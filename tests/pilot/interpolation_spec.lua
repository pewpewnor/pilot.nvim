---@diagnostic disable: undefined-field

local pilot = require("pilot")
local interpolation = require("pilot.interpolation")

describe("interpolation", function()
    pilot.setup()

    it("all placeholders return expected values", function()
        local rel = "test dir/file name.txt"
        local test_path = vim.fn.getcwd() .. "/" .. rel
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
            got_file_path_relative == rel
                or got_file_path_relative == escaped_test_path
        )

        assert.equals(
            interpolation.interpolate("{{file_name}}"),
            "file\\ name.txt"
        )
        assert.equals(interpolation.interpolate("{{dir_name}}"), "test\\ dir")
        assert.equals(
            interpolation.interpolate("{{cwd_path}}"),
            vim.fn.getcwd()
        )
        assert.equals(
            interpolation.interpolate("{{cwd_name}}"),
            vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
        )

        local pd = interpolation.interpolate("{{pilot_data_path}}")
        assert.is_string(pd)
        assert.equals(vim.fn.isdirectory(pd), 1)

        assert.equals(interpolation.interpolate("{{cword}}"), "world")
        assert.equals(interpolation.interpolate("{{cWORD}}"), "world-over")

        assert.equals(
            interpolation.interpolate("{{hash_sha256(cwd_path)}}"),
            vim.fn.sha256(vim.fn.getcwd())
        )
        assert.equals(
            interpolation.interpolate("{{hash_sha256(file_path)}}"),
            vim.fn.sha256(test_path)
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
