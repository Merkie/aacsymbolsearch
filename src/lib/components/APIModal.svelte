<script lang="ts">
	import { fade, scale } from 'svelte/transition';
	import bash from 'svelte-highlight/languages/bash';
	import { Highlight } from 'svelte-highlight';
	import { javascript, python } from 'svelte-highlight/languages';

	export let apiString: string | null;
	export let closeModal: () => void;

	let activeOption = 'CURL';

	const convertUrlToCurl = (url: string) => {
		const urlParts = url.split('?');
		const baseUrl = urlParts[0];
		const params = urlParts[1].split('&');
		const curlParams = params.map((param) => `-d ${param}`).join(' \\\n\t');
		return `$ curl -X GET -G \\\n\t'${baseUrl}' \\\n\t${curlParams}`;
	};

	const convertToFetchCall = (url: string) => {
		const urlParts = url.split('?');
		const baseUrl = urlParts[0];
		const params = urlParts[1]?.split('&') || [];

		let fetchCode = `const url = new URL("${baseUrl}");\n`;

		for (const param of params) {
			const [key, value] = param.split('=');
			fetchCode += `url.searchParams.append("${key}", "${value}");\n`;
		}

		fetchCode += '\n';
		fetchCode += 'fetch(url).then(response => response.json()).then(data => console.log(data));';

		return fetchCode;
	};

	const convertToPythonRequest = (url: string) => {
		const urlParts = url.split('?');
		const baseUrl = urlParts[0];
		const params = urlParts[1]?.split('&') || [];

		let pythonCode = 'import requests\n\n';
		pythonCode += `url = "${baseUrl}"\n`;
		pythonCode += 'params = {\n';

		for (const param of params) {
			const [key, value] = param.split('=');
			pythonCode += `    "${key}": "${value}",\n`;
		}

		pythonCode += '}\n\n';
		pythonCode += 'response = requests.get(url, params=params)\n';
		pythonCode += 'print(response.json())';

		return pythonCode;
	};
</script>

{#if apiString}
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
			class="bg-zinc-200 border border-zinc-300 rounded-md p-4 flex flex-col max-w-[90%] overflow-x-auto"
		>
			<div class="flex items-center pb-4 gap-2">
				<p class=" text-xl">API Code:</p>
				<div class="flex-1" />
				{#each ['CURL', 'Python', 'Javascript'] as option}
					<button
						on:click={() => {
							activeOption = option;
						}}
						class={`text-sm transition-all ${activeOption === option ? 'underline' : 'opacity-50'}`}
						>{option}</button
					>
				{/each}
			</div>

			{#if activeOption === 'CURL'}
				<Highlight language={bash} code={convertUrlToCurl(apiString)} />
			{/if}
			{#if activeOption === 'Javascript'}
				<Highlight language={javascript} code={convertToFetchCall(apiString)} />
			{/if}
			{#if activeOption === 'Python'}
				<Highlight language={python} code={convertToPythonRequest(apiString)} />
			{/if}
		</div>
	</main>
{/if}
