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
	let functions: FunctionDoc[] = [];
	let entries: DocEntry[] = [];
	for (let i = 0; i <= maxLine; i++) {
		if (!nodes[i]) {
			continue;
		}
		const node = nodes[i];
		if (inHeader) {
			if (node.type === 'Comment') {
				topComment += formatComment(node as Comment, entries) + '\n';
			} else {
				inHeader = false;
			}
		}
		if (node.type === 'FunctionDeclaration') {
			const doc = collectDoc(node.loc.start.line, nodes);
			const fn = formatFn(libName || name, node as FunctionDeclaration, doc);
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

function collectDoc(loc: number, nodes: Nodes): Doc {
	let typing;
	let comments = [];
	let entries = [];
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
				comments.push(formatComment(comment, entries));
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

function formatComment(commentNode: Comment, entries: DocEntry[]) {
	return commentNode.value
		.split('\n')
		.map(line => {
			const lineWithoutIndent = line.replace(/^\t/, '');
			const entryMatch = lineWithoutIndent.match(/^\@([a-z]+)\s(.+)/);
			if (entryMatch) {
				entries.push({
					tag: entryMatch[1],
					content: entryMatch[2],
				});
				return '';
			} else {
				return lineWithoutIndent;
			}
		})
		.join('\n');
}

function formatFn(libName: string, node: FunctionDeclaration, doc: Doc): FunctionDoc {
	const lines = [];
	if (node.identifier && node.identifier.type === 'MemberExpression') {
		const member = node.identifier as MemberExpression;
		const name = (member.identifier as Identifier).name;
		const params = node.parameters.map(id => id.name);

		const traits = filterEntries(doc.entries, 'trait');
		if (traits.length) {
			lines.push(`<div class="rodocs-trait">${traits.map(entry => entry.content).join(' ')}</div>`);
		}
		lines.push(`### ${name} \n`);
		lines.push(
			'```lua' +
				`
function ${libName}.${name}(${params.join(', ')}) --> string
` +
				'```',
		);
		lines.push(doc.comments);
		if (params.length) {
			lines.push('\n**Parameters**\n');
			lines.push(...params.map(param => `> __${param}__ - _string_\n>`));
		}
		lines.push('\n**Returns**\n');
		lines.push('\n> _string_');
		const examples = filterEntries(doc.entries, 'example');
		if (examples.length) {
			lines.push('\n**Examples**\n');
			lines.push('```lua');
			lines.push(...examples.map(example => example.content + '\n'));
			lines.push('```');
		}
		const usage = filterEntries(doc.entries, 'usage');
		if (usage.length) {
			lines.push('\n**Usage**\n');
			lines.push(...usage.map(({ content }) => `* ${content}`));
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
