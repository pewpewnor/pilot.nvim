---@alias pilot.PilotFilepathResolver fun(): string?

---@alias pilot.Executor fun(command: string, args: string[]?)

---@class pilot.Executors
---@field [string] pilot.Executor

---@class pilot.Target
---@field pilot_file_path pilot.PilotFilepathResolver|pilot.PilotFilepathResolver[]
---@field auto_run_single_command boolean
---@field default_executor pilot.Executor

---@class pilot.Targets
---@field [string] pilot.Target

---@alias pilot.PlaceholderVar fun(): string

---@alias pilot.PlaceholderFunc fun(arg: string): string

---@class pilot.PlaceholderVars
---@field [string] pilot.PlaceholderVar

---@class pilot.PlaceholderFuncs
---@field [string] pilot.PlaceholderFunc

---@class pilot.Placeholders
---@field vars pilot.PlaceholderVars
---@field funcs pilot.PlaceholderFuncs

---@class pilot.Display
---@field numbered boolean
---@field last_entry_new_line boolean

---@class pilot.Config
---@field targets pilot.Targets
---@field write_template_to_new_pilot_file boolean
---@field executors pilot.Executors
---@field placeholders pilot.Placeholders
---@field display pilot.Display

---@class pilot.TargetOptions
---@field pilot_file_path? pilot.PilotFilepathResolver|pilot.PilotFilepathResolver[]
---@field auto_run_single_command? boolean
---@field default_executor? pilot.Executor

---@class pilot.PlaceholderOptions
---@field vars? pilot.PlaceholderVars
---@field funcs? pilot.PlaceholderFuncs

---@class pilot.DisplayOptions
---@field numbered? boolean
---@field last_entry_new_line? boolean

---@class pilot.ConfigOptions
---@field targets? table<string, pilot.TargetOptions>
---@field write_template_to_new_pilot_file? boolean
---@field executors? pilot.Executors
---@field placeholders? pilot.PlaceholderOptions
---@field display? pilot.DisplayOptions

---@class pilot.MinimumTarget
---@field pilot_file_path pilot.PilotFilepathResolver|pilot.PilotFilepathResolver[]

---@class pilot.RawEntryTable
---@field name string?
---@field cmd string|string[]|nil
---@field command string|string[]|nil
---@field import string?
---@field executor string?

---@alias pilot.RawEntry pilot.RawEntryTable|string

---@class pilot.ProcessedEntry
---@field name string
---@field command string
---@field executor string?

---@class pilot.ProcessedTarget
---@field name string
---@field path string
---@field auto_run_single_command boolean
---@field default_executor pilot.Executor

---@class pilot.Task
---@field command string
---@field executor pilot.Executor
---@field args string[]

---@class pilot.PilotSubcommand
---@field func fun(target_name: string?)
---@field takes_target boolean
