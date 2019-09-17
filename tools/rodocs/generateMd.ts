import {
	Node,
	Comment,
	MemberExpression,
	FunctionDeclaration,
	Identifier,
	AssignmentStatement,
} from './astTypings';
import { keyBy } from 'lodash';
import { GlossaryMap } from './index';
import * as parser from './typeParser';
import {
	describeType,
	stringifyType,
	FunctionType,
	TypeKind,
	PLURALITY,
	getMetaDescription,
	describeGeneric,
} from './LuaTypes';

interface DocEntry {
	tag: string;
	content: string;
}

interface Doc {
	typeString: string;
	typing: FunctionType;
	comments: string[];
	entries: DocEntry[];
}
export interface MdDoc {
	name: string;
	content: string;
	sortName: string;
	comments: string[];
}

export interface LibraryProps {
	libName: string;
	fileName: string;
	glossaryMap: GlossaryMap;
	rootUrl: string;
}

export interface Nodes {
	[line: string]: Node;
}

export function generateMd(libraryProps: LibraryProps, nodes: Nodes, maxLine: number) {
	let topComment = '';
	let inHeader = true;
	const functions: MdDoc[] = [];
	const members: MdDoc[] = [];
	for (let i = 0; i <= maxLine; i++) {
		if (!nodes[i]) {
			continue;
		}
		const node = nodes[i];
		if (inHeader) {
			if (node.type === 'Comment') {
				const { nodeText } = getCommentTextAndEntries(node as Comment);
				topComment += nodeText + '\n';
			} else {
				inHeader = false;
			}
		}
		if (node.type === 'FunctionDeclaration' || node.type === 'AssignmentStatement') {
			const doc = getDocAtLocation(node.loc.start.line, nodes);
			if (!doc.typing) {
				console.log('Skipping untyped method:', doc.comments);
			} else {
				if (node.type === 'AssignmentStatement') {
					const member = getMemberDoc(libraryProps, node as AssignmentStatement, doc);
					if (member) {
						if (!member.comments.length) {
							console.log('Skipping undocumented method:', member.sortName);
						} else {
							members.push(member);
						}
					}
				} else {
					const fn = getFnDoc(libraryProps, node as FunctionDeclaration, doc);
					if (fn) {
						if (!fn.comments.length) {
							console.log('Skipping undocumented method:', fn.sortName);
						} else {
							functions.push(fn);
						}
					}
				}
			}
		}
		functions.sort((a, b) => (a.sortName.toLowerCase() < b.sortName.toLowerCase() ? -1 : 1));
		members.sort((a, b) => (a.sortName.toLowerCase() < b.sortName.toLowerCase() ? -1 : 1));
	}

	const functionDocs = functions.length
		? `## Functions

${functions.map(fn => fn.content).join('\n\n---\n\n')}`
		: '';

	const memberDocs = members.length
		? `## Members

${members.map(fn => fn.content).join('\n\n---\n\n')}`
		: '';

	return `
# ${libraryProps.fileName}

${topComment}

${functionDocs}

${memberDocs}

`;
}

function getDocAtLocation(loc: number, nodes: Nodes): Doc {
	let typing: FunctionType;
	let typeString: string;
	const comments = [];
	const entries = [];
	// Work backwards from the location to find comments above the specified point, which will form
	// documentation for the node at the location specified.
	for (let i = loc - 1; i >= 0; i--) {
		const node = nodes[i];
		if (!node) {
			continue;
		}
		if (node.type === 'Comment') {
			const comment = node as Comment;
			if (comment.raw.match(/^\-\-\:/)) {
				const type = comment.value.substring(1);
				try {
					typeString = type.trim();
					typing = parser.parse(typeString) as FunctionType;
				} catch (e) {
					console.warn('BadType:', type, e);
				}
			} else {
				const { nodeText, nodeEntries } = getCommentTextAndEntries(comment);
				comments.push(nodeText);
				entries.push(...nodeEntries);
			}
		} else {
			break;
		}
	}
	return {
		typeString,
		typing,
		comments: comments.reverse(),
		entries: entries,
	};
}

function getCommentTextAndEntries(commentNode: Comment) {
	const nodeEntries = [];
	let lastEntry;
	let content: string[] = [];
	commentNode.value.split('\n').forEach(line => {
		const lineWithoutIndent = line.replace(/^[\s\t][\s\t]?/g, '');
		const entryMatch = lineWithoutIndent.match(/^\@([a-z]+)\s?(.*)/);
		if (entryMatch) {
			lastEntry = {
				tag: entryMatch[1],
				content: entryMatch[2],
			};
			nodeEntries.push(lastEntry);
		} else if (lastEntry) {
			lastEntry.content += '\n' + lineWithoutIndent;
		} else {
			content.push(lineWithoutIndent);
		}
	});

	return {
		nodeText: content.join('\n'),
		nodeEntries,
	};
}

