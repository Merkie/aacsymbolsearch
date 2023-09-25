<script lang="ts">
	import { scale } from 'svelte/transition';

	export let onFilterToggle: () => void;
	export let filterResults: boolean;
</script>

<div class="flex">
	<button on:click={onFilterToggle} class="flex gap-2 items-center">
		<p class="whitespace-nowrap text-ellipsis text-sm md:text-base">Filter Nudity and Violence</p>
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
