<script lang="ts">
	import { hairColors, skinColors } from '$lib/arasaac_colors';

	export let selectedSkinColor: string;
	export let selectedHairColor: string;
	export let onSkinColorPick: (color: string) => void;
	export let onHairColorPick: (color: string) => void;
</script>

<div class="px-4 items-center flex gap-2">
	<p>Skin Color:</p>
	<div class="p-2 flex gap-2 bg-zinc-50 rounded-md border border-zinc-300">
		{#each skinColors as skinColor}
			<button
				on:click={() => {
					onSkinColorPick(skinColor.name);
				}}
				class="w-[50px] h-[25px] rounded-sm"
				style={`background-color: ${skinColor.hex}`}
			>
				{#if skinColor.name === selectedSkinColor}
					<i
						class={`bi bi-check-lg ${
							!['assian', 'white'].includes(skinColor.name) ? 'text-zinc-50' : 'text-zinc-900'
						}`}
					/>
				{/if}
			</button>
		{/each}
	</div>
	<p class="ml-4">Hair Color:</p>
	<div class="p-2 flex gap-2 bg-zinc-50 rounded-md border border-zinc-300">
		{#each hairColors as hairColor}
			<button
				on:click={() => {
					onHairColorPick(hairColor.name);
				}}
				class="w-[50px] h-[25px] rounded-sm"
				style={`background-color: ${hairColor.hex}`}
			>
				{#if hairColor.name === selectedHairColor}
					<i
						class={`bi bi-check-lg ${
							!['gray', 'blonde'].includes(hairColor.name) ? 'text-zinc-50' : 'text-zinc-900'
						}`}
					/>
				{/if}
			</button>
		{/each}
	</div>
</div>
