export interface Node {
	type: string;
	loc: {
		start: {
			line: number;
		};
	};
}
export interface Identifier extends Node {
	name: string;
}
export interface MemberExpression extends Node {
	base: Identifier;
	identifier: Identifier | MemberExpression;
}
export interface FunctionDeclaration extends Node {
	identifier: Identifier | MemberExpression;
	parameters: Identifier[];
}
export interface Comment extends Node {
	raw: string;
	value: string;
}

export interface AssignmentStatement extends Node {
	variables: Node[];
}
