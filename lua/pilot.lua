---@alias PilotFilepathResolver fun(): string?

---@alias Executor fun(command: string, args: string[]?)

---@class Executors
---@field [string] Executor

---@class Target
---@field pilot_file_path PilotFilepathResolver|PilotFilepathResolver[]
---@field auto_run_single_command boolean
---@field default_executor Executor

---@class Targets
---@field [string] Target

---@alias PlaceholderVar fun(): string

---@alias PlaceholderFunc fun(arg: string): string

---@class PlaceholderVars
---@field [string] PlaceholderVar

---@class PlaceholderFuncs
---@field [string] PlaceholderFunc

---@class Placeholders
---@field vars PlaceholderVars
---@field funcs PlaceholderFuncs

---@class Display
---@field numbered boolean
---@field last_entry_new_line boolean

---@class Config
---@field targets Targets
---@field write_template_to_new_pilot_file boolean
---@field executors Executors
---@field placeholders Placeholders
---@field display Display

local default_config = require("pilot.default_config")
local module = require("pilot.module")
local validate_opts = require("pilot.validate_opts")
local interpolation = require("pilot.interpolation")

local M = {
    preset_executors = default_config.preset_executors,
    utils = {
        interpolate = interpolation.interpolate,
    },
}

---@param options table?
function M.setup(options)
    M.config =
        vim.tbl_deep_extend("force", default_config.default_opts, options or {})
    validate_opts(M.config)
    module.init(M.config)
end

M.run_target = module.run

M.run_previous_task = module.run_previous_task

M.edit_pilot_file = module.edit_pilot_file

M.delete_pilot_file = module.delete_pilot_file

return M
