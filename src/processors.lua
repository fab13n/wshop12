-------------------------------------------------------------------------------
-- Processor routines, to convert Modbus variable numbers into symbolic names,
-- and their byte values into meaningful, physical ones.
-- 

local M = { read = { }, write = { } }

--- Translate symbolic names into Modbus coil numbers
M.NAME2REG = {
	luminosity  = 1,
 	humidity    = 2,
 	temperature = 3,
 	light       = 6,
 	button      = 7 }


function M.read.luminosity(x)
	local y = x * 0.0048828125
	return (50*y) / (5-y)
end

function M.read.humidity(x)
	return math.max(1000-x,0) / 10
	--return x<400 and 0 or (x-300)/.45
end 

function M.read.temperature(x)
	return 1/(math.log((1023-x)/x)/3975 + 1/298.15) - 273.15
end

local function int2bool(x) return x~=0 end

M.read.button, M.read.light = int2bool, int2bool

function M.write.light(x) return x and 1 or 0 end

return M
