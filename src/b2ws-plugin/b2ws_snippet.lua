require "b2ws_const"
local loaded_b2ws_util= assert(loadfile(b2ws_const.B2WS_PLUGIN_PATH .. b2ws_const.B2WS_UTIL_FILE))
loaded_b2ws_util()

function b2ws_create_field_object(name, type, type_suffix)
	local trim_type = b2ws_trim(type)
	local trim_type_suffix = b2ws_trim(type_suffix)
	local ws_type_name = b2ws_trim(string.match(trim_type, "(%w+)"))
	local size_string = b2ws_trim(string.match(ws_type_name, "(%d+)"))
	local bit_size = tonumber(size_string)
	local array_number = b2ws_trim(string.match(trim_type_suffix, "%[(.*)%]"))
	local bit_mask = nil
	if array_number ~= nil then
		if array_number == "" then
			bit_size = 0
		else
			local array_number_value = tonumber(array_number)
			if array_number_value ~= nil then
				bit_size = bit_size * array_number_value
		  	end
		end
	else
		local bit_start, bit_end = string.match(trim_type_suffix, ":(%d+)-(%d+)")
		if bit_start ~= nil and bit_end ~= nil then
			local bit_start_value = tonumber(bit_start)
			local bit_end_value = tonumber(bit_end)
			if bit_start ~= nil and bit_end ~= nil then
				bit_size = bit_end_value - bit_start_value + 1
				bit_mask = 0
				for i = bit_start_value,bit_end_value do
					bit_mask = bit_mask + 2^i
				end
			end
		end
	end
	return {["name"] = b2ws_trim(name), ["type"] = ws_type_name, ["bit_size"] = bit_size, ["bit_mask"] = bit_mask, ["array_number"] = array_number}
end

function b2ws_create_struct_object(name)
	return {["name"] = b2ws_trim(name), ["size"] = -1, ["fields"] = {}}
end

function b2ws_parse_struct(struct_string)
	local struct_name, field_list = string.match(b2ws_trim(struct_string), "struct%s+(%g+)%s*{(.*)}")
	struct_object = b2ws_create_struct_object(struct_name)
	local tmp_bit_size = 0
	for key_index, field_string in next, b2ws_string_split(field_list, ";")
	do
		local trim_filed_string = b2ws_trim(field_string)
		if trim_filed_string ~= "" then
			local type_name, field_name, type_suffix = string.match(trim_filed_string, "(%g+)%s+([%w_]+)(%g*)")
			if type_suffix == nil then
				type_suffix = ""
			end

			local tmp_field_object = b2ws_create_field_object(field_name, type_name, type_suffix)
			struct_object.fields[key_index] = tmp_field_object
			tmp_bit_size = tmp_bit_size + tmp_field_object.bit_size
		end
	end

	if tmp_bit_size % 8 ~= 0 then
		tmp_bit_size = tmp_bit_size + 8
	end

	struct_object.size = tmp_bit_size / 8
	return struct_object
end

next_proto_template = [[-- {field_name} Layer
{field_name}_layer = Proto("{field_name}_layer", "{field_name} layer")

function {field_name}_layer.dissector(buffer, packet_info, tree)
	{field_name}_layer_tree = tree:add({field_name}_layer, buffer(0, buffer:len()))
end
]]

next_proto_dissector_call = [[Dissector.get("{field_name}_layer"):call(buffer({struct_size}, buffer:len() - {struct_size}):tvb(), packet_info, {struct_name}_layer_tree)]]

proto_template = [[-- {struct_name} Layer
{struct_name}_layer = Proto("{struct_name}_layer", "{struct_name} layer")

local {struct_name}_layer_fields = {struct_name}_layer.fields
{field_declarations}
function {struct_name}_layer.dissector(buffer, packet_info, tree)
	{struct_name}_layer_tree = tree:add({struct_name}_layer, buffer(0, {struct_size}))
{field_definitions}
end]]

field_declaration_template = [===[{struct_name}_layer_fields.{field_name} = ProtoField.{field_type}("{struct_name}_layer_fields.{field_name}", "{field_name}", {base_type}, nil--[[valuestring]], {bit_mask}, "{field_name} description")]===]
field_definition_template = [[
local {field_name}_value = buffer(current_offset, {field_end}):{to_method}()
{struct_name}_layer_tree:add({struct_name}_layer_fields.{field_name}, buffer(current_offset, {field_end}), {field_name}_value)

current_offset = current_offset + {field_end}]]

first_field_definition_template = [[
local {field_name}_value = buffer(0, {field_end}):{to_method}()
{struct_name}_layer_tree:add({struct_name}_layer_fields.{field_name}, buffer(0, {field_end}), {field_name}_value)

local current_offset = {field_end}]]

last_field_definition_template = [[
local {field_name}_value = buffer(current_offset, {field_end}):{to_method}()
{struct_name}_layer_tree:add({struct_name}_layer_fields.{field_name}, buffer(current_offset, {field_end}), {field_name}_value)]]

pad_lef_template = "0x%0{pad_count}x"

function b2ws_create_dissector_next_layer_snippet(field_object, template_string)
	return template_string:gsub("{field_name}", field_object.name)
end

function b2ws_create_dissector_call_snippet(struct_object, field_object, template_string)
	local result_template = template_string:gsub("{field_name}", field_object.name)
	result_template = result_template:gsub("{struct_name}", struct_object.name)
	return result_template:gsub("{struct_size}", struct_object.size)
end

