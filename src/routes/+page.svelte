<script lang="ts">
	import { browser } from '$app/environment';
	import { onMount } from 'svelte';
	import SymbolCard from '$lib/components/SymbolCard.svelte';
	import SymbolColorPicker from '$lib/components/SymbolColorPicker.svelte';
	import SymbolProvidersPicker from '$lib/components/SymbolProvidersPicker.svelte';
	import SymbolNudityViolenceFilter from '$lib/components/SymbolNudityViolenceFilter.svelte';

	export let data;

	let results = data.initialResults;

	// Loading and infinite scroll state
	let loadingMoreResults = false;
	let noMoreResultsForQuery = false;
	let page = 0;

	// Open/Closed UI state
	let advancedOptionsOpen = false;

	// Query state
	let query = '';
	const defaultQuery = 'me';

	// Filter state
	let filterResults = true;
	let selectedProviders = ['arasaac', 'mulberry', 'picto'];

	// Color option state
	let selectedSkinColor = 'white';
	let selectedHairColor = 'brown';

	// Infinate Scroll
	onMount(() => {
		window.addEventListener('scroll', async () => {
			if (window.innerHeight + window.scrollY >= document.body.offsetHeight - 500) {
				if (!loadingMoreResults && !noMoreResultsForQuery) {
					loadingMoreResults = true;
					page++;
					const fetchedResults = await fetchResults();
					if (fetchedResults.length === 0) {
						noMoreResultsForQuery = true;
					} else {
						results = [...results, ...fetchedResults];
					}
					loadingMoreResults = false;
				}
			}
		});
	});

	// Fetch results, doesn't update state itself
	const fetchResults = async () => {
		const endpoint = new URL('/api/v1/search', window.location.origin);
		const params = {
			query: query.length > 1 ? query : defaultQuery,
			provider: selectedProviders.join(','),
			nsfw: filterResults ? 'false' : 'true',
			skin: selectedSkinColor,
			hair: selectedHairColor,
			page
		};
		// @ts-ignore
		Object.keys(params).forEach((key) => endpoint.searchParams.append(key, params[key]));
		const resJson = await fetch(endpoint)
			.then((res) => res.json())
			.catch((err) => console.error(err));
		return resJson.results || [];
	};

	// Reset results whenever some critial state changes
	$: {
		if (browser) {
			results = [];
			fetchResults().then((res) => (results = res));
		}
		[query, filterResults, selectedProviders, selectedSkinColor, selectedHairColor];
	}
</script>

<div class="p-4 flex gap-4 bg-zinc-200">
	<div
		class="bg-zinc-50 border border-zinc-300 shadow-sm flex rounded-md focus-within:ring-2 flex-1"
	>
		<i class="bi bi-search p-2 pl-4" />
		<input
			bind:value={query}
			placeholder={`Search 27,976 symbols...`}
			type="text"
			class="p-2 outline-none flex-1 bg-transparent"
		/>
	</div>
	<SymbolProvidersPicker
		{selectedProviders}
		onProviderPick={(id) => {
			if (selectedProviders.includes(id)) {
				if (selectedProviders.length === 1) return;
				selectedProviders = selectedProviders.filter((p) => p !== id);
			} else {
				selectedProviders = [...selectedProviders, id];
			}
		}}
	/>
	<SymbolNudityViolenceFilter
		{filterResults}
		onFilterToggle={() => {
			filterResults = !filterResults;
		}}
	/>
	<button class="p-2" on:click={() => (advancedOptionsOpen = !advancedOptionsOpen)}>
		<i class="bi bi-three-dots" />
	</button>
</div>
{#if advancedOptionsOpen}
	<div class="flex items-center pb-4">
		<SymbolColorPicker
			{selectedSkinColor}
			{selectedHairColor}
			onHairColorPick={(color) => {
				selectedHairColor = color;
			}}
			onSkinColorPick={(color) => {
				selectedSkinColor = color;
			}}
		/>
		<button class="hover:underline">Copy API Link</button>
	</div>
{/if}
<div class="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-7 gap-2 p-4 pt-0">
	{#key [selectedHairColor, selectedSkinColor]}
		{#each results as result (result.id)}
			<SymbolCard
				{result}
				onError={() => {
					results = results.filter((r) => r.id !== result.id);
				}}
			/>
		{/each}
	{/key}
</div>
