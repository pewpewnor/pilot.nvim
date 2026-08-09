local common = require("pilot.common")
local module = require("pilot.module")
local pathfinder = require("pilot.pathfinder")

local M = {}

local function check_neovim_version()
    if common.has("nvim-0.12") then
        common.health_ok("neovim version is v0.12.0 or newer")
    else
        common.health_error(
            "neovim v0.12.0 or newer is required",
            "upgrade your neovim installation"
        )
    end
end

local function check_setup_called()
    if not module.config then
        common.health_error(
            "setup() has not been called",
            "call require('pilot').setup({}) in your configuration"
        )
        return
    end
    common.health_ok("setup() has been called")
end

local function check_shell()
    local shell = common.get_shell()
    if common.is_executable(shell) then
        common.health_ok(string.format("shell '%s' is executable", shell))
    else
        common.health_error(
            string.format("shell '%s' is not executable", shell),
            "every executor runs commands through 'shell', set it to an installed shell"
        )
    end
end

local function check_target_paths()
    for target_name, target in pairs(module.config.targets) do
        local success, path =
            pcall(pathfinder.get_true_path, target.pilot_file_path)
        if not success then
            common.health_error(
                string.format(
                    "target '%s' cannot resolve a pilot file path: %s",
                    target_name,
                    path
                )
            )
        else
            local directory = common.dirname(path)
            if common.is_directory_writable(directory) then
                common.health_ok(
                    string.format(
                        "target '%s' can write pilot files into '%s'",
                        target_name,
                        directory
                    )
                )
            else
                common.health_warn(
                    string.format(
                        "target '%s' cannot write pilot files into '%s'",
                        target_name,
                        directory
                    ),
                    "the directory is missing or not writable, creating or editing a pilot file for this target will fail"
                )
            end
        end
    end
end

function M.check()
    common.health_start("pilot.nvim")

    check_neovim_version()
    check_setup_called()
    check_shell()
    check_target_paths()
end

return M
