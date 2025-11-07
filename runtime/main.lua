local shader = nil
local watch = false
local delay = 0.25
local show_fps = false

---removes "runtime" from `love runtime`
table.remove(arg, 1)

for i = 1, #arg do
	local a = arg[i]

	-- First non-flag argument is shader file
	if not shader and not a:match("^%-") then
		shader = a
	elseif a == "--watch" then
		watch = true
	elseif a:match("^%-%-delay=") then
		delay = tonumber(a:match("^%-%-delay=(.*)")) or delay
	elseif a == "--show-fps" then
		show_fps = true
	end
end

shader = shader or "ray-marching.glsl" -- fallback

---WARN: turn on when development
-- print("LOADED SHADER:", shader, "WATCH:", watch, "DELAY:", delay, "FPS:", show_fps)

require("runtime.src.init")(shader, watch, delay, show_fps)
