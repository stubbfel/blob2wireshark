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
	return {["name"] = b2ws_trim(name), ["type"] = ws_type_name, ["bit_size"] = bit_size, ["bit_mask"] = bit_mask, ["offset"] = 0, ["array_number"] = array_number}
end

function b2ws_create_struct_object(name)
	return {["name"] = b2ws_trim(name), ["size"] = -1, ["fields"] = {}}
end

function b2ws_parse_struct(struct_string)
	local struct_name, field_list = string.match(b2ws_trim(struct_string), "struct%s+(%g+)%s*{(.*)}")
	struct_object = b2ws_create_struct_object(struct_name)
	for key_index, field_string in next, b2ws_string_split(field_list, ";")
	do
		local trim_filed_string = b2ws_trim(field_string)
		if trim_filed_string ~= "" then
			local type_name, field_name, type_suffix = string.match(trim_filed_string, "(%g+)%s+([%w_]+)(%g*)")
			if type_suffix == nil then
				type_suffix = ""
			end
			struct_object.fields[key_index] = b2ws_create_field_object(field_name, type_name, type_suffix)
		end
	end
	return struct_object
end

proto_template = [[-- {struct_name} Layer
{struct_name}_layer = Proto("{struct_name}_layer", "{struct_name} layer")
local {struct_name}_layer_fields = {struct_name}_layer.fields
{field_declarations}
function {struct_name}_layer.dissector(buffer, packet_info, tree)
	{struct_name}_layer_tree = tree:add({struct_name}_layer, buffer(0, {struct_size}))
	{field_definitions}
end]]

field_declaration_template = [===[{struct_name}_layer_fields.{field_name} = ProtoField.{fiel_type}("{struct_name}_layer_fields.{field_name}", "{field_name}", {base_type}, nil--[[valuestring]], {bit_mask}, {field_name} description})]===]
field_definition_template = [[
local {field_name}_value = buffer({field_start},{field_end}):{to_method}()
{struct_name}_layer_tree:add({struct_name}_layer_fields.{field_name}, buffer({field_start}, {field_end}), {field_name}_value)]]


function b2ws_create_dissector_fields_snippet(struct_object, template_string)
	return template_string
end

function b2ws_create_dissector_layer_snippet(struct_object, template_string)
	local result_template = template_string:gsub("{struct_name}", struct_object.name)
	return result_template:gsub("{struct_size}", struct_object.size)
end

function b2ws_create_dissector_snippet(struct_object)
	local result_template = b2ws_create_dissector_fields_snippet(struct_object, proto_template)
	return b2ws_create_dissector_layer_snippet(struct_object, result_template)
end
