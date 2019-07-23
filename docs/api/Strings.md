
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
_.camelCase('Pepperoni Pizza') --> 'pepperoniPizza'

_.camelCase('--pepperoni-pizza--') --> 'pepperoniPizza'

_.camelCase('__PEPPERONI_PIZZA') --> 'pepperoniPizza'

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
_.capitalize("hello mould") --> "Hello mould"

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
_.endsWith("Fun Roblox Games", "Games") --> true

_.endsWith("Bad Roblox Memes", "Games") --> false

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
_.kebabCase('strongStilton') --> 'strong-stilton'

_.kebabCase(' Strong Stilton ') --> 'strong-stilton'

_.kebabCase('__STRONG_STILTON__') --> 'strong-stilton'

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
_.leftPad("toast", 6) --> " toast"

_.leftPad("2", 2, "0") --> "02"

_.leftPad("toast", 10, ":)") --> ":):):toast"

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
_.leftPad("toast", 6) --> "toast "

_.leftPad("2", 2, "!") --> "2!"

_.leftPad("toast", 10, ":)") --> "toast:):):"

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
_.snakeCase('sweetChickenCurry') --> 'SWEET_CHICKEN_CURRY'

_.snakeCase(' Sweet Chicken  Curry ') --> 'SWEET_CHICKEN__CURRY'

_.snakeCase('--sweet-chicken--curry--') --> 'SWEET_CHICKEN__CURRY'

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
_.split("rice") --> {"r", "i", "c", "e"}

_.split("one, two,,  flour", ",%s*") --> {"one", "two", "", "flour"}

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
_.startsWith("Fun Roblox Games", "Roblox") --> true

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
_.titleCase("jello world") --> "Jello World"

_.titleCase("yellow-jello with_sprinkles") --> "Yellow-jello With_sprinkles"

_.titleCase("yellow jello's don’t mellow") --> "Yellow Jello's Dont’t Mellow"

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
_.trim("  roast veg  ") --> "roast veg"

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
_.unescape("&#34;Smashed&quot; &apos;Avocado&#39;") --> [["Smashed" 'Avocado']]

```

