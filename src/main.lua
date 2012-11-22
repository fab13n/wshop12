local sched = require 'sched'
local telnet = require 'shell.telnet'

function watch(em,ev)
	sched.sighook (em, ev or '*', function(ev, ...)
		printf("Signal: %s.%s(%s)", tostring(em), ev, sprint{...} :gsub (2, -2))
	end)
end 

local function main ()
	log.displaylogger = print
	log.setlevel('INFO')
	telnet.init{ editmode='edit', address='*', port=2323, historysize=256 }
end

sched.run(main)
sched.loop()
