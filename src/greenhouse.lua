local M = { }

local modbus = require 'modbus'
local log    = require 'log'

M.conf = {
	modbus = {
		port  = '/dev/ttyACM0',
		speed = 9600 } }

--- Reads a Modbus coil value, return it as a binary string
function M.read(address)
	checks('number')
	return assert(M.modbus_client:readHoldingRegisters(1, address, 1))
end

--- Writes a binary string in a coil
function M.write(address, value)
	checks('number', 'string')
	return assert(M.modbus_client :writeMultipleRegisters (1, address, value))
end

--- Initializes the module
function M.init()
	if M.initialized then return M end
	M.modbus_client = assert(modbus.new(M.conf.modbus.port, { baudRate = M.conf.modbus.speed }))
	M.initialized = true
	return M
end

return M