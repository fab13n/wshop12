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
	local mqtt_value = value==true and 1 or value==false and 0 or value
	M.mqtt_client :publish (M.conf.mqtt.data_path..name, tostring(value))
	local str_value = string.pack('h', value)
	return assert(M.modbus_client :writeMultipleRegisters (1, address, str_value))
end

M.last_values = { }

--- Regularly runs the MQTT handler for incoming commands
function M.poll_loop()
	sched.wait(2) -- Modbus needs some time to initialize itself
	while true do
		local record = M.read_all()
		for k, v in pairs(record) do
			local last_v = M.last_values[k]
			if v~=last_v then
				log('WSHOP12', 'INFO', "Value change: %s: %s->%s", k, tostring(last_v), tostring(v))
				local mqtt_value = not v and '0' or v==true and '1' or tostring(v)
				M.mqtt_client :publish (M.conf.mqtt.data_path..k, mqtt_value)
				sched.signal(M.last_values, k, last_v, v)
				M.last_values[k]=v
			end
		end
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

--- When the button is released, invert the light's state
function M.on_button_changed(ev, old_val, new_val)
	if not new_val then -- button released
		local is_light_on = M.read 'light'
		M.write('light', not is_light_on)
	end
end
sched.sigrun(M.last_values, 'button', M.on_button_changed)

--- Initializes the module
function M.init()
	if M.initialized then return M end
	M.modbus_client = assert(modbus.new(M.conf.modbus.port, { baudRate = M.conf.modbus.speed }))
	M.mqtt_client   = assert(mqtt.client.create(M.conf.mqtt.host, M.conf.mqtt.port, M.mqtt_callback))
	M.mqtt_client :connect (M.conf.mqtt.id)
	M.mqtt_client :subscribe{ M.conf.mqtt.cmd_path.."#" }
	sched.run(M.poll_loop)

	M.initialized = true
	return M
end

return M