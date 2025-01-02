-- this is executed when the user invokes it through gesturing
local function foo()
	mp.osd_message("Hello World!", 2)
end

-- this is called immediately upon opening a file
local function init()
	    mp.msg.info("Sleep timer script initialized")
	    mp.osd_message("Sleep timer script initialized!", 3)
end

mp.add_key_binding(nil, "sleep", foo)
init()
