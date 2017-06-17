if not gui_enabled() then return end

require "b2ws_const"
local loaded_b2ws_import= assert(loadfile(b2ws_const.B2WS_PLUGIN_PATH .. "b2ws_import.lua"))
loaded_b2ws_import()

local function b2ws_win_import_blob()
	local win = TextWindow.new(b2ws_const.B2WS_IMPORT_BLOB_WIN_TITLE)
	win:set_editable()
	config_file_path = create_b2ws_config_file_path(b2ws_const.B2WS_PLUGIN_PATH, b2ws_const.B2WS_PLUGIN_CONFIG_FILE_NAME)
	win:set(read_b2ws_file(config_file_path))

	local function b2ws_win_btn_import_blob()
		-- load config from text field
		local win_text = win:get_text();

		-- import to and show in pcap file
		output_path = b2ws_import_blob(win_text)
		open_capture_file(output_path, "")
	end

	local function b2ws_win_btn_save_settings()
		-- load config from text field
		local win_text = b2ws_trim(win:get_text())
		write_b2ws_file(config_file_path, win_text)
	end

	local function b2ws_win_btn_change_settings()
		local function b2ws_win_change_settings(blob_src, eth_src, eth_dst, eth_type)
			local win_text = b2ws_trim(win:get_text())
			win:set(b2ws_change_settings(win_text, blob_src, eth_src, eth_dst, eth_type))
		end

		new_dialog(b2ws_const.B2WS_CHANGE_SETTINGS_DLG_TITLE,
		 b2ws_win_change_settings,
		 b2ws_const.B2WS_CONFIG_LABEL_BLOB_SRC,
		 b2ws_const.B2WS_CONFIG_LABEL_ETH_FAKE_HEADER_SRC,
		 b2ws_const.B2WS_CONFIG_LABEL_ETH_FAKE_HEADER_DST,
		 b2ws_const.B2WS_CONFIG_LABEL_ETH_FAKE_HEADER_TYPE)
	end

   win:add_button(b2ws_const.B2WS_IMPORT_BLOB_BTN_TITLE, b2ws_win_btn_import_blob)
   win:add_button(b2ws_const.B2WS_SAVE_SETTINGS_BTN_TITLE, b2ws_win_btn_save_settings)
   win:add_button(b2ws_const.B2WS_CHANGE_SETTINGS_BTN_TITLE, b2ws_win_btn_change_settings)
end

register_menu(b2ws_const.B2WS_IMPORT_BLOB_MENU_TITLE, b2ws_win_import_blob, MENU_TOOLS_UNSORTED)
