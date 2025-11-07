local argparse = require("lib.argparse")

local function quit()
	if not love then
		os.exit(0)
	end
	love.event.quit()
end

---WARN: rewrite needs this to be removed
---removes '.' from arg
-- table.remove(arg, 1)

local parser = argparse("shadespheare", "live GLSL shader preview")

parser:flag("-v --verbose", "enable verbose output")

local run_cmd = parser:command("run", "run a shader in a LÖVE2D window")
run_cmd:argument("shader", "path to shader file"):args(1)

local new_cmd = parser:command("new", "create a new shader project")
new_cmd:argument("shader", "path to new shader project")

local watch_cmd = parser:command("watch", "continuously re-run the shader when the file changes")
watch_cmd:argument("shader", "path to shader file"):args(1)
watch_cmd:option("--delay", "shader reload delay", "0.25"):convert(tonumber)

local args = parser:parse()

local function handle_new()
	local template = [[
void mainImage(out vec4 fragColor, in vec2 fragCoord);

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 sc) {

  // color place holder to pass into mainImage
  vec4 col = vec4(0, 0, 0, 1);

  // now it is shadertoy compatible, lol
  mainImage(col, sc.xy);

	return col;
}

/**********-------------------------------
* YOUR CODE STARTS HERE
*------------------------------**********/
uniform float iTime;
uniform vec4  iMouse;
uniform vec2  iDelta;
uniform vec3  iResolution;

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
end

local function handle_run()
	print(("[%s] 🏃 running %s"):format(os.date("%H:%M:%S"), args.shader))
	os.execute(string.format('love "%s" "%s"', "runtime", args.shader))
end

local function handle_watch()
	print(("[%s] 👀 watching %s (reload delay %.2fs)"):format(os.date("%H:%M:%S"), args.shader, args.delay))
	os.execute(string.format('love "%s" "%s" --watch --delay=%s', "runtime", args.shader, args.delay))
end

---handle the cli
if args.new then
	handle_new()
elseif args.watch then
	handle_watch()
elseif args.run then
	handle_run()
else
	parser:print_help()
	quit()
end
