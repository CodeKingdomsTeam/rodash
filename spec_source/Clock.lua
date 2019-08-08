local function setup()
	local restoreFns = {}
	local clock = {
		time = 0,
		events = {}
	}
	function clock:process()
		local events = {}
		table.sort(
			self.events,
			function(a, b)
				return a.time < b.time
			end
		)
		for _, event in ipairs(self.events) do
			if event.time <= self.time then
				event.fn()
			else
				table.insert(events, event)
			end
		end
		self.events = events
	end
	function clock:teardown()
		self.time = 0
		self.events = {}
		for name, fn in pairs(restoreFns) do
			_G[name] = fn
		end
	end
	local stubs = {
		tick = function()
			return clock.time
		end,
		spawn = function(fn)
			table.insert(clock.events, {time = clock.time, fn = fn})
		end,
		delay = function(delayInSeconds, fn)
			table.insert(clock.events, {time = clock.time + delayInSeconds, fn = fn})
		end,
		wait = function(delayInSeconds)
			clock.time = clock.time + delayInSeconds
		end
	}
	for name, fn in pairs(stubs) do
		restoreFns[name] = _G[name]
		_G[name] = fn
	end
	return clock
end

return {
	setup = setup
}
