local t = require(script.Parent.Parent.t)
local Tables = require(script.Parent.Tables)
local Classes = require(script.Parent.Classes)

local function connectToStore(Class, mapStateToProps)
	local ConnectedClass =
		Class:extendWithInterface(
		"Connected(" .. Class.name .. ")",
		{
			store = t.interface(
				{
					changed = t.Signal
				}
			)
		}
	)

	function ConnectedClass:_init(...)
		local nextProps = Classes.makeFinal(mapStateToProps(self._store:getState()))
		self._props = nextProps
		if Class._init then
			return Class._init(self, ...)
		end
	end

	function ConnectedClass:mount()
		if self._connection then
			error(string.format("Cannot mount %s as it has already been mounted", self.Class.name))
		end
		self._connection =
			self._store.changed:connect(
			function(state)
				local nextProps = Classes.makeFinal(mapStateToProps(state))
				if self:shouldUpdate(nextProps) then
					self:willUpdate(nextProps)
				end
				self._props = nextProps
			end
		)
		if Class.mount then
			Class.mount(self)
		end
		if Class.didMount then
			Class.didMount(self)
		end
	end

	function ConnectedClass:shouldUpdate(nextProps)
		if Class.shouldUpdate then
			return Class.shouldUpdate(self, nextProps)
		end
		return not Tables.shallowEqual(self._props, nextProps)
	end

	function ConnectedClass:didMount()
		if Class.didMount then
			Class.didMount(self)
		end
	end

	function ConnectedClass:willUpdate(nextProps)
		if Class.willUpdate then
			Class.willUpdate(self, nextProps)
		end
	end

	function ConnectedClass:destroy()
		if self._connection then
			self._connection:disconnect()
		end
		if Class.destroy then
			Class.destroy(self)
		end
	end

	return ConnectedClass
end

return connectToStore
