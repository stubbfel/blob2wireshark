require "b2ws_const"
local loaded_b2ws_util= assert(loadfile(b2ws_const.B2WS_PLUGIN_PATH .. b2ws_const.B2WS_UTIL_FILE))
loaded_b2ws_util()

function b2ws_import_blob(config_string)
	-- create config object
	local b2ws_config = create_b2ws_config_object(config_string)

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

function b2ws_change_settings(config_string, blob_src, eth_src, eth_dst, eth_type)
	local b2ws_config = create_b2ws_config_object(config_string)
	if not (blob_src == "") then
		b2ws_config.blob_src = blob_src
	end

	if not (eth_src == "") then
		b2ws_config.eth_fake_header_src = eth_src
	end

	if not (eth_dst == "") then
		b2ws_config.eth_fake_header_dst = eth_dst
	end

	if not (eth_type == "") then
		b2ws_config.eth_fake_header_type = eth_type
	end

	local new_config_string = "{\n\t[\"blob_src\"] = \"" .. b2ws_config.blob_src .. "\",\n"
 	new_config_string = new_config_string .. "\t[\"eth_fake_header_src\"] = \"" .. b2ws_config.eth_fake_header_src .. "\",\n"
 	new_config_string = new_config_string .. "\t[\"eth_fake_header_dst\"] = \"" .. b2ws_config.eth_fake_header_dst .. "\",\n"
 	new_config_string = new_config_string .. "\t[\"eth_fake_header_type\"] = \"" .. b2ws_config.eth_fake_header_type .. "\"\n}"
	return new_config_string
end

function b2ws_create_dissector(config_string)
	local b2ws_config = create_b2ws_config_object(config_string)
	local template_string = read_b2ws_folder_file(b2ws_const.B2WS_PLUGIN_PATH, b2ws_const.B2WS_DISSECTOR_TEMPLATE_FILE)
	template_string = template_string:gsub("0xffff", "0x" .. b2ws_config.eth_fake_header_type)
	local dissector_path  = b2ws_config.blob_src .. b2ws_const.B2WS_DISSECTOR_EXTENSION
	write_b2ws_file(dissector_path, template_string)
	return dissector_path
end
