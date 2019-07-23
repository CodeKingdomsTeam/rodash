import { parse } from 'luaparse';
import { readdir, readFile, writeFile } from 'fs-extra';
import { basename, extname, join } from 'path';
import { ArgumentParser } from 'argparse';
import { generateMd } from './generateMd';
import { generateMakeDocsYml } from './generateMakeDocsYml';
const parser = new ArgumentParser({
	version: '1.0.0',
	addHelp: true,
	description: 'Generate markdown docs for lua files',
});
parser.addArgument(['-o', '--output'], {
	help: 'The directory where md files should be written to',
	defaultValue: '.',
});
parser.addArgument('source', {
	help: 'The directory where lua files should be read from',
	defaultValue: '.',
});

async function processFiles(source: string, output: string) {
	const files = await readdir(source);
	const mdFiles = await Promise.all(
		files
			.filter(file => extname(file) === '.lua')
			.map(async file => {
				const text = await readFile(join(source, file), 'utf8');
				const nodesByLine = {};
				let maxLines = 0;
				parse(text, {
					comments: true,
					locations: true,
					onCreateNode: node => {
						const line = node.loc.start.line;
						const currentNode = nodesByLine[line];
						if (!currentNode || currentNode.type !== 'Comment') {
							nodesByLine[line] = node;
						}
						maxLines = Math.max(line, maxLines);
					},
				});
				const name = basename(file, '.lua');
				const outputName = name + '.md';
				const md = generateMd(name, nodesByLine, maxLines, '_');
				writeFile(join(output, outputName), md);
				console.log('Built md:', outputName);
				return outputName;
			}),
	);
	writeFile('mkdocs.yml', generateMakeDocsYml(mdFiles));
}

(async function() {
	try {
		const args = parser.parseArgs();
		await processFiles(args.source, args.output);
		console.log('Done!');
	} catch (e) {
		console.error(e);
		process.exit(1);
	}
})();
