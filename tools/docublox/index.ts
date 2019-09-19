import { parse } from 'luaparse';
import { readdir, readFile, writeFile } from 'fs-extra';
import { basename, extname, join } from 'path';
import { ArgumentParser } from 'argparse';
import { generateMd, Nodes, LibraryProps } from './generateMd';
import { generateMakeDocsYml } from './generateMakeDocsYml';
import {
	FunctionDeclaration,
	MemberExpression,
	Identifier,
	AssignmentStatement,
} from './astTypings';
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
parser.addArgument(['-l', '--libName'], {
	help: 'The name of the library',
});
parser.addArgument(['-r', '--rootUrl'], {
	help: 'The root URL library',
});
parser.addArgument('source', {
	help: 'The directory where any lua files should be read from',
	defaultValue: '.',
});
parser.addArgument('docsSource', {
	help: 'The directory where any md files should be read from',
	defaultValue: '.',
});

interface FileParse {
	name: string;
	maxLines: number;
	nodesByLine: Nodes;
	docNames: string[];
}
export interface Glossary {
	[module: string]: string[];
}

export interface Options {
	libName: string;
	rootUrl: string;
	source: string;
	docsSource: string;
	output: string;
}

export function substituteLinks(libraryProps: LibraryProps, text: string) {
	return text.replace(/`([A-Za-z]+)\.([A-Za-z]+)`/g, (match, libName, docName) => {
		const glossaryLink = libraryProps.glossaryMap[docName];
		if (!glossaryLink) {
			console.log('Missing glossary link', match);
			return match;
		} else {
			return glossaryLink.fullText;
		}
	});
}

async function processSourceFiles(options: Options) {
	const { source, docsSource, libName, rootUrl, output } = options;
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
				const docNames = getDocNames(nodesByLine, maxLines);
				return { name, nodesByLine, maxLines, docNames };
			}),
	);
	const glossary: Glossary = {};
	for (const fileParse of fileParses) {
		glossary[fileParse.name] = fileParse.docNames;
	}

	const glossaryLinks = getGlossaryLinks(options, glossary);
	const glossaryWritePromise = writeFile(join(output, 'glossary.md'), getGlossary(glossaryLinks));
	const sourceFilesWritePromise = Promise.all(
		fileParses.map(async ({ name, nodesByLine, maxLines }) => {
			const outputName = name + '.md';
			const libraryProps = {
				fileName: name,
				libName,
				glossaryMap: glossaryLinks,
				rootUrl,
			};
			const mdText = generateMd(libraryProps, nodesByLine, maxLines);
			const mdTextWithLinks = substituteLinks(libraryProps, mdText);
			await writeFile(join(output, 'api', outputName), mdTextWithLinks);
			console.log('Built md:', outputName);
			return outputName;
		}),
	);
	const mdFilesWritePromise = processMdSourceFiles(docsSource, output, glossaryLinks);

	const filePromises = [
		glossaryWritePromise,
		sourceFilesWritePromise.then(mdFiles => writeFile('mkdocs.yml', generateMakeDocsYml(mdFiles))),
		mdFilesWritePromise,
	];

	return Promise.all(filePromises);
}

async function processMdSourceFiles(docsSource: string, output: string, glossaryMap: GlossaryMap) {
	const files = await readdir(docsSource);
	return files
		.filter(file => extname(file) === '.md')
		.map(async file => {
			const libraryProps = {
				fileName: file,
				libName: 'dash',
				glossaryMap,
				rootUrl: '/rodash/',
			};
			const text = await readFile(join(docsSource, file), 'utf8');
			const textWithLinks = substituteLinks(libraryProps, text);
			return writeFile(join(output, file), textWithLinks);
		});
}

export function getDocNames(nodes: Nodes, maxLine: number): string[] {
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
		} else if (node.type === 'AssignmentStatement') {
			const assignmentNode = node as AssignmentStatement;
			const member = assignmentNode.variables[0] as MemberExpression;
			if (member && member.type === 'MemberExpression') {
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
	fullText: string;
	link: string;
}

export interface GlossaryMap {
	[name: string]: GlossaryLink;
}

function getGlossaryLinks(options: Options, glossary: Glossary) {
	const glossaryMap: GlossaryMap = {};
	for (const fileName in glossary) {
		for (const docName of glossary[fileName]) {
			const [memberName, idName] = docName.split('.');
			const shortName = memberName === fileName ? idName : docName;
			const link = `${options.rootUrl}api/${fileName}/#${shortName.toLowerCase()}`;
			glossaryMap[shortName] = {
				name: shortName,
				link,
				text: `[${shortName}](${link})`,
				fullText: `[${options.libName}.${shortName}](${link})`,
			};
		}
	}
	return glossaryMap;
}

function getGlossary(glossaryMap: GlossaryMap) {
	const textLinks = Object.values(glossaryMap).sort((a: GlossaryLink, b: GlossaryLink) =>
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
		await processSourceFiles(args), console.log('Done!');
	} catch (e) {
		console.error(e);
		process.exit(1);
	}
})();
