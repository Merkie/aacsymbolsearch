import { json } from '@sveltejs/kit';
import Fuse from 'fuse.js';

export const GET = async ({ url, fetch }) => {
	const params = url.searchParams;
	const query = params.get('query');
	const page = parseInt(params.get('page') || '0');
	// const provider = params.get('provider');

	if (!query) return json({ error: 'No query provided' });

	const symbols = await fetch('/symbols.json').then((res) => res.json());

	const fuse = new Fuse(symbols, {
		keys: ['keywords']
	});
	const results = fuse.search(query).map((result) => result.item);

	return json({
		results: results.slice(page * 100, page * 100 + 100)
	});
};
