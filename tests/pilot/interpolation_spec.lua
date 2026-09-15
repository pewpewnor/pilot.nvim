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
        local escaped_test_path = common.shellescape(test_path)

        common.mkdir_with_parents(test_dir_name)
        common.set_current_buffer_name(test_path)
        common.set_filetype("text")
        common.set_current_buffer_lines({ "begin hello world-over" })
        common.search("world")

        local got_file_path = interpolation.interpolate("{{file_path}}")
        assert.equals(got_file_path, escaped_test_path)

        local got_file_path_relative =
            interpolation.interpolate("{{file_path_relative}}")
        assert.is_truthy(
            got_file_path_relative == test_relative_path
                or got_file_path_relative == escaped_test_path
        )

        assert.equals(
            interpolation.interpolate("{{file_name}}"),
            common.shellescape(test_file_name)
        )
        assert.equals(
            interpolation.interpolate("{{dir_name}}"),
            common.shellescape(test_dir_name)
        )
        assert.equals(
            interpolation.interpolate("{{cwd_path}}"),
            common.shellescape(common.get_cwd())
        )
        assert.equals(
            interpolation.interpolate("{{cwd_name}}"),
            common.shellescape(common.fnamemodify(common.get_cwd(), ":t"))
        )

        local pd = interpolation.interpolate("{{pilot_data_path}}", true)
        assert.is_string(pd)
        assert.is_truthy(common.is_directory(pd))

        assert.equals(
            interpolation.interpolate("{{cword}}"),
            common.shellescape("world")
        )
        assert.equals(
            interpolation.interpolate("{{cWORD}}"),
            common.shellescape("world-over")
        )

        assert.equals(
            interpolation.interpolate("{{hash_sha256(cwd_path)}}"),
            common.shellescape(common.hash_sha256(common.get_cwd()))
        )
        assert.equals(
            interpolation.interpolate("{{hash_sha256(file_path)}}"),
            common.shellescape(common.hash_sha256(test_path))
        )

        common.cmd("enew!")
        common.path_remove_recursive(test_dir_name)
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

    it("shell-escapes custom placeholder values in commands", function()
        pilot.setup({
            placeholders = {
                vars = {
                    custom = function()
                        return "value with spaces & operators"
                    end,
                },
            },
        })

        assert.equals(
            "echo " .. common.shellescape("value with spaces & operators"),
            pilot.utils.interpolate("echo {{custom}}")
        )
    end)
end)
