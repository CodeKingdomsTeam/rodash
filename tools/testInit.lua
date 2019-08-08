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
	Strings = "Strings",
	Parent = {
		t = "t",
		Promise = "roblox-lua-promise",
		luassert = "luassert"
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
warn = function(...)
	print("[WARN]", ...)
end
