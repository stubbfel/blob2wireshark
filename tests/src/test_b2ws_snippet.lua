
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
        lu.assertEquals(fieldObject.offset, 0)
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
        lu.assertEquals(fieldObject.offset, 0)
        lu.assertEquals(fieldObject.array_number, nil)

        fieldObject = b2ws_create_field_object("foo3", "uint16", "[ ]")
        lu.assertEquals(fieldObject.name, 'foo3')
        lu.assertEquals(fieldObject.type, 'uint16')
        lu.assertEquals(fieldObject.bit_size, 0)
        lu.assertEquals(fieldObject.bit_mask, nil)
        lu.assertEquals(fieldObject.offset, 0)
        lu.assertEquals(fieldObject.array_number, "")

        fieldObject = b2ws_create_field_object("foo3-1", "uint16", "[]")
        lu.assertEquals(fieldObject.name, 'foo3-1')
        lu.assertEquals(fieldObject.type, 'uint16')
        lu.assertEquals(fieldObject.bit_size, 0)
        lu.assertEquals(fieldObject.bit_mask, nil)
        lu.assertEquals(fieldObject.offset, 0)
        lu.assertEquals(fieldObject.array_number, "")

        fieldObject = b2ws_create_field_object("foo4", "int16", "[3]")
        lu.assertEquals(fieldObject.name, 'foo4')
        lu.assertEquals(fieldObject.type, 'int16')
        lu.assertEquals(fieldObject.bit_size, 48)
        lu.assertEquals(fieldObject.bit_mask, nil)
        lu.assertEquals(fieldObject.offset, 0)
        lu.assertEquals(fieldObject.array_number, "3")

        fieldObject = b2ws_create_field_object("foo5", "int16", "[foo]")
        lu.assertEquals(fieldObject.name, 'foo5')
        lu.assertEquals(fieldObject.type, 'int16')
        lu.assertEquals(fieldObject.bit_size, 16)
        lu.assertEquals(fieldObject.bit_mask, nil)
        lu.assertEquals(fieldObject.offset, 0)
        lu.assertEquals(fieldObject.array_number, "foo")

        fieldObject = b2ws_create_field_object("foo6", "uint32", ":0-15")
        lu.assertEquals(fieldObject.name, 'foo6')
        lu.assertEquals(fieldObject.type, 'uint32')
        lu.assertEquals(fieldObject.bit_size, 16)
        lu.assertEquals(fieldObject.bit_mask, 0x0000ffff)
        lu.assertEquals(fieldObject.offset, 0)
        lu.assertEquals(fieldObject.array_number, nil)

        fieldObject = b2ws_create_field_object("foo6-1", "uint32", ":8-23")
        lu.assertEquals(fieldObject.name, 'foo6-1')
        lu.assertEquals(fieldObject.type, 'uint32')
        lu.assertEquals(fieldObject.bit_size, 16)
        lu.assertEquals(fieldObject.bit_mask, 0x00ffff00)
        lu.assertEquals(fieldObject.offset, 0)
        lu.assertEquals(fieldObject.array_number, nil)

        fieldObject = b2ws_create_field_object("foo6-2", "uint32", ":24-31")
        lu.assertEquals(fieldObject.name, 'foo6-2')
        lu.assertEquals(fieldObject.type, 'uint32')
        lu.assertEquals(fieldObject.bit_size, 8)
        lu.assertEquals(fieldObject.bit_mask, 0xff000000)
        lu.assertEquals(fieldObject.offset, 0)
        lu.assertEquals(fieldObject.array_number, nil)

    end

    function TestSnippet:testParseStruct()
        local structObject = b2ws_parse_struct([["  struct foo
         { uint8 bla_count; uint16_t bla[bla_count];
         uint32_t foo:0-15; int64_t bar[]; int8_t bla[3];
          int16_t bla; int32_t bla; int64_t bla;
        }  "]])
        lu.assertEquals(structObject.name, 'foo')
        lu.assertEquals(structObject.size, -1)
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
          int16_t bla; int32_t bla; int64_t bla;
        }  "]])
        result_template = b2ws_create_dissector_snippet(structObject)
        --print(result_template)
    end

    function TestSnippet:testCreateLayerSnippets()
        local structObject = b2ws_parse_struct([["  struct foo
         { uint8 bla_count; uint16_t bla[bla_count];
         uint32_t foo:0-15; int64_t bar[]; int8_t bla[3];
          int16_t bla; int32_t bla; int64_t bla;
        }  "]])
        result_template = b2ws_create_dissector_layer_snippet(structObject, "{struct_size}bla \n\t{struct_name}_bar{struct_size}\n{struct_name}:{struct_name}{struct_size}")
        lu.assertEquals(result_template, "-1bla \n\tfoo_bar-1\nfoo:foo-1")
    end


-- class TestSnippet

local runner = lu.LuaUnit.new()
runner:setOutputType("tap")
os.exit( runner:runSuite() )
