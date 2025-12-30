---@diagnostic disable: undefined-field

local interp = require("pilot.interpolation")

describe("pilot.interpolation", function()
    it(
        "resolve_placeholder: all placeholders return expected values",
        function()
            local rel = "test dir/file name.txt"
            local test_path = vim.fn.getcwd() .. "/" .. rel
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

            local got_file_path = interp._resolve_placeholder("file_path")
            assert.equals(vim.fn.fnamemodify(got_file_path, ":p"), test_path)

            local got_file_path_relative =
                interp._resolve_placeholder("file_path_relative")
            assert.is_truthy(
                got_file_path_relative == rel
                    or got_file_path_relative == test_path
            )

            assert.equals(
                interp._resolve_placeholder("file_name"),
                "file name.txt"
            )
            assert.equals(interp._resolve_placeholder("dir_name"), "test dir")
            assert.equals(
                interp._resolve_placeholder("cwd_path"),
                vim.fn.getcwd()
            )
            assert.equals(
                interp._resolve_placeholder("cwd_name"),
                vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
            )

            local pd = interp._resolve_placeholder("pilot_data_path")
            assert.is_string(pd)
            assert.equals(vim.fn.isdirectory(pd), 1)

            assert.equals(interp._resolve_placeholder("cword"), "world")
            assert.equals(interp._resolve_placeholder("cWORD"), "world-over")

            assert.equals(
                interp._resolve_placeholder("hash(cwd_path)"),
                vim.fn.sha256(vim.fn.getcwd())
            )
            assert.equals(
                interp._resolve_placeholder("hash(file_path)"),
                vim.fn.sha256(test_path)
            )
        end
    )

    it(
        "interpolate: complex shell quoted string preserves content when executed",
        function()
            local cmd = [[echo $'\\\\@!#$%^&*()_+=-`~[]{};:\'",<.>/?|']]
            local escaped = interp.interpolate(cmd)
            local out = vim.fn.system(escaped)
            local trimmed = vim.fn.trim(out)

            local expected = [[\@!#$%^&*()_+=-`~[]{};:'",<.>/?|]]
            assert.equals(trimmed, expected)
        end
    )
end)
