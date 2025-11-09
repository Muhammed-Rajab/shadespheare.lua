local shader = "default/shader.glsl" -- defaultmain
local config_path = "default/shader.lua" -- default
local watch = true
local delay = 0.25

---removes "runtime" from `love runtime`
table.remove(arg, 1)

for i = 1, #arg do
	local a = arg[i]

	if a:match("^%-%-shader=") then
		shader = a:match("^%-%-shader=(.*)")
	elseif a:match("^%-%-config=") then
		config_path = a:match("^%-%-config=(.*)")
	elseif a == "--watch" then
		watch = true
	elseif a:match("^%-%-delay=") then
		delay = tonumber(a:match("^%-%-delay=(.*)")) or delay
	end
end

require("runtime.src.init")(shader, watch, delay, config_path)
