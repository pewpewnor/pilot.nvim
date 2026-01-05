---@class Task
---@field command string
---@field executor Executor
---@field args [string]

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
---@param run_classification RunClassification
local function run_entry(entry, run_classification)
    local executor
    local args = {}
    if not entry.executor then
        if run_classification == "file type" then
            executor = M.config.default_executor.file_type
        else
            executor = M.config.default_executor.project
        end
    else
        for arg in entry.executor:gmatch("%S+") do
            table.insert(args, arg)
        end

        local executor_name = table.remove(args, 1)
        executor = M.config.executors[executor_name]
        if not executor then
            error(
                string.format(
                    "[Pilot] Attempted to retrieve executor '%s' from your configuration, but got nil instead.",
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

---@param run_config_path string
---@param run_classification RunClassification
function M.select_and_run_entry(run_config_path, run_classification)
    local entries = parser.parse_run_config(run_config_path, run_classification)
    if not entries then
        return
    end

    if
        #entries == 1
        and (
            run_classification == "project"
                and M.config.automatically_run_single_command.project
            or run_classification == "file type"
                and M.config.automatically_run_single_command.file_type
        )
    then
        run_entry(entries[1], run_classification)
    else
        for i, entry in ipairs(entries) do
            entries[i].name = i .. ". " .. entry.name
        end
        vim.ui.select(entries, {
            prompt = "Run a command for this "
                .. run_classification
                .. (
                    run_classification == "file type"
                        and " (" .. vim.bo.filetype .. ")"
                    or ""
                ),
            format_item = function(entry)
                return entry.name
            end,
        }, function(chosen_entry)
            if chosen_entry then
                run_entry(chosen_entry, run_classification)
            end
        end)
    end
end

function M.run_previous_task()
    if not M.last_executed_task then
        print("[Pilot] No previously executed task.")
        return
    end
    execute_task(M.last_executed_task)
end

return M
