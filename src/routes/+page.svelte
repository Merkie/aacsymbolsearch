<script lang="ts">
	import { hairColors, skinColors } from '$lib/arasaac_colors';
	import providers from '$lib/symbol_providers';

	import { browser } from '$app/environment';
	import { onMount } from 'svelte';
	import { fly, scale } from 'svelte/transition';

	export let data;

	let results = data.initialResults;

	// Loading and infinite scroll state
	let loadingMoreResults = false;
	let noMoreResultsForQuery = false;
	let page = 0;

	// Open/Closed UI state
	let providersFilterOpen = false;
	let colorOptionsOpen = false;

	// Query state
	let query = '';
	const defaultQuery = 'me';

	// Filter state
	let filterResults = true;
	let selectedProviders = ['arasaac', 'mulberry', 'picto'];

	// Color option state
	let selectedSkinColor = 'white';
	let selectedHairColor = 'black';

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

<div class="p-4 flex gap-4">
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
	<div class="relative">
		<button
			on:click={() => (providersFilterOpen = !providersFilterOpen)}
			class="bg-zinc-50 border border-zinc-300 shadow-sm flex rounded-md p-2 px-4"
		>
			<p class="pr-16">
				{selectedProviders.length === providers.length
					? 'All Providers'
					: // if all providers are disabled
					selectedProviders.length === 0
					? 'No Providers'
					: // if some providers are enabled
					  'Providers: ' +
					  providers
							.filter((p) => selectedProviders.includes(p.id))
							.map((p) => p.name)
							.join(', ')}
			</p>
			<i class="bi bi-chevron-down" />
		</button>
		{#if providersFilterOpen}
			<div
				transition:fly={{ y: 20, duration: 200 }}
				class="bg-zinc-50 w-[250px] border border-zinc-300 shadow-sm flex flex-col rounded-md p-2 absolute -bottom-[10px] translate-y-[100%] right-0"
			>
				{#each providers as provider}
					<button
						on:click={() => {
							if (selectedProviders.includes(provider.id)) {
								if (selectedProviders.length === 1) return;
								selectedProviders = selectedProviders.filter((p) => p !== provider.id);
							} else {
								selectedProviders = [...selectedProviders, provider.id];
							}
						}}
						class="flex gap-2 items-center p-2 justify-between"
					>
						<p>{provider.name}</p>
						<div
							class={`w-[20px] h-[20px] text-blue-50 relative rounded-md border-2 transition-all ${
								selectedProviders.includes(provider.id)
									? 'bg-blue-500 border-transparent'
									: ' border-zinc-500'
							}`}
						>
							{#if selectedProviders.includes(provider.id)}
								<i
									transition:scale
									class="bi bi-check text-2xl absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2"
								/>
							{/if}
						</div>
					</button>
				{/each}
			</div>
		{/if}
	</div>
	<div class="flex">
		<button on:click={() => (filterResults = !filterResults)} class="flex gap-2 items-center">
			<p>Filter Nudity and Violence</p>
			<div
				class={`w-[20px] h-[20px] text-blue-50 relative rounded-md border-2 transition-all ${
					filterResults ? 'bg-blue-500 border-transparent' : ' border-zinc-500'
				}`}
			>
				{#if filterResults}
					<i
						transition:scale
						class="bi bi-check text-2xl absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2"
					/>
				{/if}
			</div>
		</button>
	</div>
	<button class="p-2" on:click={() => (colorOptionsOpen = !colorOptionsOpen)}>
		<i class="bi bi-three-dots" />
	</button>
</div>
{#if colorOptionsOpen}
	<div class="px-4 pb-4 items-center flex gap-2">
		<p>Skin Color:</p>
		<div class="p-2 flex gap-2 bg-zinc-50 rounded-md border border-zinc-300">
			{#each skinColors as skinColor}
				<button
					on:click={() => {
						selectedSkinColor = skinColor.name;
					}}
					class="w-[50px] h-[25px] rounded-sm"
					style={`background-color: ${skinColor.hex}`}
				/>
			{/each}
		</div>
		<p class="ml-4">Hair Color:</p>
		<div class="p-2 flex gap-2 bg-zinc-50 rounded-md border border-zinc-300">
			{#each hairColors as hairColor}
				<button
					on:click={() => {
						selectedHairColor = hairColor.name;
					}}
					class="w-[50px] h-[25px] rounded-sm"
					style={`background-color: ${hairColor.hex}`}
				/>
			{/each}
		</div>
	</div>
{/if}
<div class="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-7 gap-2 p-4 pt-0">
	{#key [selectedHairColor, selectedSkinColor]}
		{#each results as result (result.id)}
			<div
				class="p-2 bg-zinc-100 border border-zinc-300 rounded-md hover:cursor-pointer hover:shadow-md"
			>
				<img
					on:error={() => {
						//@ts-ignore
						results = results.filter((r) => r.id !== result.id);
					}}
					src={result.cdn}
					alt="symbol"
				/>
			</div>
		{/each}
	{/key}
</div>

<style lang="postcss">
	:global(html) {
		@apply bg-zinc-200;
	}
</style>
