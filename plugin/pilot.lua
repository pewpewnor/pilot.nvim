---@class PilotSubcommand
---@field func fun(target_name: string?)
---@field takes_target boolean

local common = require("pilot.common")
local module = require("pilot.module")
local pilot = require("pilot")

---@type table<string, PilotSubcommand>
local subcommands = {
    run = { func = pilot.run_target, takes_target = true },
    prev = { func = pilot.run_previous_task, takes_target = false },
    edit = { func = pilot.edit_pilot_file, takes_target = true },
    delete = { func = pilot.delete_pilot_file, takes_target = true },
}

---@type string[]
local subcommand_names = {}
for subcommand_name in pairs(subcommands) do
    subcommand_names[#subcommand_names + 1] = subcommand_name
end
table.sort(subcommand_names)

---@param candidates string[]
---@param arg_lead string
---@return string[]
local function filter_by_prefix(candidates, arg_lead)
    local matches = {}
    for _, candidate in ipairs(candidates) do
        if candidate:sub(1, #arg_lead) == arg_lead then
            matches[#matches + 1] = candidate
        end
    end
    return matches
end

---@param arg_lead string
---@param cmd_line string
---@return string[]
local function complete(arg_lead, cmd_line)
    local words = {}
    for word in cmd_line:gmatch("%S+") do
        words[#words + 1] = word
    end

    local completing_index = #words + (arg_lead == "" and 1 or 0)
    if completing_index <= 2 then
        return filter_by_prefix(subcommand_names, arg_lead)
    end

    local subcommand = subcommands[words[2]]
    local completes_target = completing_index == 3
        and subcommand ~= nil
        and subcommand.takes_target
    if not completes_target then
        return {}
    end
    return filter_by_prefix(module.get_target_names(), arg_lead)
end

common.create_user_command("Pilot", function(opts)
    ---@type string[]
    local args = opts.fargs
    local subcommand_name = args[1]

    local subcommand = subcommands[subcommand_name]
    if not subcommand then
        error(
            string.format(
                "pilot.nvim: unknown subcommand '%s', expected one of: %s",
                subcommand_name,
                table.concat(subcommand_names, ", ")
            )
        )
    end

    if not subcommand.takes_target then
        if #args ~= 1 then
            error(
                string.format(
                    "pilot.nvim: subcommand '%s' does not take any argument",
                    subcommand_name
                )
            )
        end
        subcommand.func()
        return
    end

    if #args ~= 2 then
        error(
            string.format(
                "pilot.nvim: subcommand '%s' requires exactly one target name",
                subcommand_name
            )
        )
    end
    subcommand.func(args[2])
end, {
    nargs = "+",
    complete = complete,
    desc = "Pilot: run, prev, edit, or delete",
})
