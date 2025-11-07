local argparse = require("lib.argparse")
local app = require("src.init")

local function quit()
	if not love then
		os.exit(0)
	end
	love.event.quit()
end

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
uniform vec3  iResolution;

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 sc) {

  // color place holder to pass into mainImage
  vec4 col = vec4(0, 0, 0, 1);

  // now it is shadertoy compatible, lol
  mainImage(col, sc.xy);

	return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {

	vec2 uv = (fragCoord / iResolution.xy) * 2.0 - 1.0;

  fragColor = vec4(uv, 0.0, 1.0);
}
]]

	---make sure file doesn't exist
	local _f = io.open(args.shader, "r")
	if _f then
		_f:close()
		print(("[%s] ⚠️ file already exists: %s"):format(os.date("%H:%M:%S"), args.shader))
		love.event.quit(1)
		return
	end

	local f, err = io.open(args.shader, "w")
	if not f then
		print(("[%s] error creating file: %s"):format(os.date("%H:%M:%S"), err))
		love.event.quit(1)
		return
	end
	f:write(template)
	f:close()

	print(("[%s] 🆕 created shader file: %s"):format(os.date("%H:%M:%S"), args.shader))
	quit()
elseif args.watch then
	print(("[%s] 👀 watching %s (reload delay %.2fs)"):format(os.date("%H:%M:%S"), args.shader, args.delay))
	app.initialize(args.shader, true, args.delay, false)
elseif args.run then
	print(("[%s] 🏃 running %s"):format(os.date("%H:%M:%S"), args.shader))
	app.initialize(args.shader, false, 0.25, false)
else
	parser:print_help()
	quit()
end
