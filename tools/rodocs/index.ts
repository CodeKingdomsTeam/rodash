import { parse } from 'luaparse';
import { readdir, readFile, writeFile } from 'fs-extra';
import { basename, extname, join } from 'path';
import { ArgumentParser } from 'argparse';
import { generateMd, Nodes } from './generateMd';
import { generateMakeDocsYml } from './generateMakeDocsYml';
import { FunctionDeclaration, MemberExpression, Identifier } from './astTypings';
import { uniq } from 'lodash';
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

interface FileParse {
	name: string;
	maxLines: number;
	nodesByLine: Nodes;
	fnNames: string[];
}
interface Glossary {
	[module: string]: string[];
}

async function processFiles(source: string, output: string) {
	const files = await readdir(source);
	const fileParses: FileParse[] = await Promise.all(
		files
			.filter(file => extname(file) === '.lua' && basename(file) !== 'init.lua')
			.map(async file => {
				const text = await readFile(join(source, file), 'utf8');
				const nodesByLine: Nodes = {};
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
				const fnNames = getFnNames(nodesByLine, maxLines);
				return { name, nodesByLine, maxLines, fnNames };
			}),
	);
	const glossary: Glossary = {};
	for (const fileParse of fileParses) {
		glossary[fileParse.name] = fileParse.fnNames;
	}

	await writeFile(join(output, 'glossary.md'), getGlossary(glossary));

	const mdFiles = await Promise.all(
		fileParses.map(async ({ name, nodesByLine, maxLines }) => {
			const outputName = name + '.md';
			const md = generateMd(name, nodesByLine, maxLines, 'dash');
			await writeFile(join(output, 'api', outputName), md);
			console.log('Built md:', outputName);
			return outputName;
		}),
	);
	await writeFile('mkdocs.yml', generateMakeDocsYml(mdFiles));
}

export function getFnNames(nodes: Nodes, maxLine: number): string[] {
	const names = [];
	for (const line in nodes) {
		const node = nodes[line];
		if (node.type === 'FunctionDeclaration') {
			const fnNode = node as FunctionDeclaration;
			if (fnNode.identifier && fnNode.identifier.type === 'MemberExpression') {
				const member = fnNode.identifier as MemberExpression;
				const name = (member.identifier as Identifier).name;
				names.push(member.base.name + '.' + name);
			}
		}
	}
	return names;
}

interface GlossaryLink {
	name: string;
	text: string;
}

function getGlossary(glossary: Glossary) {
	const fnLinks: GlossaryLink[] = [];
	for (const fileName in glossary) {
		fnLinks.push(
			...glossary[fileName].map(fnName => {
				const [memberName, idName] = fnName.split('.');
				const shortName = memberName === fileName ? idName : fnName;
				return {
					name: shortName,
					text: `[${shortName}](/api/${fileName}/#${shortName})`,
				};
			}),
		);
	}
	const textLinks = fnLinks.sort((a: GlossaryLink, b: GlossaryLink) =>
		a.name.toLowerCase() < b.name.toLowerCase() ? -1 : 1,
	);
	const list = uniq(textLinks.map(link => '* ' + link.text)).join('\n');
	return `
# Glossary	

${list}
`;
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
