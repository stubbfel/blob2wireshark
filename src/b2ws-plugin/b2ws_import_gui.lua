if not gui_enabled() then return end

require "b2ws_const"
local loaded_b2ws_import= assert(loadfile(b2ws_const.B2WS_PLUGIN_PATH .. b2ws_const.B2WS_IMPORT_BLOB_FILE))
loaded_b2ws_import()

local function b2ws_win_import_blob()
	local win = TextWindow.new(b2ws_const.B2WS_IMPORT_BLOB_WIN_TITLE)
	win:set_editable()
	config_file_path = create_b2ws_folder_file_path(b2ws_const.B2WS_PLUGIN_PATH, b2ws_const.B2WS_PLUGIN_CONFIG_FILE_NAME)
	win:set(read_b2ws_file(config_file_path))

	local function b2ws_win_btn_import_blob()
		-- load config from text field
		local win_text = win:get_text();

		-- import to and show in pcap file
		output_path = b2ws_import_blob(win_text)
		open_capture_file(output_path, "")
		reload()
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

	local function b2ws_dlg_btn_create_dissector(dissector_name)
		if dissector_name == "" then
			return
		end

		local win_text = b2ws_trim(win:get_text())
		local dissector_path = b2ws_create_dissector(win_text, dissector_name)
		local info = TextWindow.new(b2ws_const.B2WS_RELOAD_PLUGIN_WIN_TITLE)
		info:set(b2ws_const.B2WS_RELOAD_PLUGIN_WIN_CONTENT:gsub("{0}", dissector_path))
		local function b2ws_win_btn_show_disector()
			local dis_win = TextWindow.new(b2ws_const.B2WS_SHOW_DISSECTOR_WIN_TITLE)
			dis_win:set_editable()
			dis_win:set(read_b2ws_file(dissector_path))
			local function b2ws_win_btn_save_disector()
				local dis_win_text = b2ws_trim(dis_win:get_text())
				write_b2ws_file(dissector_path, dis_win_text)
			end

			dis_win:add_button(b2ws_const.B2WS_SAVE_DISSECTOR_BTN_TITLE, b2ws_win_btn_save_disector)
		end
		info:add_button(b2ws_const.B2WS_SHOW_DISSECTOR_BTN_TITLE, b2ws_win_btn_show_disector)
	end

	local function b2ws_win_btn_create_dissector()
		new_dialog(b2ws_const.B2WS_CREATE_DISSECTOR_DLG_TITLE,
		 b2ws_dlg_btn_create_dissector,
		 b2ws_const.B2WS_CREATE_DISSECTOR_DLG_NAME_LABEL)
	end

   win:add_button(b2ws_const.B2WS_IMPORT_BLOB_BTN_TITLE, b2ws_win_btn_import_blob)
   win:add_button(b2ws_const.B2WS_SAVE_SETTINGS_BTN_TITLE, b2ws_win_btn_save_settings)
   win:add_button(b2ws_const.B2WS_CHANGE_SETTINGS_BTN_TITLE, b2ws_win_btn_change_settings)
   win:add_button(b2ws_const.B2WS_CREATE_DISSECTOR_BTN_TITLE, b2ws_win_btn_create_dissector)
end

register_menu(b2ws_const.B2WS_IMPORT_BLOB_MENU_TITLE, b2ws_win_import_blob, MENU_TOOLS_UNSORTED)
