<script>
	import '../app.css';
</script>

<div class="p-2 px-4 text-sm flex items-center bg-zinc-700 text-zinc-50 gap-4">
	<a href="/" class="font-light">
		<span><i class="bi bi-search mr-2" />AAC<span class="font-bold">SYMBOL</span>SEARCH</span>
	</a>
	<div class="flex-1" />
	<a class="hover:underline" target="_blank" href="https://github.com/merkie/aacsymbolsearch"
		>Github</a
	>
	<a class="hover:underline" href="/providers">Providers</a>
</div>
<slot />

<style lang="postcss">
	:global(html) {
		@apply bg-zinc-200;
	}
</style>
