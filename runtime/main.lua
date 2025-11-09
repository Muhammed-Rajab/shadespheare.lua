local shader = "" -- default
local config_path = "" -- default
local watch = false
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
	elseif a == "--no-fps" then
		show_fps = false
	end
end

require("runtime.src.init")(shader, watch, delay, config_path)
