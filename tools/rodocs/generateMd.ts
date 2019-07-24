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
			entries.push(lastEntry);
		} else if (lastEntry) {
			lastEntry.content += '\n' + lineWithoutIndent;
		} else {
			content.push(lineWithoutIndent);
		}
	});

	return content.join('\n');
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
		const returns = filterEntries(doc.entries, 'returns');
		lines.push('\n**Returns**\n');
		if (returns.length) {
			lines.push(...returns.map(({ content }) => `\n> _string_ - ${content}`));
		} else {
			lines.push('\n> _string_');
		}
		const throws = filterEntries(doc.entries, 'throws');
		if (throws.length) {
			lines.push('\n**Usage**\n');
			lines.push(...formatList(throws));
		}

		const rejects = filterEntries(doc.entries, 'rejects');
		if (rejects.length) {
			lines.push('\n**Rejects**\n');
			lines.push(
				...formatList(rejects, function(line) {
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
			lines.push('\n**Examples**\n');
			lines.push('```lua');
			lines.push(...examples.map(example => example.content + '\n'));
			lines.push('```');
		}
		const usage = filterEntries(doc.entries, 'usage');
		if (usage.length) {
			lines.push('\n**Usage**\n');
			lines.push(...formatList(usage));
		}
		return {
			name,
			content: lines.join('\n'),
		};
	}
}

function formatList(entries: DocEntry[], modifier?: (line: string) => string) {
	return entries.map(
		({ content }) =>
			'* ' +
			content
				.split('\n')
				.filter(line => !line.match(/^\s*$/))
				.map(line => (modifier ? modifier(line) : line))
				.join('\n* '),
	);
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
