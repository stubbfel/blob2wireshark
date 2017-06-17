
local PLUGIN_PATH = "plugins/b2ws-plugin/"
local PLUGIN_CONFIG_FILE_NAME = "b2ws.config"

-- from http://lua-users.org/wiki/StringRecipes
local function string_starts(String,Start)
	return string.sub(String,1,string.len(Start))==Start
end

-- from http://lua-users.org/wiki/StringTrim
function b2ws_trim(s)
 local from = s:match"^%s*()"
 return from > #s and "" or s:match(".*%S", from)
end

local function create_b2ws_config_file_path(plugin_path, plugin_config_file_name)
	return persconffile_path(plugin_path) .. plugin_config_file_name
end

local function write_b2ws_file(file_path, content)
	local config_inp = assert(io.open(file_path, "w"))
	config_inp:write(content)
	assert(config_inp:close())
end

local function read_b2ws_file(file_path)
	local config_inp = assert(io.open(file_path, "r"))
	local config_string = config_inp:read("*all")
	assert(config_inp:close())
	return config_string
end

local function read_b2ws_config_file(plugin_path, plugin_config_file_name)
	local path = create_b2ws_config_file_path(plugin_path, plugin_config_file_name)
	return read_b2ws_file(path)
end

local function write_b2ws_config_file(plugin_path, plugin_config_file_name, settings)
	local path = create_b2ws_config_file_path(plugin_path, plugin_config_file_name)
	write_b2ws_file(path, settings)
end

local function b2ws_import_blob(config_string)

	local tmp_config_func = assert(loadstring(string.gsub(config_string, "[\n\r]", "")))
	b2ws_config = tmp_config_func()

	-- read blob file
	local bytes = read_b2ws_file(b2ws_config.blob_src)

	-- convert to hex string
	local data = {}
	bytes:gsub(".", function(c)	table.insert(data,string.format("%02X ", string.byte(c))) end)
	local data_string = table.concat(data)

	-- create fake ethernet frame
	local header = PseudoHeader.eth()
	local eth_fake_header = b2ws_config.eth_fake_header_src .. b2ws_config.eth_fake_header_dst .. b2ws_config.eth_fake_header_type
	local eth_fake_frame = eth_fake_header .. data_string
	local pcapPath = b2ws_config.blob_src .. ".pcap"

	-- write fake frame to pcap file
	local dmp = Dumper.new(pcapPath)
	dmp:dump(os.time(),header, ByteArray.new(eth_fake_frame))
	dmp:flush()
	dmp:close()
	return pcapPath
end

if (gui_enabled()) then
	-- gui part
	local IMPORT_BLOB_MENU_TITLE = "b2ws/Import Blob"
	local IMPORT_BLOB_BTN_TITLE = "Import Blob"
	local SAVE_SETTINGS_BTN_TITLE = "Save current settings"
	local IMPORT_BLOB_WIN_TITLE = "Import Blob"

	local function b2ws_win_import_blob()
		local win = TextWindow.new(IMPORT_BLOB_WIN_TITLE)
		win:set_editable()
		win:set(read_b2ws_config_file(PLUGIN_PATH, PLUGIN_CONFIG_FILE_NAME))

		local function b2ws_win_btn_import_blob()

			-- load config from text field
			local win_text = win:get_text();
			if not (string_starts(win_text, "return ")) then
				win_text = "return " .. win_text
			end

			-- import to and show in pcap file
			output_path = b2ws_import_blob(win_text)
			open_capture_file(output_path, "")
		end

		local function b2ws_win_btn_save_settings()
			-- load config from text field
			local win_text = b2ws_trim(win:get_text());
			write_b2ws_config_file(PLUGIN_PATH, PLUGIN_CONFIG_FILE_NAME, win_text)
		end

	   win:add_button(IMPORT_BLOB_BTN_TITLE, b2ws_win_btn_import_blob)
	   win:add_button(SAVE_SETTINGS_BTN_TITLE, b2ws_win_btn_save_settings)
	end

	register_menu(IMPORT_BLOB_MENU_TITLE, b2ws_win_import_blob, MENU_TOOLS_UNSORTED)
end
