Every function in Rodash is dynamically and statically typed.

This means you know what arguments  Rodash functions can take and what they can return when you write your code, and Rodash will also check that you've passed in valid values when you run it.

## Dynamic Typing

Dynamic typing means checking that the values passed into a function are valid when the function is run. Rodash functions will throw a `BadInput` error if any arguments are invalid, allowing you to catch errors quickly and fail fast during development.

Rodash uses [the "t" library](https://github.com/osyrisrblx/t) by Osyris to perform runtime type assertions, which we recommend using in your own code during development and production code.

## Static Typing

Lua is a dynamically-typed language, which means that you can't tell from normal Lua source code what type of values you should use when calling functions, unless you understand how the function internals work.

Rodash uses a type language that borrows heavily from the Typescript type language.

Types are added using optional annotations, which are added using `--:`. For example:

```lua
--: string, string -> bool
function endsWith(str, suffix)
```

This states that `dash.endsWith` takes two string arguments and returns a boolean.

## Lua primitives

These types correspond to basic Lua types:

| Name | Type | Description |
| --- | --- | --- |
| Number | `number` | A Lua number |
| String | `string` | A Lua string |
| Boolean | `bool` | A Lua boolean |
| Nil | `nil` | The Lua nil |
| Userdata | `userdata` | A Lua userdata object |
| Table | `table` | A Lua table i.e. with `type(value) == "table"` |

## Extended primitives

| Name | Usage | Description |
| --- | --- | --- |
| Any | `any` | A type representing all of the valid types (excluding fail) |
| Some | `some` | A type representing all of the valid non-nil types |
| Character | `char` | A single character of a string |
| Pattern | `pattern` | A string representing a valid Lua pattern |
| Integer | `int` | An integer |
| Unsigned integer | `uint` | An unsigned (positive) integer |
| Float | `float` | A floating point number |
| Never | `never` | A Promise that never resolves |
| Void | `void` or `()` | An empty tuple, typically to represent an empty return type or empty function-arguments |
| Fail | `fail` | A return value which means that the function will always throw an error |

## Structural types

Like many scripting languages, Lua has a general structure type `table` which can be used to represent arrays, dictionaries, sets, classes, and many other data types. The type language uses a strict set of definitions for different ways tables can be used:

| Name | Usage | Description |
| --- | --- | --- |
| Tuple | `(X, Y, Z)` | Values of particular types separated by commas, such as an argument or return list in a Lua function |
| Array | `X[]` | A Lua table that has a finite number of [Ordered](/rodash/types/#Ordered) keys with values of type `X` |
| Fixed array | `{X, Y, Z}` | An array with a fixed number of values, where the first value has type `X`, the second type `Y` etc. |
| Table | `{}` | a Lua table with no specific keys or values |
| Dictionary | `X{}` | a Lua table which has values of type `X` |
| Map | `{[X]: Y}` | A Lua table with keys of type `X` mapping to values of type `Y` |
| Multi-dimensional table | `X[][]`<br/>`X{}{}`<br/>`X{}[]{}` | A 2d or higher dimensional table, with values being arrays, dictionaries or multi-dimensional tables themselves | 

Rodash methods use more general types where possible, specifically [Ordered](/rodash/types/#Ordered) and [Iterable](/rodash/types/#Iterable) values. This let's you operate on iterators as well as tables.

## Function types

| Name | Type | Description |
| --- | --- | --- |
| Function | `X, Y -> Z` | A callable value taking parameters with type `X` and `Y` and returning a value of type `Z` |
| Multiple returns | `X -> Y, Z` | A callable value taking a parameter of type `X` and returning two values of type `Y` and `Z` respectively |
| Void function | `() -> ()` | A function that takes no parameters and returns nothing |
| Rest function | `...X -> ...Y` | A function that takes any number of parameters of type `X` and returns any number values of type `Y` |

## Modifying types

These types can be used in function signatures:

| Name | Usage | Description |
| --- | --- | --- |
| Mutable parameter | `mut X` | A function which takes a value of type `mut X` may modify the value of type `X` during execution |
| Yield return | `yield X` | A function which returns `yield X` may yield when executed before returning a value of type `X` |
| Self | `self X` | A function which takes `self X` as a parameter must be defined using `:` and called as a method on a value of type `X`. Only required if the method should be called on a different type to the one it is defined under |


### Callable

Any value that can be called has a function type. In practice, a value is callable if and only if it is one of the following:

* A Lua `function`
* A Lua `CFunction`
* A Lua `table` with a metatable that has a valid `__call` property defined

This is more general than just checking if a value has a function type.

**Usage**

You can test if a value is callable using `dash.isCallable`.

## Composite types

| Name | Type | Description |
| --- | --- | --- |
| Optional | `X?` | Equivalent to the type `X | nil`, meaning a value of this type either has type `X` or `nil` |
| Union | `X | Y` | Values of this type can either be of type `X` or of type `Y` (or both) |
| Intersection | `X & Y` | Values of this type must be of both types `X` and `Y`. For example, if `X` and `Y` are interfaces the value must implement both of them. |

## Generic types

Generics allow the same function to be used with different types. Known types are replaced with type variables, which are usually single capital letters such as `T` or `K`, but can be any word beginning with a capital letter.

When a generic function is called, the same type variable must refer to the same type everywhere it appears in the type definition. 

| Name | Type | Description |
| --- | --- | --- |
| Generic function | `<T>(T -> T)` | A generic function that takes a parameter of type `T` and returns a value of the same type `T` |
| Generic arguments | `<A>(...A -> A)` | A generic function that takes any number of parameters of type `A` and returns a value of the same type `A` |
| Generic bounds | `<T: X>(T -> T)` | A function that has a type variable `T` which must satisfy the type `X` |
| Parameterized object | `X<T>` | An object of type `X` that is parameterized to type `T` |

**Examples**

The `dash.last` function returns the last element of an array, and has a type signature of `<T>(T[] -> T)`. If you call it with an array of strings with type `string[]`, then `T = string` and the function becomes parameterized, meaning its type `string[] -> string`. This shows you that the function will return a `string`. If you simply used `any[] -> any` without using a generics, you couldn't know that the function always returned a value of the same type.

Like `T[]` was parameterized as a string array when `T = string`, any structural types like dictionaries or [Classes](/rodash/types/#Classes) can also parameterized.

**Usage**

Note that using `...X` when `X` refers to a tuple expands the elements from the tuple in-order, as a value can't have a tuple type itself. For example, `dash.id` has the type signature `<A>(...A -> ...A)`. If you call `id(1, "Hello")` then `A = (number, string)` and the function becomes typed as: `number, string -> number, string`.

## Iterable types

### Iterators

An iterator is a function which returns `(key, value)` pairs when it is called. You might not use them often in your own code but they are very common in Lua - any loop you write takes an iterator. For example `ipairs(object)` in the code:
```lua
for key, value in ipairs(object) do
```

They are more abstract than using a concrete table to store data which means you can use them to:

- Represent an infinite list, such as countable sequences of numbers like the naturals.
- Represent a stream, such as a random stream or events coming from an input source.
- Avoid calculating all the elements of a list at once, such as a lazy list retrieving elements from an HTTP endpoint

You cannot modify the source of values in an iterator, so they are safer to use if you don't want a function changing the underlying source.

**Type**

`type Iterator<K,V> = (props: any, previousKey: K?) -> K, V`

**Generics**

> __K__ - `some` - the primary key type (can be any non-nil value)
>
> __V__ - `some` - the secondary key type (can be any non-nil value)

### Stateful Iterator

```lua
function statefulIterator() --> K, V
```

Stateful iterators take no arguments and simply return the next `(key, value)` pair when called. These are simple to make and prevent code from skipping or seeking to arbitrary elements in the underlying source.

You can use `dash.iterator` to create your own iterator for a table. This is useful where you cannot use `pairs` or `ipairs` natively such as when using read-only objects - see `dash.freeze`.

**Type**

`<K,V>(() -> K, V)`

**Generics**

> __K__ - `some` - the primary key type (can be any non-nil value)
>
> __V__ - `some` - the secondary key type (can be any non-nil value)

**Examples**

```lua
-- Calling range returns a stateful iterator that counts from a to b.
function range(a, b)
	local key = 0
	return function()
		local value = a + key
		key = key + 1
		if value <= b then
			return key, value
		end
	end
end
```

**Usage**

Stateful iterators that you write can be used in any Rodash function that takes an [Iterable](/rodash/types/#Iterable).

### Stateless Iterator

```lua
function statelessIterator(props, previousKey) --> K, V
```

Stateless iterators take two arguments `(props, previousKey)` which are used to address a `(key, value)` pair to return.

A stateless iterator should return the first `(key, value)` pair if the _previousKey_ `nil` is passed in.

**Type**

`<K,V>((any, K?) -> K, V)`

**Properties**

> __props__ - `any` - any value - the static properties that the iterator uses
> __previousKey__ - `K?` - the iterator state type (optional) - (default = `nil`) the previous key acts as the state for the iterator so it doesn't need to store its own state

**Generics**

> __K__ - `some` - the primary key type (can be any non-nil value)
>
> __V__ - `some` - the secondary key type (can be any non-nil value)
>
> __S__ - `some` - the iterator state type (can be any non-nil value)

**Examples**

```lua
-- This function is a stateless iterator 
function evenNumbers(_, previousKey)
	local key = (previousKey or 0) + 1
	return key, key * 2
end
```

**Usage**

Stateless iterators that you write can be used in any Rodash function that takes an [Iterable](/rodash/types/#Iterable).

### Iterable

An iterable value is either a dictionary or an [Iterator](/rodash/types/#Iterator). Many Rodash functions can operate on iterator functions as well as tables.

**Type**

`type Iterable<K,V> = {[K]:V} | Iterator<K,V>`

**Generics**

> __K__ - `any` - the primary key type (can be any value)
>
> __V__ - `any` - the primary value type (can be any value)

**See**

- [Iterator](/rodash/types/#Iterator)

### Ordered

An ordered value is either an array or an ordered [Iterator](/rodash/types/#Iterator). For something to be ordered, the keys returned during iteration must be the natural numbers. This means the first key must be `1`, the second `2`, the third `3`, etc.

**Type**

`type Ordered<V> = V[] | Iterator<number,V>`

**Generics**

> __V__ - `any` - the primary value type (can be any value)

**Usage**

For example, you could write an ordered iterator of numbers, and `dash.first` will to return the first number which matches a particular condition.

**See**

- [Iterator](/rodash/types/#Iterator)

## Asynchronous types

### Promise

Any promise value created using the [Roblox Lua Promise](https://github.com/LPGhatguy/roblox-lua-promise) library has `Promise<T>` type. See the documentation of this library for examples on how to use promises.

**Type**

`interface Promise<T>`

**Generics**

> __T__ - `any` - the primary type (can be any value)

### Yieldable

A marker type for a function which may yield. We recommend you use promises instead of writing your own yielding functions as they can have unpredictable behavior, such as causing threads to block outside your control.

Because of this, only functions which are marked as yieldable are assumed to be capable of yielding.

**Type**

`type Yieldable<T> = ... -> yield T`

**Generics**

> __T__ - `any` - the primary type (can be any value)

### Async

A marker type for a function which returns a promise.

**Type**

`type Async<T> = ... -> Promise<T>`

**Generics**

> __T__ - `any` - the primary type (can be any value)

## Class types

### Class

Classes are the building block of object-oriented programming and are represented as tables in Lua. Every class instance has a metatable which points back to its class, allowing it to inherit class methods.

A class definition defines the unique type `T`. Any instance of the class satisfies the type `T`.

**Type**

`interface Class<T:{}>`

**Generics**

> __T__ - `{}` - the class instance type (can be a table)

**Properties**

| Property | Type | Description | 
|---|---|---|
| **name** | `string` | the name of the class |
| **new(...)** | `Constructor<T>` | returns a new instance of the class |

**See**

* [Classes](/rodash/api/Classes) - for a full list of methods on a class created with `dash.class`.

### Constructor

A marker type for functions which return a new instance of a particular class.

**Type**

`type Constructor<T:{}> = ... -> T`

**Generics**

> __T__ - `{}` - the class instance type (can be a table)

### Enum

A marker type for an enumeration. An enumeration is a fixed dictionary of unique values that allow
you to name different states that a value can take.

An enum definition defines the unique type `T`. Any value which is equal to a value in the 
enumeration satisfies the type `T`.

**Type**

`type Enum<T:some> = {[key:string]:T}`

**Generics**

> __T__ - `some` - the unique type of the enum (can be any non-nil value)

**See**

* `dash.enum` - to create and use your own string enums.

### Symbol

A marker type for a symbol.

An symbol definition defines the unique type `T`. Only the value of the symbol satisfies the type
`T`.

**Type**

`type Symbol<T:some>`

**Generics**

> __T__ - `some` - the unique type of the symbol (can be any non-nil value)

**See**

* `dash.symbol` - to create and use your own symbols.

## Decorator types

### Decorator

A marker type for decorator functions. A decorator is a function that takes a class and returns a
modified version of the class which new behavior.

**Type**

`type Decorator<T:{}> = Class<T> -> Class<T>`

**Generics**

> __T__ - `{}` - the class instance type (can be a table)

### Cloneable

An interface that lets implementors be cloned.

**Type**

`interface Cloneable<T:{}>`

**Generics**

> __T__ - `{}` - the class instance type (can be a table)

**Properties**

| Property | Type | Description |
|---|---|---|
| **clone()** | `T` | returns a copy of the instance |

**See**

* `dash.Cloneable` - to derive a generated implementation of this interface.

### Ord

An interface that means implementors of the same type `T` form a total order, similar to the
[Rust Ord](https://doc.rust-lang.org/std/cmp/trait.Ord.html) trait.

**Type**

`interface Ord<T:{}>`

**Generics**

> __T__ - `{}` - the class instance type (can be a table)

**Properties**

Implementors can be compared using the ordering operators such as `<`, `<=`, and `==`.

An ordering means that you can compare any two elements `a` and `b`, and one is always greater
or equal to the other i.e. `a >= b == b < a` is always true.

**See**

* `dash.Ord` - to derive a generated implementation of this interface.

### Eq

An interface that means implementors of the same type `T` form an equivalence relation, similar to
the [Rust Eq](https://doc.rust-lang.org/std/cmp/trait.Eq.html) trait.

**Type**

`interface Eq<T:{}>`

**Generics**

> __T__ - `{}` - the class instance type (can be a table)

**Properties**

Implementors can be compared using the equality operators such as `==` and `~=`.

An equivalence relation means that you can compare any elements `a`, `b` and `c`, and these
properties are satisfied:

* Reflexive - `a == a` is always true
* Symmetric - if `a == b` then `b == a`
* Transitive - if `a == b && b == c` then `a == c`

**See**

* `dash.ShallowEq` - to derive a generated implementation of this interface.

## Chaining types

### Chain

A chain is a function which can operate on a _subject_ and return a value. They are built by
composing a "chain" of functions together, which means that when the chain is called, each
function runs on the subject in order, with the result of one function passed to the next.

A chain also provides methods based on the [Chainable](/rodash/types/#chainable) functions that the
chain is created with. Each one takes the additional arguments of the chainable and returns a new
chain that has the operation of the function called "queued" to the end of it.

**Type**

`type Chain<S,T:Chainable<S>{}> = Chainable<S> & (... -> Chain<S,T>){}`

**Generics**

> __S__ - `any` - the subject type (can be any value)
>
> __T__ - `Chainable<S>{}` - the chain's interface type (can be a dictionary (of [Chainables](/rodash/types/#chainable) (of the subject type)))

**See**

* `dash.chain` - to make you own chains
* `dash.fn` - to make a chain with Rodash functions

### Chainable

A marker type for any function that is chainable, meaning it takes a _subject_ as its first
argument and "operates" on that subject in some way using any additional arguments.

**Type**

`type Chainable<S> = S, ... -> S`

**Generics**

> __S__ - `any` - the subject type (can be any value)

### Actor

A marker type for a function that acts as an actor in a chain. An actor is a function that is
called to determine how each function in the chain should evaluate its arguments and the _subject_
value.

By default, a chain simply invokes the function with the subject and additional arguments.

Actors can be used to transform the types of subjects that functions can naturally deal with,
without having to change the definition of the functions themselves.

For example the `dash.maybe` actor factory allows functions to be skipped if the subject is `nil`,
and `dash.continue` allows functions to act with.

**Type**

`type Actor<S> = (S -> S), S, ... -> S`

**See**

* `dash.chain`
* `dash.maybe`
* `dash.continue`

## Library types

### Clearable

A stateful object with a `clear` method that resets the object state.

**Type**

`interface Clearable<A>`

**Generics**

> __A__ - `any` - the primary arguments

**Properties**

| Property | Type | Description | 
|---|---|---|
| **clear(...)** | `...A -> ()` | reset the object state addressed by the arguments provided |

**See**

* `dash.setTimeout`
* `dash.setInterval`
* `dash.memoize`

### AllClearable

A stateful object with a `clearAll` method that resets the all parts of the object state.

**Type**
`interface AllClearable`

**Properties**

| Property | Type | Description | 
|---|---|---|
| **clearAll()** | `() -> ()` | reset the entire object state |

**See**

* `dash.memoize`

### DisplayString

A DisplayString is a `string` that is a valid argument to `dash.formatValue`. Examples include:

* `#b` - prints a number in its binary representation
* `#?` - pretty prints a table using `dash.pretty`

**Usage**

See `dash.format` for a full description of valid display strings.


### SerializeOptions

Customize how `dash.serialize`, `dash.serializeDeep` and `dash.pretty` convert objects into strings using these options:

**Type**

`interface SeralizeOptions<T: Iterable<K,V>>`

**Generics**

> __K__ - `any` - the primary key type (can be any value)
>
> __V__ - `any` - the primary value type (can be any value)
>
> __T__ - `Iterable<K,V>` - An [Iterable](/rodash/types/#Iterable) (of the primary key type and the primary value type)

**Properties**

| Property | Type | Description | 
|---|---|---|
| **keys** | `K[]?` | (optional) if defined, only the keys present in this array will be serialized |
| **omitKeys** | `K[]?` | (optional) an array of keys which should not be serialized |
| **serializeValue(value)** | `V -> string` | (default = `dash.defaultSerializer`) returns the string representation for a value in the object |
| **serializeKey(key)** | `K -> string` | (default = `dash.defaultSerializer`) returns the string representation for a key in the object |
| **serializeElement(keyString, valueString, options)** | `string, string, SerializeOptions<T> -> string` | returns the string representation for a serialized key-value pair |
| **serializeTable(contents, ref, options)** | `string[], string?, SerializeOptions<T> -> string` | (default = returns "{elements}") given an array of serialized table elements and an optional reference, this returns the string representation for a table |
| **keyDelimiter** | `":"` | The string that is put between a serialized key and value pair |
| **valueDelimiter** | `","` | The string that is put between each element of the object |

### BackoffOptions

Customize the function of `dash.retryWithBackoff` using these options:

**Type**

`interface SeralizeOptions<T>`

**Generics**

> __T__ - `any` - the primary type

**Properties**

| Property | Type | Description |
|---|---|---|
| **maxTries** | `int` | how many tries (including the first one) the function should be called |
| **retryExponentInSeconds** | `number` | customize the backoff exponent |
| **retryConstantInSeconds** | `number` | customize the backoff constant |
| **randomStream** | `Random` | use a Roblox "Random" instance to control the backoff |
| **shouldRetry(response)** | `T -> bool` | called if maxTries > 1 to determine whether a retry should occur |
| **onRetry(waitTime, errorMessage)** | `(number, string) -> nil` | a hook for when a retry is triggered, with the delay before retry and error message which caused the failure |
| **onDone(response, durationInSeconds)** | `(T, number) -> nil` | a hook for when the promise resolves |
| **onFail(errorMessage)** | `string -> nil` | a hook for when the promise has failed and no more retries are allowed |