local argparse = require("lib.argparse")

local function quit()
	if not love then
		os.exit(0)
	end
	love.event.quit()
end

local function abspath(path)
	-- normalize slashes
	path = path:gsub("\\", "/")

	-- if it's already absolute, just return it
	if path:sub(1, 1) == "/" then
		return path
	end

	-- get working directory
	local cwd = io.popen("pwd"):read("*l")
	return cwd .. "/" .. path
end

---WARN: rewrite needs this to be removed
---removes '.' from arg
-- table.remove(arg, 1)

local parser = argparse("shadespheare", "live GLSL shader preview")

parser:flag("-v --verbose", "enable verbose output")

local run_cmd = parser:command("run", "run a shader in a LÖVE2D window")
run_cmd:argument("shader", "path to shader file"):args(1)
run_cmd:option("--config", "path to shader config file"):args(1):count(1)

local new_cmd = parser:command("new", "create a new shader project")
new_cmd:argument("shader", "path to new shader project")

local watch_cmd = parser:command("watch", "continuously re-run the shader when the file changes")
watch_cmd:argument("shader", "path to shader file"):args(1)
watch_cmd:option("--delay", "shader reload delay", "0.25"):convert(tonumber)
watch_cmd:option("--config", "path to shader config file"):args(1):count(1)

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
		quit()
		return
	end

	local f, err = io.open(args.shader, "w")
	if not f then
		print(("[%s] error creating file: %s"):format(os.date("%H:%M:%S"), err))
		return
	end
	f:write(template)
	f:close()

	print(("[%s] 🆕 created shader file: %s"):format(os.date("%H:%M:%S"), args.shader))
	quit()
end

local function handle_run()
	print(("[%s] 🏃 running %s"):format(os.date("%H:%M:%S"), args.shader))
	local shader_abs_path = abspath(args.shader)
	local config_abs_path = abspath(args.config)
	os.execute(string.format('love "%s" --shader="%s" --config="%s"', "runtime", shader_abs_path, config_abs_path))
end

local function handle_watch()
	print(("[%s] 👀 watching %s (reload delay %.2fs)"):format(os.date("%H:%M:%S"), args.shader, args.delay))
	local shader_abs_path = abspath(args.shader)
	local config_abs_path = abspath(args.config)
	os.execute(
		string.format(
			'love "%s" --shader="%s" --watch --delay=%s --config="%s"',
			"runtime",
			shader_abs_path,
			args.delay,
			config_abs_path
		)
	)
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
