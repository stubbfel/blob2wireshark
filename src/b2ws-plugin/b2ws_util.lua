-- from http://lua-users.org/wiki/StringRecipes
function b2ws_string_starts(String,Start)
	return string.sub(String,1,string.len(Start))==Start
end

-- from http://lua-users.org/wiki/StringTrim
function b2ws_trim(s)
 local from = s:match"^%s*()"
 return from > #s and "" or s:match(".*%S", from)
end

function create_b2ws_folder_file_path(plugin_path, plugin_config_file_name)
	return persconffile_path(plugin_path) .. plugin_config_file_name
end

function write_b2ws_file(file_path, content)
	local config_inp = assert(io.open(file_path, "w"))
	config_inp:write(content)
	assert(config_inp:close())
end

function read_b2ws_file(file_path)
	local config_inp = assert(io.open(file_path, "r"))
	local config_string = config_inp:read("*all")
	assert(config_inp:close())
	return config_string
end

function read_b2ws_folder_file(plugin_path, plugin_config_file_name)
	local path = create_b2ws_folder_file_path(plugin_path, plugin_config_file_name)
	return read_b2ws_file(path)
end

function write_b2ws_folder_file(plugin_path, plugin_config_file_name, settings)
	local path = create_b2ws_folder_file_path(plugin_path, plugin_config_file_name)
	write_b2ws_file(path, settings)
end

function create_b2ws_config_object(config_string)
	if not (b2ws_string_starts(config_string, "return ")) then
		config_string = "return " .. config_string
	end

	local tmp_config_func = assert(loadstring(string.gsub(config_string, "[\n\r]", "")))
	return tmp_config_func()
end
