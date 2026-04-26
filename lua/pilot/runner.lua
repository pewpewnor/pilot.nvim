---@class ProcessedTarget
---@field name string
---@field path string
---@field auto_run_single_command boolean
---@field default_executor Executor

---@class Task
---@field command string
---@field executor Executor
---@field args string[]

local common = require("pilot.common")
local parser = require("pilot.parser")
local interpolation = require("pilot.interpolation")

local M = {}

---@param config Config
function M.init(config)
    M.config = config
end

---@type Task|nil
M.last_executed_task = nil

---@param task Task
local function execute_task(task)
    task.executor(interpolation.interpolate(task.command), task.args)
end

---@param entry ProcessedEntry
---@param default_executor Executor
local function run_entry(entry, default_executor)
    local executor
    local args = {}
    if not entry.executor then
        executor = default_executor
    else
        for arg in entry.executor:gmatch("%S+") do
            table.insert(args, arg)
        end

        local executor_name = table.remove(args, 1)
        executor = M.config.executors[executor_name]
        if not executor then
            error(
                string.format(
                    "pilot.nvim: executor '%s' not found in configuration",
                    entry.executor
                )
            )
        end
    end

    M.last_executed_task = {
        command = entry.command,
        executor = executor,
        args = args,
    }
    execute_task(M.last_executed_task)
end

---@param target ProcessedTarget
function M.select_and_run_entry(target)
    local entries = parser.parse_pilot_file(target.path, target.name)
    if not entries then
        return
    end

    if #entries == 0 then
        print(
            string.format(
                "pilot.nvim: no entries in the pilot file for '%s'",
                target.name
            )
        )
        return
    end

    if #entries == 1 and target.auto_run_single_command then
        return run_entry(entries[1], target.default_executor)
    end

    if M.config.display.numbered then
        for i, entry in ipairs(entries) do
            entries[i].name = i .. ". " .. entry.name
        end
    end
    if M.config.display.last_entry_new_line then
        entries[#entries].name = entries[#entries].name .. "\n"
    end
    common.ui_select(entries, {
        prompt = string.format("Run a '%s' command", target.name),
        format_item = function(entry)
            return entry.name
        end,
    }, function(chosen_entry)
        -- chosen_entry = nil means the user closed the selector ui
        if chosen_entry then
            return run_entry(chosen_entry, target.default_executor)
        end
    end)

    -- vim.ui.select runs parallel, so this function will immediately return nil??
end

function M.run_previous_task()
    if not M.last_executed_task then
        print("pilot.nvim: no previously executed task")
        return
    end
    execute_task(M.last_executed_task)
end

return M
