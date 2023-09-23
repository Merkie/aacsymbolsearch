<script lang="ts">
	import { hairColors, skinColors } from '$lib/arasaac_colors';

	export let onSkinColorPick: (color: string) => void;
	export let onHairColorPick: (color: string) => void;
</script>

<div class="px-4 pb-4 items-center flex gap-2">
	<p>Skin Color:</p>
	<div class="p-2 flex gap-2 bg-zinc-50 rounded-md border border-zinc-300">
		{#each skinColors as skinColor}
			<button
				on:click={() => {
					onSkinColorPick(skinColor.name);
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
					onHairColorPick(hairColor.name);
				}}
				class="w-[50px] h-[25px] rounded-sm"
				style={`background-color: ${hairColor.hex}`}
			/>
		{/each}
	</div>
</div>
