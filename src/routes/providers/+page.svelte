<script lang="ts">
	const providers = [
		{
			name: 'ARASAAC Symbols',
			logo: '/arasaac-logo.svg',
			symbols: '13,044',
			projectUrl: 'https://arasaac.org/',
			download: '"https://cdn.aacsymbolsearch.com/symbol-archive/arasaac-symbols.zip"'
		},
		{
			name: 'Mulberry Symbols',
			logo: '/mullberry-logo.svg',
			symbols: '3,437',
			projectUrl: 'https://mulberrysymbols.org/',
			download: 'https://cdn.aacsymbolsearch.com/symbol-archive/mulberry-symbols.zip'
		},
		{
			name: '"Picto" by Sclera',
			logo: '/sclera-picto-logo.png',
			symbols: '11,496',
			projectUrl: 'https://www.sclera.be/nl/picto/overview',
			download: 'https://cdn.aacsymbolsearch.com/symbol-archive/picto-symbols.zip'
		}
	];
</script>

<div class="flex justify-center">
	<div class="flex flex-col w-[95%] max-w-[800px] py-16 gap-16">
		{#each providers as provider}
			<div class="bg-zinc-50 border border-zinc-300 rounded-md p-4">
				<div class="flex items-center gap-8 pb-8">
					<img src={provider.logo} alt={provider.name + ' logo'} width={150} />
					<p class="text-5xl">{provider.name}</p>
				</div>
				<div class="flex gap-4">
					<p class="flex-1 p-4 rounded-md bg-zinc-500 text-zinc-50 text-center">
						{provider.symbols} Symbols
					</p>
					<a
						href={provider.projectUrl}
						target="_blank"
						class="flex-1 p-4 rounded-md text-center bg-blue-500 border border-blue-400 text-blue-50 font-bold"
						>Visit Project Website <i class="bi bi-box-arrow-up-right ml-4" /></a
					>
					<a
						href={provider.download}
						target="_blank"
						class="flex-1 p-4 rounded-md text-center bg-green-500 border border-green-400 text-green-50 font-bold"
						>Download Zip <i class="bi bi-file-zip" /></a
					>
				</div>
			</div>
		{/each}
	</div>
</div>
