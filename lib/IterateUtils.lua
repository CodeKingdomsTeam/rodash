local IterateUtils = {}

local function getNext(source)
	if type(source) == "function" then
		return source
	else
		assert(type(source) == "table", "Can only iterate over an array or an iterator function")
		local key = 0
		return function()
			key = key + 1
			if source[key] == nil then
				return
			else
				return key, source[key]
			end
		end
	end
end

function IterateUtils.getInsertionSafeIterator(source)
	local next = getNext(source)
	local insertStack = {}
	local outputIndex = 0

	local iterator = {}
	function iterator:insertAhead(element)
		table.insert(insertStack, element)
	end

	return function()
		outputIndex = outputIndex + 1
		if #insertStack > 0 then
			local stackHead = insertStack[#insertStack]
			table.remove(insertStack, #insertStack)
			iterator.value = stackHead
			iterator.outputKey = outputIndex
			return outputIndex, iterator
		else
			local key, value = next()
			if key == nil then
				return
			end
			iterator.value = value
			iterator.outputKey = outputIndex
			iterator.inputKey = key
			return outputIndex, iterator
		end
	end
end

return IterateUtils
