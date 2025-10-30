local argparse = require("lib.argparse")
local app = require("src.init")

---removes '.' from arg
table.remove(arg, 1)

local parser = argparse("shadespheare", "live GLSL shader preview")

parser:flag("-v --verbose", "enable verbose output")
parser:flag("-h --help", "shows this help message and exit")

local run_cmd = parser:command("run", "run a shader in a LÖVE2D window")
run_cmd:argument("shader", "path to shader file"):args(1)

local new_cmd = parser:command("new", "create a new shader project")
new_cmd:argument("shader", "path to new shader project")

local watch_cmd = parser:command("watch", "continuously re-run the shader when the file changes")
watch_cmd:argument("shader", "path to shader file"):args(1)
watch_cmd:option("--delay", "shader reload delay", "0.25"):convert(tonumber)

local args = parser:parse()

---handle the cli
if args.new then
	local template = [[
uniform float iTime;
uniform vec4  iMouse;
uniform vec2  iDelta;
uniform vec2  iResolution;

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 sc) {
	vec2 uv = (sc / iResolution) * 2.0 - 1.0;
	vec3 col = vec3(uv.x, sin(iTime), uv.y);
	return vec4(col, 1.0);
}
]]

	local f, err = io.open(args.shader, "w")
	if not f then
		print(("[%s] error creating file: %s"):format(os.date("%H:%M:%S"), err))
		love.event.quit(1)
		return
	end
	f:write(template)
	f:close()

	print(("[%s] 🆕 created shader file: %s"):format(os.date("%H:%M:%S"), args.shader))
elseif args.watch then
	print(("[%s] 👀 watching %s (reload delay %.2fs)"):format(os.date("%H:%M:%S"), args.shader, args.delay))
	app.Initialize(args.shader, true, args.delay)
elseif args.run then
	print(("[%s] 🏃 running %s"):format(os.date("%H:%M:%S"), args.shader))
	app.Initialize(args.shader, false, 0.25)
else
	parser:print_help()

	if not love then
		os.exit(0)
	end
	love.event.quit()
	return
end
