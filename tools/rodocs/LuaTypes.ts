import { stringify } from 'querystring';

export enum TypeKind {
	TABLE = 'table',
	ARRAY = 'array',
	DICTIONARY = 'dictionary',
	TUPLE = 'tuple',
	ALIAS = 'alias',
	FUNCTION = 'function',
	ANY = 'any',
	CHAR = 'char',
	STRING = 'string',
	NUMBER = 'number',
	INT = 'int',
	UINT = 'uint',
	FLOAT = 'float',
	BOOLEAN = 'boolean',
	NIL = 'nil',
	NEVER = 'never',
	VOID = 'void',
	UNION = 'union',
	OPTIONAL = 'optional',
	INTERSECTION = 'intersection',
	GENERIC = 'generic',
}
export interface Type {
	typeKind: TypeKind;
	isRestParameter?: boolean;
	genericParameters?: Type[];
	tag?: string;
	isMutable?: boolean;
}
export interface GenericType {
	typeKind: TypeKind.GENERIC;
	tag: string;
	extendingType: Type;
}
export interface TupleType extends Type {
	typeKind: TypeKind.TUPLE;
	elementTypes: Type[];
	genericTypes?: GenericType[];
}
export interface FunctionType extends Type {
	typeKind: TypeKind.FUNCTION;
	parameterTypes: Type[];
	returnType: ReturnType;
	genericTypes?: GenericType[];
}
export interface UnionType extends Type {
	typeKind: TypeKind.UNION;
	allowedTypes: Type[];
}
export interface IntersectionType extends Type {
	typeKind: TypeKind.INTERSECTION;
	requiredTypes: Type[];
}
export interface OptionalType extends Type {
	typeKind: TypeKind.OPTIONAL;
	optionalType: Type;
}
export interface ReturnType extends Type {
	isYielding?: boolean;
}
export interface ArrayType extends Type {
	typeKind: TypeKind.ARRAY;
	valueType: Type;
}
export interface DictionaryType extends Type {
	typeKind: TypeKind.DICTIONARY;
	keyType: Type;
	valueType: Type;
}
export interface AliasType extends Type {
	typeKind: TypeKind.ALIAS;
	aliasName: string;
}
export interface TableType extends Type {
	typeKind: TypeKind.TABLE;
	dimensions: { isArray: boolean }[];
	elementType: Type;
}

export function stringifyType(type: Type) {
	let typeString;
	switch (type.typeKind) {
		case TypeKind.ALIAS:
			typeString = (type as AliasType).aliasName;
			break;
		case TypeKind.OPTIONAL:
			typeString = stringifyType((type as OptionalType).optionalType) + '?';
			break;
		case TypeKind.TABLE:
			const tableType = type as TableType;
			typeString =
				stringifyType(tableType.elementType) +
				tableType.dimensions.map(dim => (dim.isArray ? '[]' : '{}')).join('');
			break;
		case TypeKind.FUNCTION:
			const functionType = type as FunctionType;
			typeString =
				'(' +
				functionType.parameterTypes.map(type => stringifyType(type)).join(', ') +
				') -> ' +
				stringifyType(functionType.returnType);
			break;
		case TypeKind.ARRAY:
			const arrayType = type as ArrayType;
			typeString = '{' + (arrayType.valueType ? stringifyType(arrayType.valueType) : '') + '}';
			break;
		case TypeKind.TUPLE:
			const tupleType = type as TupleType;
			typeString = tupleType.elementTypes.map(type => stringifyType(type)).join(', ');
			break;
		case TypeKind.UNION:
			const unionType = type as UnionType;
			typeString = unionType.allowedTypes.map(type => stringifyType(type)).join(' | ');
			break;
		case TypeKind.INTERSECTION:
			const intersectionType = type as IntersectionType;
			typeString = intersectionType.requiredTypes.map(type => stringifyType(type)).join(' & ');
			break;
		case TypeKind.DICTIONARY:
			const dictionaryType = type as DictionaryType;
			typeString =
				'{[' +
				stringifyType(dictionaryType.keyType) +
				']: ' +
				stringifyType(dictionaryType.valueType) +
				'}';
			break;
		default:
			typeString = type.typeKind;
			break;
	}
	return (
		(type.tag ? type.tag + ': ' : '') +
		(type.isMutable ? 'mut ' : '') +
		(type.isRestParameter ? '...' : '') +
		typeString +
		(type.genericParameters
			? '<' + type.genericParameters.map(param => stringifyType(param)).join(', ') + '>'
			: '')
	);
}
