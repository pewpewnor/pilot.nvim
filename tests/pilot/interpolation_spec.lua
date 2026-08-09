---@diagnostic disable: undefined-field

local pilot = require("pilot")
local interpolation = require("pilot.interpolation")
local common = require("pilot.common")

describe("interpolation", function()
    pilot.setup()

    it("all placeholders return expected values", function()
        local test_dir_name = "test dir"
        local test_file_name = "file name.txt"
        local test_relative_path =
            common.path_join(test_dir_name, test_file_name)
        local test_path = common.path_join(common.get_cwd(), test_relative_path)
        local escaped_test_path = common.fnameescape(test_path)

        common.set_current_buffer_name(test_path)
        common.set_filetype("text")
        common.set_current_buffer_lines({ "begin hello world-over" })
        common.search("world")

        local got_file_path = interpolation.interpolate("{{file_path}}")
        assert.equals(
            common.fnamemodify(got_file_path, ":p"),
            escaped_test_path
        )

        local got_file_path_relative =
            interpolation.interpolate("{{file_path_relative}}")
        assert.is_truthy(
            got_file_path_relative == test_relative_path
                or got_file_path_relative == escaped_test_path
        )

        assert.equals(
            interpolation.interpolate("{{file_name}}"),
            common.fnameescape(test_file_name)
        )
        assert.equals(
            interpolation.interpolate("{{dir_name}}"),
            common.fnameescape(test_dir_name)
        )
        assert.equals(
            interpolation.interpolate("{{cwd_path}}"),
            common.fnameescape(common.get_cwd())
        )
        assert.equals(
            interpolation.interpolate("{{cwd_name}}"),
            common.fnameescape(common.fnamemodify(common.get_cwd(), ":t"))
        )

        local pd = interpolation.interpolate("{{pilot_data_path}}")
        assert.is_string(pd)
        assert.is_truthy(common.is_directory(pd))

        assert.equals(interpolation.interpolate("{{cword}}"), "world")
        assert.equals(interpolation.interpolate("{{cWORD}}"), "world-over")

        assert.equals(
            interpolation.interpolate("{{hash_sha256(cwd_path)}}"),
            common.hash_sha256(common.fnameescape(common.get_cwd()))
        )
        assert.equals(
            interpolation.interpolate("{{hash_sha256(file_path)}}"),
            common.hash_sha256(escaped_test_path)
        )
    end)

    it(
        "escapes vim specials in static text to prevent unwanted expansion",
        function()
            local cmd = "echo % #"
            local expected = "echo \\% \\#"
            assert.equals(interpolation.interpolate(cmd), expected)
        end
    )

    it(
        "correctly escapes vim specials inside complex shell quoted strings",
        function()
            local cmd = [[echo $'\\^!#$%@&*()_+=-`~[]{};:'",<.>/?|']]
            local expected = [[echo $'\\^!\#$\%@&*()_+=-`~[]{};:'",<.>/?|']]
            assert.equals(interpolation.interpolate(cmd), expected)
        end
    )
end)
