local M = { }

local modbus = require 'modbus'
local log    = require 'log'

M.conf = {
	modbus = {
		port  = '/dev/ttyACM0',
		speed = 9600 } }

--- Converter between Modbus coil/value, symbolic names and physical values
M.process = require 'processors'

--- Reads a physical value from a symbolic variable
function M.read(name)
	checks('string')
	local address = M.process.NAME2REG[name] or error ("Undefined modbus variable "..name)
	local str_value = assert(M.modbus_client:readHoldingRegisters(1, address, 1))
	local low, high = str_value :byte (1, 2)
	local value = 256*high + low
	local processor = M.process.read[name]
	if processor then value = processor(value) end
	return value
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

--- Initializes the module
function M.init()
	if M.initialized then return M end
	M.modbus_client = assert(modbus.new(M.conf.modbus.port, { baudRate = M.conf.modbus.speed }))
	M.initialized = true
	return M
end

return M