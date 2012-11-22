local M = { }

local modbus     = require 'modbus'
local log        = require 'log'
local airvantage = require 'airvantage'

M.conf = {
    asset_name = 'arduino',
	modbus = {
		port  = '/dev/ttyACM0',
		speed = 9600 } }

--- Converter between Modbus coil/value, symbolic names and physical values
M.process = require 'processors'

--- Reads all variables, returns them as keys/values in a record
function M.read_all()
	local str_value = assert(M.modbus_client:readHoldingRegisters(1, 0, 9))
	local record = { }
	for name, n in pairs(M.process.NAME2REG) do
		local low, high = str_value :byte (2*n+1, 2*n+2)
		local value = 256*high + low
		local processor = M.process.read[name]
		if processor then value = processor(value) end
		record[name] = value
	end
	return record
end

--- Writes a physical value into a symbolic variable
function M.write(name, value)
	checks('string', '?')
	local address = M.process.NAME2REG[name] or error ("Undefined modbus variable "..name)
	local processor = M.process.write[name]
	if processor then value = processor(value) end	
	local str_value = string.pack('h', value)
	return assert(M.modbus_client :writeMultipleRegisters (1, address, str_value))
end

M.last_values = { }

--- Regularly runs the MQTT handler for incoming commands
function M.poll_loop()
	sched.wait(2) -- Modbus needs some time to initialize itself
	for i=0, math.huge do
		local record = M.read_all()
		if i%10~=0 then record = { button=record.button } end
		for k, v in pairs(record) do
			local last_v = M.last_values[k]
			if v~=last_v then
				log('WSHOP12', 'INFO', "Value change: %s: %s->%s", k, tostring(last_v), tostring(v))
				M.last_values[k]=v
			else record[k]=nil end
		end
		if next(record) then 
			record.timestamp=os.time()
			M.asset :pushdata ('', record, 'now')
		end
		sched.wait(1)
	end
end

--- Reacts to settings sent by m2mop.net by sending them to Arduino
function M.on_m2mop_setting(asset, record)
	for k, v in pairs(record) do assert(M.write(k, v)) end
	return 'ok'
end

--- Initializes the module
function M.init()
	if M.initialized then return M end
	M.modbus_client = assert(modbus.new(M.conf.modbus.port, { baudRate = M.conf.modbus.speed }))
	assert(airvantage.init())

	M.asset = airvantage.newasset(M.conf.asset_name)
	M.asset.tree.__default = M.on_m2mop_setting
	M.asset :start()

	sched.run(M.poll_loop)

	M.initialized = true
	return M
end

return M