<script lang="ts">
	import { fade, scale } from 'svelte/transition';

	export let selectedSymbol: string | null;
	export let closeModal: () => void;

	const downloadImage = async () => {
		if (selectedSymbol) {
			const image = await fetch(selectedSymbol);
			const imageBlog = await image.blob();
			const imageURL = URL.createObjectURL(imageBlog);

			const link = document.createElement('a');
			link.href = imageURL;
			link.download = 'Symbol';
			document.body.appendChild(link);
			link.click();
			document.body.removeChild(link);
		}
	};
</script>

{#if selectedSymbol}
	<!-- svelte-ignore a11y-click-events-have-key-events -->
	<!-- svelte-ignore a11y-no-noninteractive-element-interactions -->
	<main
		on:click={(e) => {
			if (e.target === e.currentTarget) {
				closeModal();
			}
		}}
		in:fade
		out:fade={{ duration: 200 }}
		class="fixed top-0 left-0 w-screen h-screen bg-[rgba(0,0,0,0.5)] grid place-items-center z-40"
	>
		<div
			in:scale
			out:scale={{ duration: 200 }}
			class="bg-zinc-200 border border-zinc-300 rounded-md p-4 flex flex-col"
		>
			<img src={selectedSymbol} alt="Symbol preview" />
			<button
				on:click={downloadImage}
				class="bg-blue-600 p-4 mt-8 rounded-md border border-blue-500 text-blue-50 text-xl"
				>Download <i class="bi bi-cloud-download ml-4" /></button
			>
		</div>
	</main>
{/if}
