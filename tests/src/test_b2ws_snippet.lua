
local loaded_const_code = assert(loadfile("../../src/b2ws-plugin/b2ws_const.lua"))
loaded_const_code()
b2ws_const.B2WS_PLUGIN_PATH="../../src/b2ws-plugin/"
local loaded_test_code = assert(loadfile("../../src/b2ws-plugin/b2ws_snippet.lua"))
loaded_test_code()

-- Unit testing starts
local lu = require('luaunit')

TestSnippet = {} --class
    function TestSnippet:testCreateObjects()
        local fieldObject = b2ws_create_field_object("foo ", " bar", "")
        lu.assertEquals(fieldObject.name, 'foo')
        lu.assertEquals(fieldObject.type, 'bar')
        lu.assertEquals(fieldObject.bit_size, nil)
        lu.assertEquals(fieldObject.bit_mask, nil)
        lu.assertEquals(fieldObject.array_number, nil)

        local structObject = b2ws_create_struct_object("bla  ")
        structObject.fields[1] = fieldObject
        lu.assertEquals(structObject.name, 'bla')
        lu.assertEquals(structObject.size, -1)
        lu.assertEquals(structObject.fields[1].name, 'foo')
        lu.assertEquals(structObject.fields[1].type, 'bar')

        fieldObject = b2ws_create_field_object("foo2", "uint8_t", "")
        lu.assertEquals(fieldObject.name, 'foo2')
        lu.assertEquals(fieldObject.type, 'uint8')
        lu.assertEquals(fieldObject.bit_size, 8)
        lu.assertEquals(fieldObject.bit_mask, nil)
        lu.assertEquals(fieldObject.array_number, nil)

        fieldObject = b2ws_create_field_object("foo3", "uint16", "[ ]")
        lu.assertEquals(fieldObject.name, 'foo3')
        lu.assertEquals(fieldObject.type, 'uint16')
        lu.assertEquals(fieldObject.bit_size, 0)
        lu.assertEquals(fieldObject.bit_mask, nil)
        lu.assertEquals(fieldObject.array_number, "")

        fieldObject = b2ws_create_field_object("foo3-1", "uint16", "[]")
        lu.assertEquals(fieldObject.name, 'foo3-1')
        lu.assertEquals(fieldObject.type, 'uint16')
        lu.assertEquals(fieldObject.bit_size, 0)
        lu.assertEquals(fieldObject.bit_mask, nil)
        lu.assertEquals(fieldObject.array_number, "")

        fieldObject = b2ws_create_field_object("foo4", "int16", "[3]")
        lu.assertEquals(fieldObject.name, 'foo4')
        lu.assertEquals(fieldObject.type, 'int16')
        lu.assertEquals(fieldObject.bit_size, 48)
        lu.assertEquals(fieldObject.bit_mask, nil)
        lu.assertEquals(fieldObject.array_number, "3")

        fieldObject = b2ws_create_field_object("foo5", "int16", "[foo]")
        lu.assertEquals(fieldObject.name, 'foo5')
        lu.assertEquals(fieldObject.type, 'int16')
        lu.assertEquals(fieldObject.bit_size, 16)
        lu.assertEquals(fieldObject.bit_mask, nil)
        lu.assertEquals(fieldObject.array_number, "foo")

        fieldObject = b2ws_create_field_object("foo6", "uint32", ":0-15")
        lu.assertEquals(fieldObject.name, 'foo6')
        lu.assertEquals(fieldObject.type, 'uint32')
        lu.assertEquals(fieldObject.bit_size, 16)
        lu.assertEquals(fieldObject.bit_mask, 0x0000ffff)
        lu.assertEquals(fieldObject.array_number, nil)

        fieldObject = b2ws_create_field_object("foo6-1", "uint32", ":8-23")
        lu.assertEquals(fieldObject.name, 'foo6-1')
        lu.assertEquals(fieldObject.type, 'uint32')
        lu.assertEquals(fieldObject.bit_size, 16)
        lu.assertEquals(fieldObject.bit_mask, 0x00ffff00)
        lu.assertEquals(fieldObject.array_number, nil)

        fieldObject = b2ws_create_field_object("foo6-2", "uint32", ":24-31")
        lu.assertEquals(fieldObject.name, 'foo6-2')
        lu.assertEquals(fieldObject.type, 'uint32')
        lu.assertEquals(fieldObject.bit_size, 8)
        lu.assertEquals(fieldObject.bit_mask, 0xff000000)
        lu.assertEquals(fieldObject.array_number, nil)

    end

    function TestSnippet:testParseStruct()
        local structObject = b2ws_parse_struct([["  struct foo
         { uint8 bla_count; uint16_t bla[bla_count];
         uint32_t foo:0-15; int64_t bar[]; int8_t bla[3];
          int16_t bla; int32_t bla; int64_t bla;
        }  "]])
        lu.assertEquals(structObject.name, 'foo')
        lu.assertEquals(structObject.size, 22)
        lu.assertEquals(structObject.fields[1].name, 'bla_count')
        lu.assertEquals(structObject.fields[1].type, 'uint8')
        lu.assertEquals(structObject.fields[2].name, 'bla')
        lu.assertEquals(structObject.fields[2].type, 'uint16')
        lu.assertEquals(structObject.fields[3].name, 'foo')
        lu.assertEquals(structObject.fields[3].type, 'uint32')
        lu.assertEquals(structObject.fields[4].name, 'bar')
        lu.assertEquals(structObject.fields[4].type, 'int64')
        lu.assertEquals(structObject.fields[#structObject.fields].name, 'bla')
        lu.assertEquals(structObject.fields[#structObject.fields].type, 'int64')
    end

    function TestSnippet:testCreateSnippets()
        local structObject = b2ws_parse_struct([["  struct foo
         { uint8 bla_count; uint16_t bla[bla_count];
         uint32_t foo:0-15; int64_t bar[]; int8_t bla[3];
          int16_t bla; int32_t bla; int64_t bar[];
        }  "]])
        local result_template = b2ws_create_dissector_snippet(structObject)
        local expected_result = [===[-- bar Layer
bar_layer = Proto("bar_layer", "bar layer")

function bar_layer.dissector(buffer, packet_info, tree)
	bar_layer_tree = tree:add(bar_layer, buffer(0, buffer:len()))
end

-- foo Layer
foo_layer = Proto("foo_layer", "foo layer")

local foo_layer_fields = foo_layer.fields
foo_layer_fields.bla_count = ProtoField.uint8("foo_layer_fields.bla_count", "bla_count", base.HEX, nil--[[valuestring]], nil, bla_count description})
foo_layer_fields.bla = ProtoField.bytes("foo_layer_fields.bla", "bla", base.HEX, nil--[[valuestring]], nil, bla description})
foo_layer_fields.foo = ProtoField.uint32("foo_layer_fields.foo", "foo", base.HEX, nil--[[valuestring]], 0x0000ffff, foo description})
foo_layer_fields.bar = ProtoField.bytes("foo_layer_fields.bar", "bar", base.HEX, nil--[[valuestring]], nil, bar description})
foo_layer_fields.bla = ProtoField.bytes("foo_layer_fields.bla", "bla", base.HEX, nil--[[valuestring]], nil, bla description})
foo_layer_fields.bla = ProtoField.int16("foo_layer_fields.bla", "bla", base.DEC, nil--[[valuestring]], nil, bla description})
foo_layer_fields.bla = ProtoField.int32("foo_layer_fields.bla", "bla", base.DEC, nil--[[valuestring]], nil, bla description})

function foo_layer.dissector(buffer, packet_info, tree)
	foo_layer_tree = tree:add(foo_layer, buffer(0, 14.0))

	local bla_count_value = buffer(0, 1):le_uint()
	foo_layer_tree:add(foo_layer_fields.bla_count, buffer(0, 1), bla_count_value)

	local current_offset = 1
	local bla_value = buffer(current_offset, 2 * bla_count_value):bytes()
	foo_layer_tree:add(foo_layer_fields.bla, buffer(current_offset, 2 * bla_count_value), bla_value)

	current_offset = current_offset + 2 * bla_count_value
	local foo_value = buffer(current_offset, 4):le_uint()
	foo_layer_tree:add(foo_layer_fields.foo, buffer(current_offset, 4), foo_value)

	current_offset = current_offset + 4
	local bar_value = buffer(current_offset, buffer:len() - current_offset):bytes()
	foo_layer_tree:add(foo_layer_fields.bar, buffer(current_offset, buffer:len() - current_offset), bar_value)

	current_offset = current_offset + buffer:len() - current_offset
	local bla_value = buffer(current_offset, 3):bytes()
	foo_layer_tree:add(foo_layer_fields.bla, buffer(current_offset, 3), bla_value)

	current_offset = current_offset + 3
	local bla_value = buffer(current_offset, 2):le_uint()
	foo_layer_tree:add(foo_layer_fields.bla, buffer(current_offset, 2), bla_value)

	current_offset = current_offset + 2
	local bla_value = buffer(current_offset, 4):le_uint()
	foo_layer_tree:add(foo_layer_fields.bla, buffer(current_offset, 4), bla_value)

	current_offset = current_offset + 4
	Dissector.get("bar_layer"):call(buffer(14.0, buffer:len() - 14.0):tvb(), packet_info, tree)
end
]===]
        lu.assertEquals(result_template:gsub("%s", ""), expected_result:gsub("%s", ""))
--        print(result_template)
    end

    function TestSnippet:testCreateLayerSnippets()
        local structObject = b2ws_parse_struct([["  struct foo
         { uint8 bla_count; uint16_t bla[bla_count];
         uint32_t foo:0-15; int64_t bar[]; int8_t bla[3];
          int16_t bla; int32_t bla; int64_t bla;
        }  "]])
        result_template = b2ws_create_dissector_layer_snippet(structObject, "{struct_size}bla \n\t{struct_name}_bar{struct_size}\n{struct_name}:{struct_name}{struct_size}")
        lu.assertEquals(result_template, "22.0bla \n\tfoo_bar22.0\nfoo:foo22.0")
    end

    function TestSnippet:testCreateFunctionDeclaration()
        local test_field_declaration_template = [===[{struct_name}_layer_fields.{field_name} = ProtoField.{field_type}("{struct_name}_layer_fields.{field_name}", "{field_name}", {base_type}, nil--[[valuestring]], {bit_mask}, {field_name} description})]===]

        local structObject = b2ws_create_struct_object("bla  ")
        structObject.fields[1] = fieldObject
        lu.assertEquals(structObject.name, 'bla')

        local fieldObject = b2ws_create_field_object("foo2", "uint8_t", "")
        local result_string = b2ws_create_dissector_fields_declaration_snippet(structObject, fieldObject, test_field_declaration_template)
        lu.assertEquals(result_string,
            "bla_layer_fields.foo2 = ProtoField.uint8(\"bla_layer_fields.foo2\", \"foo2\", base.HEX, nil--[[valuestring]], nil, foo2 description})")

        fieldObject = b2ws_create_field_object("foo3", "uint16", "[ ]")
        result_string = b2ws_create_dissector_fields_declaration_snippet(structObject, fieldObject, test_field_declaration_template)
        lu.assertEquals(result_string,
            "bla_layer_fields.foo3 = ProtoField.bytes(\"bla_layer_fields.foo3\", \"foo3\", base.HEX, nil--[[valuestring]], nil, foo3 description})")

        fieldObject = b2ws_create_field_object("foo3-1", "uint16", "[]")
        result_string = b2ws_create_dissector_fields_declaration_snippet(structObject, fieldObject, test_field_declaration_template)
        lu.assertEquals(result_string,
            "bla_layer_fields.foo3-1 = ProtoField.bytes(\"bla_layer_fields.foo3-1\", \"foo3-1\", base.HEX, nil--[[valuestring]], nil, foo3-1 description})")

        fieldObject = b2ws_create_field_object("foo4", "int16", "")
        result_string = b2ws_create_dissector_fields_declaration_snippet(structObject, fieldObject, test_field_declaration_template)
        lu.assertEquals(result_string,
            "bla_layer_fields.foo4 = ProtoField.int16(\"bla_layer_fields.foo4\", \"foo4\", base.DEC, nil--[[valuestring]], nil, foo4 description})")

        fieldObject = b2ws_create_field_object("foo5", "int16", "[foo]")
        result_string = b2ws_create_dissector_fields_declaration_snippet(structObject, fieldObject, test_field_declaration_template)
        lu.assertEquals(result_string,
            "bla_layer_fields.foo5 = ProtoField.bytes(\"bla_layer_fields.foo5\", \"foo5\", base.HEX, nil--[[valuestring]], nil, foo5 description})")

        fieldObject = b2ws_create_field_object("foo6", "uint32", ":0-15")
        result_string = b2ws_create_dissector_fields_declaration_snippet(structObject, fieldObject, test_field_declaration_template)
        lu.assertEquals(result_string,
            "bla_layer_fields.foo6 = ProtoField.uint32(\"bla_layer_fields.foo6\", \"foo6\", base.HEX, nil--[[valuestring]], 0x0000ffff, foo6 description})")

        fieldObject = b2ws_create_field_object("foo6-1", "int32", ":8-23")
        result_string = b2ws_create_dissector_fields_declaration_snippet(structObject, fieldObject, test_field_declaration_template)
        lu.assertEquals(result_string,
            "bla_layer_fields.foo6-1 = ProtoField.int32(\"bla_layer_fields.foo6-1\", \"foo6-1\", base.DEC, nil--[[valuestring]], 0x00ffff00, foo6-1 description})")
    end

    function TestSnippet:testCreateFunctionDefinition()
        local test_field_declaration_template = [[local {field_name}_value = buffer(0,{field_end}):{to_method}()
{struct_name}_layer_tree:add({struct_name}_layer_fields.{field_name}, buffer(0, {field_end}), {field_name}_value)]]

        local structObject = b2ws_create_struct_object("bla  ")
        structObject.fields[1] = fieldObject
        lu.assertEquals(structObject.name, 'bla')

        local fieldObject = b2ws_create_field_object("foo2", "uint8_t", "")
        local result_string = b2ws_create_dissector_fields_definition_snippet(structObject, fieldObject, test_field_declaration_template)
        lu.assertEquals(result_string,
            "local foo2_value = buffer(0,1):le_uint()\nbla_layer_tree:add(bla_layer_fields.foo2, buffer(0, 1), foo2_value)")

        fieldObject = b2ws_create_field_object("foo3", "uint16", "[ ]")
        result_string = b2ws_create_dissector_fields_definition_snippet(structObject, fieldObject, test_field_declaration_template)
        lu.assertEquals(result_string,
        "local foo3_value = buffer(0,buffer:len() - current_offset):bytes()\nbla_layer_tree:add(bla_layer_fields.foo3, buffer(0, buffer:len() - current_offset), foo3_value)")

        fieldObject = b2ws_create_field_object("foo33", "uint16", "[3]")
        result_string = b2ws_create_dissector_fields_definition_snippet(structObject, fieldObject, test_field_declaration_template)
        lu.assertEquals(result_string,
        "local foo33_value = buffer(0,6):bytes()\nbla_layer_tree:add(bla_layer_fields.foo33, buffer(0, 6), foo33_value)")

        fieldObject = b2ws_create_field_object("foo4", "int16", "")
        local result_string = b2ws_create_dissector_fields_definition_snippet(structObject, fieldObject, test_field_declaration_template)
        lu.assertEquals(result_string,
            "local foo4_value = buffer(0,2):le_uint()\nbla_layer_tree:add(bla_layer_fields.foo4, buffer(0, 2), foo4_value)")

        fieldObject = b2ws_create_field_object("foo5", "int16", "[foo]")
        result_string = b2ws_create_dissector_fields_definition_snippet(structObject, fieldObject, test_field_declaration_template)
        lu.assertEquals(result_string,
        "local foo5_value = buffer(0,2 * foo_value):bytes()\nbla_layer_tree:add(bla_layer_fields.foo5, buffer(0, 2 * foo_value), foo5_value)")

        fieldObject = b2ws_create_field_object("foo6", "uint32", ":0-15")
        result_string = b2ws_create_dissector_fields_definition_snippet(structObject, fieldObject, test_field_declaration_template)
        lu.assertEquals(result_string,
            "local foo6_value = buffer(0,4):le_uint()\nbla_layer_tree:add(bla_layer_fields.foo6, buffer(0, 4), foo6_value)")

        fieldObject = b2ws_create_field_object("foo6-1", "int32", ":8-23")
        result_string = b2ws_create_dissector_fields_definition_snippet(structObject, fieldObject, test_field_declaration_template)
        lu.assertEquals(result_string,
            "local foo6-1_value = buffer(0,4):le_uint()\nbla_layer_tree:add(bla_layer_fields.foo6-1, buffer(0, 4), foo6-1_value)")
    end

-- class TestSnippet

local runner = lu.LuaUnit.new()
runner:setOutputType("tap")
os.exit( runner:runSuite() )
