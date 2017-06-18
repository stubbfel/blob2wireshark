-- from http://lua-users.org/wiki/StringRecipes
function b2ws_string_starts(String,Start)
	return string.sub(String,1,string.len(Start))==Start
end

-- from http://lua-users.org/wiki/StringTrim
function b2ws_trim(s)
	if s == nil then
		return  nil
	end

	local from = s:match"^%s*()"
	return from > #s and "" or s:match(".*%S", from)
end

-- from http://lua-users.org/wiki/SplitJoin
function b2ws_string_split(str, pat)
   local t = {}
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
         table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
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