function getMemberDoc(
	libraryProps: LibraryProps,
	node: AssignmentStatement,
	doc: Doc,
): MdDoc | undefined {
	const member = node.variables[0] as MemberExpression;
	const name = (member.identifier as Identifier).name;
	const baseName = member.base.name;
	const prefixName = baseName === libraryProps.fileName ? libraryProps.libName : baseName;
	const sortName = baseName === libraryProps.fileName ? name : baseName + '.' + name;
	const lines = [];
	lines.push(
		`### ${name} \n`,
		'```lua' +
			`
${prefixName}.${name} -- ${doc.typeString}
` +
			'```',
		doc.comments,
	);
	const examples = filterEntries(doc.entries, 'example');
	if (examples.length) {
		lines.push(
			'\n**Examples**\n',
			...examples.map(example => '```lua\n' + example.content + '\n```\n\n'),
		);
	}
	return {
		name,
		sortName,
		content: lines.join('\n'),
		comments: doc.comments,
	};
}

function getFnDoc(
	libraryProps: LibraryProps,
	node: FunctionDeclaration,
	doc: Doc,
): MdDoc | undefined {
	const lines = [];
	if (node.identifier && node.identifier.type === 'MemberExpression') {
		const member = node.identifier as MemberExpression;
		const name = (member.identifier as Identifier).name;
		const baseName = member.base.name;
		const params = node.parameters.map(id => (id.type === 'VarargLiteral' ? '...' : id.name));
		const prefixName = baseName === libraryProps.fileName ? libraryProps.libName : baseName;
		const sortName = baseName === libraryProps.fileName ? name : baseName + '.' + name;

		const returnType = doc.typing.returnType || { typeKind: TypeKind.ANY, isRestParameter: true };
		const returnTypeString = stringifyType(returnType);

		const traits = filterEntries(doc.entries, 'trait');
		if (traits.length) {
			lines.push(`<div class="rodocs-trait">${traits.map(entry => entry.content).join(' ')}</div>`);
		}
		lines.push(
			`### ${sortName} \n`,
			'```lua' +
				`
function ${prefixName}.${name}(${params.join(', ')})
` +
				'```',
			doc.comments,
		);
		const paramEntries = filterEntries(doc.entries, 'param');
		const paramMap = keyBy(
			paramEntries.map(entry => entry.content.match(/^\s*([A-Za-z.]+)\s(.*)/)),
			entry => entry && entry[1],
		);
		lines.push('\n**Type**\n', '`' + doc.typeString + '`');

		const metaDescription = getMetaDescription(doc.typing, {
			generics: {
				T: 'the type of _self_',
			},
			rootUrl: libraryProps.rootUrl,
		});

		if (doc.typing.genericTypes) {
			lines.push(
				'\n**Generics**\n',
				...doc.typing.genericTypes.map(
					generic =>
						`\n> __${generic.tag}__ - \`${stringifyType(
							generic.extendingType,
						)}\` - ${describeGeneric(generic, metaDescription)}`,
				),
			);
		}
		const parameterTypes = doc.typing.parameterTypes || [];
		if (params.length) {
			lines.push(
				'\n**Parameters**\n',
				...params.map((param, i) => {
					const parameterType = parameterTypes[i] || {
						typeKind: TypeKind.ANY,
					};
					return `> __${param}__ - \`${stringifyType(parameterType)}\` - ${describeType(
						parameterType,
						metaDescription,
						PLURALITY.SINGULAR,
					)} ${paramMap[param] && paramMap[param][2] ? ' - ' + paramMap[param][2] : ''}\n>`;
				}),
			);
		}
		const returns = filterEntries(doc.entries, 'returns');
		lines.push('\n**Returns**\n');
		const returnTypeDescription = describeType(returnType, metaDescription, PLURALITY.SINGULAR);
		if (returns.length) {
			lines.push(
				...returns.map(
					({ content }) => `\n> \`${returnTypeString}\` - ${returnTypeDescription} - ${content}`,
				),
			);
		} else {
			lines.push(`\n> \`${returnTypeString}\` - ${returnTypeDescription}`);
		}
		const throws = filterEntries(doc.entries, 'throws');
		if (throws.length) {
			lines.push('\n**Throws**\n');
			lines.push(...formatList(throws));
		}

		const rejects = filterEntries(doc.entries, 'rejects');
		if (rejects.length) {
			lines.push('\n**Rejects**\n');
			lines.push(
				...formatList(rejects, line => {
					switch (line) {
						case 'passthrough':
							return '_passthrough_ - The returned promise will reject if promises passed as arguments reject.';
						default:
							return line;
					}
				}),
			);
		}

		const examples = filterEntries(doc.entries, 'example');
		if (examples.length) {
			lines.push(
				'\n**Examples**\n',
				...examples.map(example => '```lua\n' + example.content + '\n```\n\n'),
			);
		}
		const usage = filterEntries(doc.entries, 'usage');
		if (usage.length) {
			lines.push('\n**Usage**\n', ...formatList(usage));
		}
		const see = filterEntries(doc.entries, 'see');
		if (see.length) {
			lines.push('\n**See**\n', ...see.map(({ content }) => `\n* ${content}`));
		}
		return {
			name,
			sortName,
			content: lines.join('\n'),
			comments: doc.comments,
		};
	}
}

function formatList(entries: DocEntry[], modifier?: (line: string) => string) {
	return entries.map(({ content }) => '\n* ' + (modifier ? modifier(content) : content));
}

function filterEntries(entries: DocEntry[], tag: string) {
	return entries.filter(entry => entry.tag === tag);
}
