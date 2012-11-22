local sched = require 'sched'
local telnet = require 'shell.telnet'

local function main ()
	telnet.init{ editmode='edit', address='*', port=2323, historysize=256 }
	print("Application started, connect a telnet to port 2323")
end

sched.run(main)
sched.loop()
