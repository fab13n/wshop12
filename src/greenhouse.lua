local M = { }

local modbus = require 'modbus'
local log    = require 'log'
local mqtt   = require 'mqtt_library'

M.conf = {
	modbus = {
		port  = '/dev/ttyACM0',
		speed = 9600 },
	mqtt = {
		id        = 'MODBUS_APP',
		port      = 1883,
		host      = 'm2m.eclipse.org',
		data_path = '/eclipsecon/demo-mihini/data/',
		cmd_path  = '/eclipsecon/demo-mihini/command/' } }

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
	local mqtt_value = value==true and 1 or value==false and 0 or value
	M.mqtt_client :publish (M.conf.mqtt.data_path..name, mqtt_value)
	return value
end

--- Writes a physical value into a symbolic variable
function M.write(name, value)
	checks('string', '?')
	local address = M.process.NAME2REG[name] or error ("Undefined modbus variable "..name)
	local processor = M.process.write[name]
	if processor then value = processor(value) end	
	local mqtt_value = value==true and 1 or value==false and 0 or value
	M.mqtt_client :publish (M.conf.mqtt.data_path..name, tostring(value))
	local str_value = string.pack('h', value)
	return assert(M.modbus_client :writeMultipleRegisters (1, address, str_value))
end

--- Regularly runs the MQTT handler for incoming commands
function M.mqtt_poll_loop()
	while true do
		M.mqtt_client :handler()
		sched.wait(1)
	end
end

--- Reacts to MQTT incoming commands
function M.mqtt_callback(topic, value)
	log('WSHOP12', 'INFO', "Incoming MQTT command %s=%s", tostring(topic), tostring(value))
	local var_name = topic :match "[^/]+$"
	M.write(var_name, value=='1')
end

--- Initializes the module
function M.init()
	if M.initialized then return M end
	M.modbus_client = assert(modbus.new(M.conf.modbus.port, { baudRate = M.conf.modbus.speed }))
	M.mqtt_client   = assert(mqtt.client.create(M.conf.mqtt.host, M.conf.mqtt.port, M.mqtt_callback))
	M.mqtt_client :connect (M.conf.mqtt.id)
	M.mqtt_client :subscribe{ M.conf.mqtt.cmd_path.."#" }
	sched.run(M.mqtt_poll_loop)

	M.initialized = true
	return M
end

return M