import { json } from '@sveltejs/kit';
import Fuse from 'fuse.js';

export const GET = async ({ url, fetch }) => {
	const params = url.searchParams;
	const query = params.get('query');
	const provider = params.get('provider');

	if (!query) return json({ error: 'No query provided' });

	const results: {
		arasaac: unknown[];
	} = {
		arasaac: []
	};

	const ArasaacSymbols = await fetch('/symbols.json').then((res) => res.json());

	// console.log(ArasaacSymbols);

	if (provider === 'arasaac' || !provider) {
		const arasaacFuse = new Fuse(ArasaacSymbols, {
			keys: ['keywords']
		});
		results.arasaac = arasaacFuse.search(query).map((result) => result.item);
	}

	return json({
		results: [...results.arasaac].slice(0, 100)
	});
};
