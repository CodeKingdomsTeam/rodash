
# Functions



## Functions

### compose 

```lua
function _.compose() --> string
```


**Parameters**

> __undefined__ - _string_
>

**Returns**


> _string_

---

### debounce 

```lua
function _.debounce(fn, secondsDelay) --> string
```
Creates a debounced function that delays invoking fn until after secondsDelay seconds have elapsed since the last time the debounced function was invoked.


**Parameters**

> __fn__ - _string_
>
> __secondsDelay__ - _string_
>

**Returns**


> _string_

---

### defaultSerializeArgs 

```lua
function _.defaultSerializeArgs(fnArgs) --> string
```


**Parameters**

> __fnArgs__ - _string_
>

**Returns**


> _string_

---

### isCallable 

```lua
function _.isCallable(thing) --> string
```


**Parameters**

> __thing__ - _string_
>

**Returns**


> _string_

---

### memoize 

```lua
function _.memoize(fn, serializeArgs) --> string
```
Cache results of a function such that subsequent calls return the cached result rather than
call the function again.

By default, a cached result is stored for each separate combination of serialized input args.
Optionally memoize takes a serializeArgs function which should return a key that the result
should be cached with for a given call signature. Return nil to avoid caching the result.


**Parameters**

> __fn__ - _string_
>
> __serializeArgs__ - _string_
>

**Returns**


> _string_

---

### once 

```lua
function _.once(fn, default) --> string
```


**Parameters**

> __fn__ - _string_
>
> __default__ - _string_
>

**Returns**


> _string_

---

### returnsArgs 

```lua
function _.returnsArgs() --> string
```


**Parameters**

> __undefined__ - _string_
>

**Returns**


> _string_

---

### returnsNil 

```lua
function _.returnsNil() --> string
```


**Returns**


> _string_

---

### setInterval 

```lua
function _.setInterval(fn, secondsDelay) --> string
```


**Parameters**

> __fn__ - _string_
>
> __secondsDelay__ - _string_
>

**Returns**


> _string_

---

### setTimeout 

```lua
function _.setTimeout(fn, secondsDelay) --> string
```


**Parameters**

> __fn__ - _string_
>
> __secondsDelay__ - _string_
>

**Returns**


> _string_

---

### throttle 

```lua
function _.throttle(fn, secondsCooldown) --> string
```
Creates a throttle function that drops any repeat calls within a cooldown period and instead returns the result of the last call


**Parameters**

> __fn__ - _string_
>
> __secondsCooldown__ - _string_
>

**Returns**


> _string_

