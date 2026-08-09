local module = require("pilot.module")
local pathfinder = require("pilot.pathfinder")

local M = {}

local function check_neovim_version()
    if vim.fn.has("nvim-0.12") == 1 then
        vim.health.ok("neovim version is v0.12.0 or newer")
    else
        vim.health.error(
            "neovim v0.12.0 or newer is required",
            "upgrade your neovim installation"
        )
    end
end

local function check_setup_called()
    if not module.config then
        vim.health.error(
            "setup() has not been called",
            "call require('pilot').setup({}) in your configuration"
        )
        return
    end
    vim.health.ok("setup() has been called")
end

local function check_shell()
    if vim.fn.executable(vim.o.shell) == 1 then
        vim.health.ok(string.format("shell '%s' is executable", vim.o.shell))
    else
        vim.health.error(
            string.format("shell '%s' is not executable", vim.o.shell),
            "every executor runs commands through 'shell', set it to an installed shell"
        )
    end
end

local function check_target_paths()
    ---@diagnostic disable-next-line: undefined-field
    require("pilot.common")
        .iter(module.config.targets)
        :each(function(target_name, target)
            local success, path =
                pcall(pathfinder.get_true_path, target.pilot_file_path)
            if not success then
                vim.health.error(
                    string.format(
                        "target '%s' cannot resolve a pilot file path: %s",
                        target_name,
                        path
                    )
                )
                return
            end

            local directory = vim.fs.dirname(path)
            if vim.fn.filewritable(directory) == 2 then
                vim.health.ok(
                    string.format(
                        "target '%s' can write pilot files into '%s'",
                        target_name,
                        directory
                    )
                )
            else
                vim.health.warn(
                    string.format(
                        "target '%s' cannot write pilot files into '%s'",
                        target_name,
                        directory
                    ),
                    "the directory is missing or not writable, creating or editing a pilot file for this target will fail"
                )
            end
        end)
end

function M.check()
    vim.health.start("pilot.nvim")

    check_neovim_version()
    check_setup_called()
    check_shell()
    check_target_paths()
end

return M
