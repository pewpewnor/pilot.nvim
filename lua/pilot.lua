local common = require("pilot.common")
local default_config = require("pilot.default_config")
local interpolation = require("pilot.interpolation")
local module = require("pilot.module")
local validate_opts = require("pilot.validate_opts")

local M = {
    preset_executors = default_config.preset_executors,
    utils = {
        interpolate = interpolation.interpolate,
    },
}

---@param options table?
function M.setup(options)
    config = common.tbl_deep_extend(
        "force",
        default_config.default_opts,
        options or {}
    )
    validate_opts(config)
    module.init(config)
end

M.run_target = module.run_target

M.run_previous_task = module.run_previous_task

M.edit_pilot_file = module.edit_pilot_file

M.delete_pilot_file = module.delete_pilot_file

return M
