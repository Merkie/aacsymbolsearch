export const load = async ({ fetch }) => {
	const initialSearch = await fetch('/api/v1/search?query=me').then((res) => res.json());

	return {
		initialResults: initialSearch.results
	};
};
