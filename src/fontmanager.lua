local FontManager = {
	fonts = {},
	standard_sizes = { 12, 16, 20, 28, 32, 48, 64 },
}

function FontManager:load(name, path)
	if not self.fonts[name] then
		local font = {
			path = path,
			sizes = {},
		}
		for _, size in ipairs(self.standard_sizes) do
			font.sizes[size] = love.graphics.newFont(path, size)
		end
		self.fonts[name] = font
	end
end

function FontManager:get(name, size)
	local font = self.fonts[name]
	if not font then
		error("font not loaded: " .. name)
	end

	-- if size isn't available, get create new
	if not font.sizes[size] then
		io.write("non standard size " .. size .. "px for " .. name .. " detected!\n")
		font.sizes[size] = love.graphics.newFont(font.path, size)
	end

	return font.sizes[size]
end

function FontManager:set(name, size)
	love.graphics.setFont(self:get(name, size))
end

return FontManager
