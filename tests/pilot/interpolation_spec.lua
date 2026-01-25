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
            vim.fs.joinpath(test_dir_name, test_file_name)
        local test_path = vim.fs.joinpath(vim.fn.getcwd(), test_relative_path)
        local escaped_test_path = vim.fn.fnameescape(test_path)

        vim.api.nvim_buf_set_name(0, test_path)
        vim.bo.filetype = "text"
        vim.api.nvim_buf_set_lines(
            0,
            0,
            -1,
            false,
            { "begin hello world-over" }
        )
        vim.fn.search("world")

        local got_file_path = interpolation.interpolate("{{file_path}}")
        assert.equals(
            vim.fn.fnamemodify(got_file_path, ":p"),
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
            vim.fn.fnameescape(test_file_name)
        )
        assert.equals(
            interpolation.interpolate("{{dir_name}}"),
            vim.fn.fnameescape(test_dir_name)
        )
        assert.equals(
            interpolation.interpolate("{{cwd_path}}"),
            vim.fn.fnameescape(vim.fn.getcwd())
        )
        assert.equals(
            interpolation.interpolate("{{cwd_name}}"),
            vim.fn.fnameescape(vim.fn.fnamemodify(vim.fn.getcwd(), ":t"))
        )

        local pd = interpolation.interpolate("{{pilot_data_path}}")
        assert.is_string(pd)
        assert.is_truthy(common.is_directory(pd))

        assert.equals(interpolation.interpolate("{{cword}}"), "world")
        assert.equals(interpolation.interpolate("{{cWORD}}"), "world-over")

        assert.equals(
            interpolation.interpolate("{{hash_sha256(cwd_path)}}"),
            vim.fn.sha256(vim.fn.fnameescape(vim.fn.getcwd()))
        )
        assert.equals(
            interpolation.interpolate("{{hash_sha256(file_path)}}"),
            vim.fn.sha256(escaped_test_path)
        )
    end)

    it(
        "escapes vim specials in static text to prevent unwanted expansion",
        function()
            local cmd = "echo % # <"
            local expected = "echo \\% \\# \\<"
            assert.equals(interpolation.interpolate(cmd), expected)
        end
    )

    it(
        "correctly escapes vim specials inside complex shell quoted strings",
        function()
            local cmd = [[echo $'\\^!#$%@&*()_+=-`~[]{};:'",<.>/?|']]
            local expected = [[echo $'\\^!\#$\%@&*()_+=-`~[]{};:'",\<.>/?|']]
            assert.equals(interpolation.interpolate(cmd), expected)
        end
    )
end)
