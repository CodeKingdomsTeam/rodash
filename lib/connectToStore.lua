local tea = require(script.Parent.Parent.tea)
local TableUtils = require(script.Parent.TableUtils)

local function connectToStore(Class, mapStateToFields)
	local ConnectedClass =
		Class:extendWithInterface(
		"Connected(" .. Class.name .. ")",
		{
			store = tea.interface(
				{
					changed = tea.Signal
				}
			)
		}
	)

	function ConnectedClass:listen()
		self._connection =
			self._store.changed:connect(
			function(state)
				local nextFields = mapStateToFields(state)
				if self:shouldUpdate(nextFields) then
					self:willUpdate(nextFields)
				end
				self._fields = nextFields
				TableUtils.assign(self, nextFields)
			end
		)
		if Class.listen then
			Class.listen(self)
		end
		local nextFields = mapStateToFields(self._store:getState())
		self._fields = nextFields
		TableUtils.assign(self, nextFields)
		if Class.didMount then
			Class.didMount(self)
		end
	end

	function ConnectedClass:shouldUpdate(nextFields)
		if Class.shouldUpdate then
			return Class.shouldUpdate(self, nextFields)
		end
		return not TableUtils.shallowEqual(self._fields, nextFields)
	end

	function ConnectedClass:didMount()
		if Class.didMount then
			Class.didMount(self)
		end
	end

	function ConnectedClass:willUpdate(nextFields)
		if Class.willUpdate then
			Class.willUpdate(self, nextFields)
		end
	end

	function ConnectedClass:destroy()
		self._connection:disconnect()
		if Class.destroy then
			Class.destroy(self)
		end
	end

	return ConnectedClass
end

return connectToStore