function b2ws_create_dissector_fields_definition_snippet(struct_object, field_object, template_string, next_index)
	local result_template = template_string:gsub("{struct_name}", struct_object.name)
	local array_number = field_object.array_number
	if array_number== nil then
		result_template = result_template:gsub("{to_method}", "le_uint")
	else
		result_template = result_template:gsub("local {field_name}_value = buffer%(current_offset, {field_end}%):{to_method}%(%)\n","")
		result_template = result_template:gsub("local {field_name}_value = %g+\n", "")
		result_template = result_template:gsub(", {field_name}_value%)", ")")
	end

	result_template = result_template:gsub("{field_name}", field_object.name)
	local bit_size = field_object.bit_size

	if bit_size == 0 then
		result_template = result_template:gsub("{field_end}", "buffer:len() - current_offset")
	else
		if bit_size % 8 ~= 0 then
			bit_size = bit_size + 8
		end
		local byte_size = bit_size / 8
		if array_number == nil or tonumber(array_number) ~= nil then
			if field_object.bit_mask ~= nil then
				byte_size = tonumber(string.match(field_object.type, "(%d+)")) / 8
				if next_index > 0 and struct_object.fields[next_index].bit_mask ~= nil then
			    	result_template = result_template:gsub("\ncurrent_offset = current_offset %+ {field_end}", "")
				end

				result_template = result_template:gsub("local current_offset = {field_end}", "local current_offset = 0")
			end

			result_template = result_template:gsub("{field_end}", string.match(byte_size, "(%d+)"))
		else
			result_template = result_template:gsub("{field_end}", string.match(byte_size, "(%d+)") .. " * " .. array_number .. "_value")
		end
	end


	return result_template
end

function b2ws_create_dissector_fields_declaration_snippet(struct_object, field_object, template_string)
	local result_template = template_string:gsub("{struct_name}", struct_object.name)
	result_template = result_template:gsub("{field_name}", field_object.name)
	local field_type = field_object.type
	if field_object.array_number == nil then
		result_template = result_template:gsub("{field_type}", field_type)
	else
		result_template = result_template:gsub("{field_type}", "bytes")
	end

	if field_object.array_number ~= nil then
		result_template = result_template:gsub("{base_type}", "base.NONE")
	elseif b2ws_string_starts(field_type, "u") then
		result_template = result_template:gsub("{base_type}", "base.HEX")
	else
		result_template = result_template:gsub("{base_type}", "base.DEC")
	end

	local bit_mask = field_object.bit_mask
	if bit_mask == nil then
		bit_mask = "nil"
	else
		local size_string = string.match(field_type, "(%d+)")
		local bit_size = string.match(tonumber(size_string) / 4, "(%d+)")
		bit_mask = string.format( pad_lef_template:gsub("{pad_count}", bit_size), bit_mask)
	end
	return result_template:gsub("{bit_mask}", bit_mask)
end

function get_fields_definition_template(field_object)
	if field_object.bit_mask ~= nil then
		return value
	end
end

function b2ws_create_dissector_fields_snippet(struct_object, template_string)
	local field_list = struct_object.fields
	local field_declarations_string = ""
	local field_definitions_string = "\n"
	local tmp_bit_size = 0
	local field_list_len = #field_list
	local field_object = nil
	local tmp_field_definition_template = first_field_definition_template
	if field_list_len > 1 then
		field_object = field_list[1]
		field_declarations_string = field_declarations_string .. b2ws_create_dissector_fields_declaration_snippet(struct_object, field_object, field_declaration_template) .. "\n"
		field_definitions_string = field_definitions_string  .. b2ws_create_dissector_fields_definition_snippet(struct_object, field_object, tmp_field_definition_template, 2) .. "\n"
		tmp_field_definition_template = field_definition_template
		if field_list_len > 2 then
			for key_index = 2, field_list_len - 1
			do
				field_object = field_list[key_index]
				field_declarations_string = field_declarations_string .. b2ws_create_dissector_fields_declaration_snippet(struct_object, field_object, field_declaration_template) .. "\n"
				field_definitions_string = field_definitions_string  .. b2ws_create_dissector_fields_definition_snippet(struct_object, field_object, tmp_field_definition_template, key_index + 1) .. "\n"
			end
		end
	end

	local pre_template = ""
	field_object = field_list[field_list_len]
	if field_object.bit_size == 0 then
		pre_template = b2ws_create_dissector_next_layer_snippet(field_object, next_proto_template) .. "\n"
		field_definitions_string = field_definitions_string .. b2ws_create_dissector_call_snippet(struct_object, field_object, next_proto_dissector_call)
	else
		field_declarations_string = field_declarations_string .. b2ws_create_dissector_fields_declaration_snippet(struct_object, field_object, field_declaration_template).. "\n"
		field_definitions_string = field_definitions_string  .. b2ws_create_dissector_fields_definition_snippet(struct_object, field_object, last_field_definition_template, 0)
	end

	local result_template_string = template_string:gsub("{field_declarations}", field_declarations_string)
	result_template_string = result_template_string:gsub("{field_definitions}", field_definitions_string:gsub("\n", "\n\t"))
	return pre_template .. result_template_string
end

function b2ws_create_dissector_layer_snippet(struct_object, template_string)
	local result_template = template_string:gsub("{struct_name}", struct_object.name)
	if struct_object.fields[#struct_object.fields].bit_size == 0 then
		result_template = result_template:gsub("{struct_size}", "buffer:len()")
	end
	return result_template:gsub("{struct_size}", struct_object.size)
end

function b2ws_create_dissector_snippet(struct_object)
	local result_template = b2ws_create_dissector_fields_snippet(struct_object, proto_template)
	return b2ws_create_dissector_layer_snippet(struct_object, result_template)
end
