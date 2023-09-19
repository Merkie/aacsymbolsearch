import { Symbols } from '$lib/resources/symbols/arasaac';

export const load = async () => {
	const search = 'panties';

	const start = Date.now();

	const symbolResults = Symbols.filter((symbol) => {
		return symbol.keywords
			.map((keyword) => keyword.keyword)
			.join(', ')
			.includes(search);
	});

	console.log(`process took ${Date.now() - start}ms`);

	return {
		symbolResults
	};
};
