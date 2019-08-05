import { Node, Comment, MemberExpression, FunctionDeclaration, Identifier } from './astTypings';

interface DocEntry {
	tag: string;
	content: string;
}

interface Doc {
	typing: string;
	comments: string[];
	entries: DocEntry[];
}
interface FunctionDoc {
	name: string;
	content: string;
}

interface Nodes {
	[line: string]: Node;
}

export function generateMd(name: string, nodes: Nodes, maxLine: number, libName?: string) {
	let topComment = '';
	let inHeader = true;
	const functions: FunctionDoc[] = [];
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
		if (node.type === 'FunctionDeclaration') {
			const doc = getDocAtLocation(node.loc.start.line, nodes);
			const fn = getFnDoc(libName || name, node as FunctionDeclaration, doc);
			if (fn) {
				functions.push(fn);
			}
		}
		functions.sort((a, b) => (a.name < b.name ? -1 : 1));
	}

	return `
# ${name}

${topComment}

## Functions

${functions.map(fn => fn.content).join('\n\n---\n\n')}

`;
}

function getDocAtLocation(loc: number, nodes: Nodes): Doc {
	let typing;
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
				typing = escapeHtml(comment.value.substring(1));
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
		typing,
		comments: comments.reverse(),
		entries: entries,
	};
}

function getCommentTextAndEntries(commentNode: Comment) {
	const nodeEntries = [];
	return {
		nodeText: commentNode.value
			.split('\n')
			.map(line => {
				const lineWithoutIndent = line.replace(/^\t/, '');
				const entryMatch = lineWithoutIndent.match(/^\@([a-z]+)\s(.+)/);
				if (entryMatch) {
					nodeEntries.push({
						tag: entryMatch[1],
						content: entryMatch[2],
					});
					return '';
				} else {
					return lineWithoutIndent;
				}
			})
			.join('\n'),
		nodeEntries,
	};
}

function getFnDoc(libName: string, node: FunctionDeclaration, doc: Doc): FunctionDoc | undefined {
	const lines = [];
	if (node.identifier && node.identifier.type === 'MemberExpression') {
		const member = node.identifier as MemberExpression;
		const name = (member.identifier as Identifier).name;
		const params = node.parameters.map(id => id.name);

		const traits = filterEntries(doc.entries, 'trait');
		if (traits.length) {
			lines.push(`<div class="rodocs-trait">${traits.map(entry => entry.content).join(' ')}</div>`);
		}
		lines.push(
			`### ${name} \n`,
			'```lua' +
				`
function ${libName}.${name}(${params.join(', ')}) --> string
` +
				'```',
		);
		lines.push(doc.comments);
		if (params.length) {
			lines.push('\n**Parameters**\n', ...params.map(param => `> __${param}__ - _string_\n>`));
		}
		lines.push('\n**Returns**\n');
		lines.push('\n> _string_');
		const examples = filterEntries(doc.entries, 'example');
		if (examples.length) {
			lines.push(
				'\n**Examples**\n',
				'```lua',
				...examples.map(example => example.content + '\n'),
				'```',
			);
		}
		const usage = filterEntries(doc.entries, 'usage');
		if (usage.length) {
			lines.push('\n**Usage**\n', ...usage.map(({ content }) => `* ${content}`));
		}
		return {
			name,
			content: lines.join('\n'),
		};
	}
}

function filterEntries(entries: DocEntry[], tag: string) {
	return entries.filter(entry => entry.tag === tag);
}

function escapeHtml(unsafe: string) {
	return unsafe
		.replace(/&/g, '&amp;')
		.replace(/</g, '&lt;')
		.replace(/>/g, '&gt;')
		.replace(/"/g, '&quot;')
		.replace(/'/g, '&#039;');
}
