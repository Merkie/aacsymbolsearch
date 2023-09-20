<script lang="ts">
	export let data;

	let query = '';

	let results = data.initialResults;

	const resultToUrl = (result: any) => {
		if (result.provider === 'mulberry')
			return `https://cdn.aacsymbolsearch.com/mulberry/${result.id.slice(9)}.svg`;
		if (result.provider === 'arasaac')
			return `https://cdn.aacsymbolsearch.com/arasaac/${
				result.id.split('-')[1]
			}-${result.keywords[0].replace(/[^a-zA-Z0-9\s]/g, '-')}${result.skin ? '-white' : ''}${
				result.hair ? '-brown' : ''
			}.png`;
		if (result.provider === 'picto')
			return `https://cdn.aacsymbolsearch.com/picto/${result.id.slice(6)}.png`;
	};
</script>

<div class="p-4 flex gap-4">
	<div
		class="bg-zinc-50 border border-zinc-300 shadow-sm flex rounded-md focus-within:ring-2 flex-1"
	>
		<i class="bi bi-search p-2 pl-4" />
		<input
			on:input={async () => {
				results = [];
				const resJson = await fetch(`/api/v1/search?query=${encodeURIComponent(query)}`)
					.then((res) => res.json())
					.catch((err) => console.error(err));
				if (resJson.results) results = resJson.results;
			}}
			bind:value={query}
			placeholder={`Search 13,044 symbols...`}
			type="text"
			class="p-2 outline-none flex-1 bg-transparent"
		/>
	</div>
</div>
<div class="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-7 gap-2 p-4 pt-0">
	{#each results as result}
		<div
			class="p-2 bg-zinc-100 border border-zinc-300 rounded-md hover:cursor-pointer hover:shadow-md"
		>
			<img src={resultToUrl(result)} alt="symbol" />
		</div>
	{/each}
</div>

<style lang="postcss">
	:global(html) {
		@apply bg-zinc-200;
	}
</style>
