<script lang="ts">
	import providers from '$lib/symbol_providers';
	import { fly, scale } from 'svelte/transition';

	let providersFilterOpen = false;

	export let selectedProviders: string[];
	export let onProviderPick: (id: string) => void;
</script>

<div class="relative flex-1 flex text-sm md:text-base">
	<button
		on:click={() => (providersFilterOpen = !providersFilterOpen)}
		class={`bg-zinc-50 border flex-1 border-zinc-300 shadow-sm flex rounded-md p-2 md:px-4 whitespace-nowrap`}
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
		<span class="flex-1" />
		<i class="bi bi-chevron-down" />
	</button>
	{#if providersFilterOpen}
		<div
			transition:fly={{ y: 20, duration: 200 }}
			class={`bg-zinc-50 w-full border border-zinc-300 shadow-sm flex flex-col rounded-md p-2 absolute -bottom-[10px] translate-y-[100%] right-0`}
		>
			{#each providers as provider}
				<button
					on:click={() => {
						onProviderPick(provider.id);
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
