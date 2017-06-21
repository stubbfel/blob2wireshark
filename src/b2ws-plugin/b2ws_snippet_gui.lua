if not gui_enabled() then return end

require "b2ws_const"
local loaded_b2ws_snippet = assert(loadfile(b2ws_const.B2WS_PLUGIN_PATH .. b2ws_const.B2WS_CREATE_SNIPPET_FILE))
loaded_b2ws_snippet()

local function b2ws_win_snippet_blob()
	local win = TextWindow.new(b2ws_const.B2WS_CREATE_SNIPPET_WIN_TITLE)
	win:set_editable()

	local function b2ws_btn_create_snippet_dissector()
		local win_text = b2ws_trim(win:get_text())
		local structObject = b2ws_parse_struct(win_text)
        local result_template = b2ws_create_dissector_snippet(structObject)
		local info = TextWindow.new(b2ws_const.B2WS_SHOW_SNIPPET_WIN_TITLE)
		info:set(result_template)
	end

   win:add_button(b2ws_const.B2WS_CREATE_DISSECTOR_SNIPPET_BTN_TITLE, b2ws_btn_create_snippet_dissector)
end

register_menu(b2ws_const.B2WS_CREATE_SNIPPET_MENU_TITLE, b2ws_win_snippet_blob, MENU_TOOLS_UNSORTED)
