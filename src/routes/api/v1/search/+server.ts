import type { SymbolResult } from '$lib/types.js';
import { json } from '@sveltejs/kit';
import Fuse from 'fuse.js';

export const GET = async ({ url, fetch }) => {
	const params = url.searchParams;
	const query = params.get('query');
	const page = parseInt(params.get('page') || '0');
	const provider = params.get('provider');
	const nsfw = params.get('nsfw');
	const skin = params.get('skin');
	const hair = params.get('hair');

	if (!query) return json({ error: 'No query provided' });

	const symbols = await fetch('/symbols.json').then((res) => res.json());

	const fuse = new Fuse(symbols, {
		keys: ['keywords']
	});
	let results = fuse.search(query).map((result) => result.item) as SymbolResult[];

	// filter based on provider
	if (provider && provider?.split(',').length > 0) {
		results = results.filter((result) => provider.split(',').includes(result.provider));
	}

	// filter based on nsfw
	if (nsfw === 'false') {
		results = results.filter((result) => !result.sex && !result.violence);
	}

	// adjust skin and hair
	if (skin || hair) {
		results = results.map((result) => {
			let url = result.cdn;
			if (result.skin && !result.hair) url = url.replace('-white.', `-${skin}.`);
			if (result.hair && !result.skin) url = url.replace('-brown.', `-${hair}.`);
			if (result.hair && result.skin) url = url.replace('-white-brown.', `-${skin}-${hair}.`);
			return {
				...result,
				cdn: url
			};
		});
	}

	return json({
		results: results.slice(page * 100, page * 100 + 100)
	});
};
