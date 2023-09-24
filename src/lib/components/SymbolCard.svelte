<script lang="ts">
	export let result: any;
	export let onError: () => void;
	export let onClick: (link: string) => void;
</script>

<button
	on:click={() => {
		onClick(result.cdn);
	}}
	class="p-2 bg-zinc-100 border border-zinc-300 rounded-md hover:cursor-pointer hover:shadow-md"
>
	<img on:error={onError} src={result.cdn} alt="symbol" />
</button>
