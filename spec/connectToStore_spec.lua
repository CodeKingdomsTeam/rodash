local connectToStore = require "connectToStore"
local ClassUtils = require "ClassUtils"
local tea = require "tea"

local function getStoreStub(initialState)
	local state = initialState
	local callback
	return {
		getState = function()
			return state
		end,
		changed = {
			connect = function(connection, handler)
				callback = handler
				return {
					disconnect = function()
						callback = nil
					end
				}
			end
		},
		setState = function(newState)
			state = newState
			if callback then
				callback(newState)
			end
		end
	}
end

describe(
	"connectToStore",
	function()
		it(
			"maps fields and calls didMount",
			function()
				local MyClass =
					ClassUtils.makeClassWithInterface(
					"Simple",
					{
						amount = tea.number
					}
				)
				MyClass.didMount =
					spy.new(
					function()
					end
				)
				local MyConnectedClass =
					connectToStore(
					MyClass,
					function(state)
						return {_field = state.field}
					end
				)
				local store =
					getStoreStub(
					{
						field = 5
					}
				)
				local myInstance =
					MyConnectedClass.new(
					{
						store = store,
						amount = 10
					}
				)
				myInstance:mount()
				assert.spy(MyClass.didMount).was_called()
				assert.equals(5, myInstance._field)
			end
		)
		it(
			"complains about invalid fields",
			function()
				local MyClass =
					ClassUtils.makeClassWithInterface(
					"Simple",
					{
						amount = tea.number
					}
				)
				local MyConnectedClass = connectToStore(MyClass)
				assert.errors(
					function()
						MyConnectedClass.new(
							{
								amount = 10
							}
						)
					end,
					[[Class Connected(Simple) cannot be instantiated
[interface] bad value for store:
	table expected, got nil]]
				)
				assert.errors(
					function()
						MyConnectedClass.new(
							{
								store = getStoreStub(),
								amount = "what"
							}
						)
					end,
					[[Class Connected(Simple) cannot be instantiated
[interface] bad value for amount:
	number expected, got string]]
				)
			end
		)
		it(
			"calls willUpdate during state change",
			function()
				local MyClass =
					ClassUtils.makeClassWithInterface(
					"Simple",
					{
						amount = tea.number
					}
				)
				MyClass.willUpdate =
					spy.new(
					function()
					end
				)
				local MyConnectedClass =
					connectToStore(
					MyClass,
					function(state)
						return {_field = state.field}
					end
				)
				local store =
					getStoreStub(
					{
						field = 5
					}
				)
				local myInstance =
					MyConnectedClass.new(
					{
						store = store,
						amount = 10
					}
				)
				myInstance:mount()
				assert.spy(MyClass.willUpdate).was_not_called()
				store.setState(
					{
						field = 6
					}
				)
				assert.spy(MyClass.willUpdate).was_called()
				assert.equals(5, MyClass.willUpdate.calls[1].vals[1]._field)
				assert.equals(6, MyClass.willUpdate.calls[1].vals[2]._field)
				assert.equals(6, myInstance._field)
			end
		)
		it(
			"does not call willUpdate if state is shallow equal",
			function()
				local MyClass =
					ClassUtils.makeClassWithInterface(
					"Simple",
					{
						amount = tea.number
					}
				)
				MyClass.willUpdate =
					spy.new(
					function()
					end
				)
				local MyConnectedClass =
					connectToStore(
					MyClass,
					function(state)
						return {_field = state.field}
					end
				)
				local store =
					getStoreStub(
					{
						field = 5
					}
				)
				local myInstance =
					MyConnectedClass.new(
					{
						store = store,
						amount = 10
					}
				)
				myInstance:mount()
				assert.spy(MyClass.willUpdate).was_not_called()
				store.setState(
					{
						field = 5
					}
				)
				assert.spy(MyClass.willUpdate).was_not_called()
				store.setState(
					{
						field = 6
					}
				)
				assert.spy(MyClass.willUpdate).was_called()
			end
		)
		it(
			"does not call willUpdate if shouldUpdate returns false, but ensures fields are consistent",
			function()
				local MyClass =
					ClassUtils.makeClassWithInterface(
					"Simple",
					{
						amount = tea.number
					}
				)
				MyClass.willUpdate =
					spy.new(
					function()
					end
				)
				MyClass.shouldUpdate =
					spy.new(
					function()
						return false
					end
				)
				local MyConnectedClass =
					connectToStore(
					MyClass,
					function(state)
						return {_field = state.field}
					end
				)
				local store =
					getStoreStub(
					{
						field = 5
					}
				)
				local myInstance =
					MyConnectedClass.new(
					{
						store = store,
						amount = 10
					}
				)
				myInstance:mount()
				assert.spy(MyClass.willUpdate).was_not_called()
				assert.spy(MyClass.shouldUpdate).was_not_called()
				store.setState(
					{
						field = 12
					}
				)
				assert.spy(MyClass.willUpdate).was_not_called()
				assert.spy(MyClass.shouldUpdate).was_called()
				assert.equals(12, myInstance._field)
			end
		)
		it(
			"does not update fields after instance is destroyed",
			function()
				local MyClass =
					ClassUtils.makeClassWithInterface(
					"Simple",
					{
						amount = tea.number
					}
				)
				MyClass.willUpdate =
					spy.new(
					function()
					end
				)
				MyClass.shouldUpdate =
					spy.new(
					function()
						return true
					end
				)
				MyClass.destroy =
					spy.new(
					function()
					end
				)
				local MyConnectedClass =
					connectToStore(
					MyClass,
					function(state)
						return {_field = state.field}
					end
				)
				local store =
					getStoreStub(
					{
						field = 5
					}
				)
				local myInstance =
					MyConnectedClass.new(
					{
						store = store,
						amount = 10
					}
				)
				myInstance:mount()
				assert.spy(MyClass.willUpdate).was_not_called()
				assert.spy(MyClass.shouldUpdate).was_not_called()
				myInstance:destroy()
				assert.spy(MyClass.destroy).was_called()
				store.setState(
					{
						field = 12
					}
				)
				assert.spy(MyClass.willUpdate).was_not_called()
				assert.spy(MyClass.shouldUpdate).was_not_called()
				assert.equals(5, myInstance._field)
			end
		)
	end
)
