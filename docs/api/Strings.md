
# Strings

Useful functions to manipulate strings, based on similar implementations in other standard libraries.



## Functions

<div class="rodocs-trait">Chainable</div>
### camelCase 

```lua
function _.camelCase(str) --> string
```
Convert `str` to camel-case.






**Parameters**

> __str__ - _string_
>

**Returns**


> _string_

**Examples**

```lua
_.camelCase('Foo Bar') --> 'fooBar'

_.camelCase('--foo-bar--') --> 'fooBar'

_.camelCase('__FOO_BAR__') --> 'fooBar'

```

---

<div class="rodocs-trait">Chainable</div>
### capitalize 

```lua
function _.capitalize(str) --> string
```
Capitalize the first letter of `str`.




**Parameters**

> __str__ - _string_
>

**Returns**


> _string_

**Examples**

```lua
_.capitalize("hello world") --> "Hello world"

```

---

<div class="rodocs-trait">Chainable</div>
### endsWith 

```lua
function _.endsWith(str, ending) --> string
```
Checks if `str` ends with the string `ending`.





**Parameters**

> __str__ - _string_
>
> __ending__ - _string_
>

**Returns**


> _string_

**Examples**

```lua
_.endsWith("Roblox Games", "Games") --> true

_.endsWith("Roblox Conference", "Games") --> false

```

---

<div class="rodocs-trait">Chainable</div>
### escape 

```lua
function _.escape(str) --> string
```
Converts the characters `&<>"'` in `str` to their corresponding HTML entities.




**Parameters**

> __str__ - _string_
>

**Returns**


> _string_

**Examples**

```lua
_.escape("<a>Fish & Chips</a>") --> "&lt;a&gt;Fish &amp; Chips&lt;/a&gt;"

```

---

<div class="rodocs-trait">Chainable</div>
### kebabCase 

```lua
function _.kebabCase(str) --> string
```
Convert `str` to kebab-case, making all letters lowercase.







**Parameters**

> __str__ - _string_
>

**Returns**


> _string_

**Examples**

```lua
_.kebabCase('fooBar') --> 'foo-bar'

_.kebabCase(' Foo Bar ') --> 'foo-bar'

_.kebabCase('__FOO_BAR__') --> 'foo-bar'

```

**Usage**

* Chain with `:upper()` if you need an upper kebab-case string.

---

<div class="rodocs-trait">Chainable</div>
### leftPad 

```lua
function _.leftPad(str, length, prefix) --> string
```
Makes a string of `length` from `str` by repeating characters from `prefix` at the start of the string.







**Parameters**

> __str__ - _string_
>
> __length__ - _string_
>
> __prefix__ - _string_
>

**Returns**


> _string_

**Examples**

```lua
_.leftPad("yes", 4) --> " yes"

_.leftPad("2", 2, "0") --> "02"

_.leftPad("hi", 10, ":-)") --> ":-):-):-hi"

```

---

<div class="rodocs-trait">Chainable</div>
### rightPad 

```lua
function _.rightPad(str, length, suffix) --> string
```
Makes a string of `length` from `str` by repeating characters from `suffix` at the end of the string.







**Parameters**

> __str__ - _string_
>
> __length__ - _string_
>
> __suffix__ - _string_
>

**Returns**


> _string_

**Examples**

```lua
_.leftPad("yes", 4) --> "yes "

_.leftPad("2", 2, "!") --> "2!"

_.leftPad("hi", 10, ":-)") --> "hi:-):-):-"

```

---

<div class="rodocs-trait">Chainable</div>
### snakeCase 

```lua
function _.snakeCase(str) --> string
```
Convert `str` to kebab-case, making all letters uppercase.







**Parameters**

> __str__ - _string_
>

**Returns**


> _string_

**Examples**

```lua
_.snakeCase('fooBar') --> 'FOO_BAR'

_.snakeCase(' Foo Bar ') --> 'FOO_BAR'

_.snakeCase('--foo-bar--') --> 'FOO_BAR'

```

**Usage**

* Chain with `:lower()` if you need a lower snake-case string.

---

<div class="rodocs-trait">Chainable</div>
### splitByPattern 

```lua
function _.splitByPattern(str, delimiter) --> string
```
Splits `str` into parts based on a pattern delimiter and returns a table of the parts.







**Parameters**

> __str__ - _string_
>
> __delimiter__ - _string_
>

**Returns**


> _string_

**Examples**

```lua
_.split("nice") --> {"n", "i", "c", "e"}

_.split("one, two,,  four", ",%s*") --> {"one", "two", "", "four"}

```

**Usage**

* This method is useful only when you need a _pattern_ for delimiter. Use the Roblox native `string.split` if you a splitting on a simple string.

---

<div class="rodocs-trait">Chainable</div>
### startsWith 

```lua
function _.startsWith(str, start) --> string
```
Checks if `str` starts with the string `start`.





**Parameters**

> __str__ - _string_
>
> __start__ - _string_
>

**Returns**


> _string_

**Examples**

```lua
_.startsWith("Roblox Games", "Roblox") --> true

_.startsWith("Minecraft Games", "Roblox") --> false

```

---

<div class="rodocs-trait">Chainable</div>
### titleCase 

```lua
function _.titleCase(str) --> string
```
Convert `str` to title-case, where the first letter of each word is capitalized.







**Parameters**

> __str__ - _string_
>

**Returns**


> _string_

**Examples**

```lua
_.titleCase("hello world") --> "Hello World"

_.titleCase("hello-there world_visitor") --> "Hello-there World_visitor"

_.titleCase("hello world's end don’t panic") --> "Hello World's End Don’t Panic"

```

**Usage**

* Dashes, underscores and apostraphes don't break words.

---

<div class="rodocs-trait">Chainable</div>
### trim 

```lua
function _.trim(str) --> string
```
Removes any spaces from the start and end of `str`.




**Parameters**

> __str__ - _string_
>

**Returns**


> _string_

**Examples**

```lua
_.trim("  full moon  ") --> "full moon"

```

---

<div class="rodocs-trait">Chainable</div>
### unescape 

```lua
function _.unescape(str) --> string
```
The inverse of `_.escape`.
Converts any escaped HTML entities in `str` to their corresponding characters.




**Parameters**

> __str__ - _string_
>

**Returns**


> _string_

**Examples**

```lua
_.unescape("&#34;Hello&quot; &apos;World&#39;") --> [["Hello" 'World']]

```

