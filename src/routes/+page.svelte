<script lang="ts">
	import { browser } from '$app/environment';
	import { onMount } from 'svelte';
	import { fly, scale } from 'svelte/transition';

	export let data;

	let results = data.initialResults;

	let query = '';
	const defaultQuery = 'me';

	let page = 0;

	let loadingMoreResults = false;
	let finishedLoading = false;

	let filterResults = true;
	let providersFilterOpen = false;

	let providers = [
		{
			name: 'Arasaac',
			id: 'arasaac',
			enabled: true
		},
		{
			name: 'Mulberry',
			id: 'mulberry',
			enabled: true
		},
		{
			name: 'Sclera Picto',
			id: 'picto',
			enabled: true
		}
	];

	onMount(() => {
		window.addEventListener('scroll', async () => {
			if (window.innerHeight + window.scrollY >= document.body.offsetHeight - 500) {
				if (!loadingMoreResults && !finishedLoading) {
					loadingMoreResults = true;
					page++;
					const resJson = await fetch(
						`/api/v1/search?query=${encodeURIComponent(query)}?query=${
							query.length > 1 ? query : defaultQuery
						}&page=${page}&provider=${providers
							.map((p) => (p.enabled ? p.id : null))
							.filter((p) => !!p)}&nsfw=${filterResults ? 'true' : 'false'}`
					)
						.then((res) => res.json())
						.catch((err) => console.error(err));
					if (resJson.results.length === 0) finishedLoading = true;
					if (resJson.results) results = [...results, ...resJson.results];
					loadingMoreResults = false;
				}
			}
		});
	});

	const refreshResults = async () => {
		results = [];
		const resJson = await fetch(
			`/api/v1/search?query=${encodeURIComponent(
				query.length > 1 ? query : defaultQuery
			)}&provider=${providers.map((p) => (p.enabled ? p.id : null)).filter((p) => !!p)}&nsfw=${
				filterResults ? 'false' : 'true'
			}`
		)
			.then((res) => res.json())
			.catch((err) => console.error(err));
		if (resJson.results) results = resJson.results;
	};

	$: {
		if (browser) refreshResults();
		[query, providers, filterResults];
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
				{providers.filter((p) => p.enabled).length === providers.length
					? 'All Providers'
					: // if all providers are disabled
					providers.filter((p) => p.enabled).length === 0
					? 'No Providers'
					: // if some providers are enabled
					  'Providers: ' +
					  providers
							.filter((p) => p.enabled)
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
							if (providers.filter((p) => p.enabled).length === 1 && provider.enabled) return;
							provider.enabled = !provider.enabled;
						}}
						class="flex gap-2 items-center p-2 justify-between"
					>
						<p>{provider.name}</p>
						<div
							class={`w-[20px] h-[20px] text-blue-50 relative rounded-md border-2 transition-all ${
								provider.enabled ? 'bg-blue-500 border-transparent' : ' border-zinc-500'
							}`}
						>
							{#if provider.enabled}
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
</div>
<div class="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-5 lg:grid-cols-7 gap-2 p-4 pt-0">
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
</div>

<style lang="postcss">
	:global(html) {
		@apply bg-zinc-200;
	}
</style>
