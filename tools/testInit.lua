if arg[1] == "debug" then
	package.cpath = package.cpath .. ";tools/?.dylib"
	local lrdb = require("lrdb_server")
	print("Waiting for debugger to attach...")
	lrdb.activate(21110)
end

script = {
	Async = "Async",
	Tables = "Tables",
	Classes = "Classes",
	Functions = "Functions",
	Arrays = "Arrays",
	Strings = "Strings",
	Parent = {
		Async = "Async",
		Tables = "Tables",
		Classes = "Classes",
		Functions = "Functions",
		Arrays = "Arrays",
		Strings = "Strings",
		Parent = {
			t = "t",
			Promise = "roblox-lua-promise",
			luassert = "luassert"
		}
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
		table.sort(
			clock.events,
			function(a, b)
				return a.time < b.time
			end
		)
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
		clock.events = {}
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
