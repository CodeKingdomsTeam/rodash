
# Async



## Functions

### all 

```lua
function _.all(objects) --> string
```
    Given an array of objects, this function returns a promise which
    resolves once all of the array elements have resolved, or rejects
    if any of the array elements reject.

    Any objects in the array which aren't promises are considered
    resolved immediately.

    The promise resolves to an array mapping the input to resolved elements.


**Parameters**

> __objects__ - _string_
>

**Returns**


> _string_

---

### delay 

```lua
function _.delay(delayInSeconds) --> string
```
    Returns a promise which resolves after the given delayInSeconds.


**Parameters**

> __delayInSeconds__ - _string_
>

**Returns**


> _string_

---

### retryWithBackoff 

```lua
function _.retryWithBackoff(getPromise, backoffOptions) --> string
```
    Try running a function which returns a promise and retry if the function throws
    and error or the promise rejects. The retry behaviour can be adapted using
    backoffOptions, which can customize the maximum number of retries and the backoff
    timing of the form [0, x^attemptNumber] + y where x is an exponent that produces
    a random exponential delay and y is a constant delay.

    maxTries - how many tries (including the first one) the function should be called
    retryExponentInSeconds - customize the backoff exponent
retryConstantInSeconds - customize the backoff constant
    randomStream - use a Roblox "Random" instance to control the backoff
shouldRetry(response) - called if maxTries > 1 to determine whether a retry should occur
    onRetry(waitTime, errorMessage) - a hook for when a retry is triggered, with the delay before retry and error message which caused the failure
    onDone(response, durationMs) - a hook for when the promise resolves
    onFail(errorMessage) - a hook for when the promise has failed and no more retries are allowed


**Parameters**

> __getPromise__ - _string_
>
> __backoffOptions__ - _string_
>

**Returns**


> _string_

---

### wrapFn 

```lua
function _.wrapFn(fn) --> string
```
    Returns a promise for a function which may yield. wrapFn calls the
    the function in a coroutine and resolves with the output of the function
    after any asynchronous actions, and rejects if the function throws an error.


**Parameters**

> __fn__ - _string_
>

**Returns**


> _string_

