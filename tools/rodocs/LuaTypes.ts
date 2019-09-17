import { stringify } from 'querystring';

export enum TypeKind {
	DEFINITION = 'definition',
	TABLE = 'table',
	ARRAY = 'array',
	DICTIONARY = 'dictionary',
	TUPLE = 'tuple',
	ALIAS = 'alias',
	FAIL = 'fail',
	FUNCTION = 'function',
	ANY = 'any',
	CHAR = 'char',
	STRING = 'string',
	NUMBER = 'number',
	INT = 'int',
	UINT = 'uint',
	FLOAT = 'float',
	BOOL = 'bool',
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

export enum PLURALITY {
	SINGULAR,
	PLURAL,
}

export interface MetaDescription {
	rootUrl: string;
	generics: { [genericKey: string]: string };
}

function pluralizeName(name: string, plurality?: PLURALITY) {
	const useAn = name.match(/(^[aeiou].)|(^[aefhilmnorsx][0-9]*$)/i);
	switch (plurality) {
		case PLURALITY.SINGULAR:
			return (useAn ? 'an ' : 'a ') + name;
		case PLURALITY.PLURAL:
			const commonPluralizations = {
				dictionary: 'dictionaries',
				strategy: 'strategies',
			};
			return commonPluralizations[name] ? commonPluralizations[name] : name + 's';
		default:
			return name;
	}
}
function joinList(values: string[]) {
	const output = [];
	if (values.length === 0) {
		return 'nothing';
	}
	for (let i = 0; i < values.length - 2; i++) {
		output.push(values[i] + ', ');
	}
	for (let i = Math.max(values.length - 2, 0); i < values.length - 1; i++) {
		output.push(values[i] + ' and ');
	}
	output.push(values[values.length - 1]);
	return output.join('');
}

export function getCommonNameForTypeVariable(name: string) {
	const commonNames = {
		A: 'the primary arguments',
		A2: 'the secondary arguments',
		K: 'the primary key type',
		K2: 'the secondary key type',
		R: 'the result type',
		S: 'the subject type',
		T: 'the primary type',
		T2: 'the secondary type',
		V: 'the primary value type',
		V2: 'the secondary value type',
	};
	return commonNames[name];
}

export function describeGeneric(type: GenericType, meta?: MetaDescription) {
	const commonName = getCommonNameForTypeVariable(type.tag);
	const name = commonName ? commonName : type.tag;
	if (meta) {
		return name + ' (extends ' + describeType(type.extendingType, meta, PLURALITY.SINGULAR) + ')';
	} else {
		return name;
	}
}

export function describeType(type: Type, meta: MetaDescription, plurality?: PLURALITY): string {
	let typeString: string;
	if (type.isRestParameter) {
		plurality = PLURALITY.PLURAL;
	}
	switch (type.typeKind) {
		case TypeKind.ALIAS:
			const name = (type as AliasType).aliasName;
			if (meta.generics[name]) {
				typeString = meta.generics[name];
			} else {
				typeString = `[${pluralizeName(name, plurality)}](${meta.rootUrl}types/#${name})`;
			}
			break;
		case TypeKind.OPTIONAL:
			const optionalType = describeType((type as OptionalType).optionalType, meta, plurality);
			typeString = optionalType + ' (optional)';
			break;
		case TypeKind.TABLE:
			const tableType = type as TableType;
			const elementType = describeType(tableType.elementType, meta, PLURALITY.PLURAL);
			if (tableType.dimensions.length === 1) {
				const dim = tableType.dimensions[0];
				const name = pluralizeName(dim.isArray ? 'array' : 'dictionary', plurality);
				typeString = name + ' (of ' + elementType + ')';
			} else {
				const dimensionString = pluralizeName(tableType.dimensions.length + 'd', plurality);
				const namePlurality = plurality === PLURALITY.SINGULAR ? undefined : plurality;
				const name = pluralizeName(
					tableType.dimensions[0].isArray ? 'array' : 'dictionary',
					namePlurality,
				);
				typeString = dimensionString + ' ' + name + ' (of ' + elementType + ')';
			}
			break;
		case TypeKind.FUNCTION:
			const functionType = type as FunctionType;
			typeString =
				pluralizeName('function', plurality) +
				' (taking ' +
				joinList(
					functionType.parameterTypes.map(type => describeType(type, meta, PLURALITY.SINGULAR)),
				) +
				', and returning ' +
				describeType(functionType.returnType, meta, PLURALITY.SINGULAR) +
				')';
			break;
		case TypeKind.ARRAY:
			const arrayType = type as ArrayType;
			if (arrayType.valueType) {
				typeString =
					pluralizeName('array', plurality) +
					' (of ' +
					describeType(arrayType.valueType, meta, PLURALITY.PLURAL) +
					')';
			} else {
				typeString = pluralizeName('table', plurality);
			}
			break;
		case TypeKind.TUPLE:
			const tupleType = type as TupleType;
			typeString =
				pluralizeName('tuple', plurality) +
				' (' +
				joinList(tupleType.elementTypes.map(type => describeType(type, meta, PLURALITY.SINGULAR))) +
				')';
			break;
		case TypeKind.UNION:
			const unionType = type as UnionType;
			typeString = unionType.allowedTypes
				.map(type => describeType(type, meta, plurality))
				.join(' or ');
			break;
		case TypeKind.INTERSECTION:
			const intersectionType = type as IntersectionType;
			typeString =
				pluralizeName('intersection', plurality) +
				' (of ' +
				joinList(
					intersectionType.requiredTypes.map(type => describeType(type, meta, PLURALITY.SINGULAR)),
				) +
				')';
			break;
		case TypeKind.DICTIONARY:
			const dictionaryType = type as DictionaryType;
			typeString =
				'a dictionary mapping ' +
				describeType(dictionaryType.keyType, meta, PLURALITY.PLURAL) +
				' to ' +
				describeType(dictionaryType.valueType, meta, PLURALITY.PLURAL);
			break;
		case TypeKind.GENERIC:
			typeString = describeGeneric(type as GenericType);
			break;
		case TypeKind.ANY:
			typeString = plurality === PLURALITY.PLURAL ? 'any values' : 'any value';
			break;
		case TypeKind.NIL:
			typeString = 'nil';
			break;
		case TypeKind.VOID:
			typeString = 'nothing';
			break;
		case TypeKind.NEVER:
			typeString = 'a promise that never resolves';
			break;
		case TypeKind.BOOL:
			typeString = pluralizeName('boolean', plurality);
			break;
		case TypeKind.INT:
			typeString = pluralizeName('integer', plurality);
			break;
		case TypeKind.UINT:
			typeString = pluralizeName('unsigned integer', plurality);
			break;
		case TypeKind.FAIL:
			typeString = pluralizeName('failure state', plurality);
			break;
		default:
			typeString = pluralizeName(type.typeKind, plurality);
			break;
	}
	const useTag = type.tag && type.typeKind !== TypeKind.GENERIC;
	return (
		(useTag ? '_' + type.tag + '_ (' : '') +
		typeString +
		(type.genericParameters
			? ' (of ' + joinList(type.genericParameters.map(param => describeType(param, meta))) + ')'
			: '') +
		(type.isMutable ? ' (which can be mutated)' : '') +
		(useTag ? ')' : '')
	);
}

export function getMetaDescription(type: Type, meta: MetaDescription) {
	switch (type.typeKind) {
		case TypeKind.FUNCTION:
			const functionType = type as FunctionType;
			if (functionType.genericTypes) {
				for (const param of functionType.genericTypes) {
					if (param.tag) {
						meta.generics[param.tag] = describeGeneric(param);
						getMetaDescription(param.extendingType, meta);
					}
				}
			}
			break;
	}
	if (type.genericParameters) {
		for (const param of type.genericParameters) {
			if (type.typeKind === TypeKind.ALIAS) {
				const name = (param as AliasType).aliasName;
				const commonName = getCommonNameForTypeVariable(name);
				if (commonName) {
					meta.generics[name] = commonName;
				}
			}
		}
	}
	return meta;
}
