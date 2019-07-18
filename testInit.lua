script = {
	Async = "Async",
	Iterators = "Iterators",
	Tables = "Tables",
	Classes = "Classes",
	Functions = "Functions",
	Parent = {
		t = "t",
		Promise = "roblox-lua-promise"
	}
}
Random = {
	new = function()
		local n = 0
		return {
			NextNumber = function()
				n = n + 1
				return n
			end
		}
	end
}
clock = {
	time = 0,
	events = {},
	process = function()
		local events = {}
		for _, event in ipairs(clock.events) do
			if event.time <= clock.time then
				event.fn()
			else
				table.insert(events, event)
			end
		end
		clock.events = events
	end,
	reset = function()
		clock.time = 0
	end
}
tick = function()
	return clock.time
end
spawn = function(fn)
	table.insert(clock.events, {time = clock.time, fn = fn})
end
delay = function(delayInSeconds, fn)
	table.insert(clock.events, {time = clock.time + delayInSeconds, fn = fn})
end
wait = function(delayInSeconds)
	clock.time = clock.time + delayInSeconds
end
warn = function(...)
	print("[WARN]", ...)
end
