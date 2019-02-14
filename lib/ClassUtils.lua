local TableUtils = require(script.Parent.TableUtils)
local ClassUtils = {}

function ClassUtils.makeClass(name, constructor)
    local Class = {
        name = name,
        constructor = constructor or function()
                return {}
            end
    }
    function Class.new(...)
        local instance = Class.constructor(...)
        setmetatable(instance, {__index = Class, __tostring = Class.toString})
        return instance
    end
    function Class:extend(name, constructor)
        local Subclass = ClassUtils.makeClass(name, constructor or self.constructor)
        setmetatable(Subclass, {__index = self})
        return Subclass
    end
    function Class:toString()
        return self.name
    end
    return Class
end

function ClassUtils.makeWrapperClass(name)
    return ClassUtils.makeClass(
        name,
        function(data)
            return TableUtils.Clone(data)
        end
    )
end

function ClassUtils.makeEnum(keys)
    return TableUtils.KeyBy(
        keys,
        function(key)
            assert(key:match("^[A-Z_]+$"), "Enum keys must be defined as upper snake case")
            return key
        end
    )
end

function ClassUtils.makeSymbolEnum(keys)
    return TableUtils.Map(
        ClassUtils.makeEnum(keys),
        function(key)
            return ClassUtils.makeSymbol(key)
        end
    )
end

function ClassUtils.isA(instance, classOrEnum)
    local isEnum = type(instance) == "string"
    if isEnum then
        local isEnumKeyDefined = type(classOrEnum[instance]) == "string"
        return isEnumKeyDefined
    elseif type(instance) == "table" then
        if instance.__symbol and classOrEnum[instance.__symbol] == instance then
            return true
        end
        local metatable = getmetatable(instance)
        while metatable do
            if metatable.__index == classOrEnum then
                return true
            end
            metatable = getmetatable(metatable.__index)
        end
    end
    return false
end

function ClassUtils.makeSymbol(name)
    local symbol = {
        __symbol = name
    }
    setmetatable(
        symbol,
        {
            __tostring = function()
                return name
            end
        }
    )
end

return ClassUtils
