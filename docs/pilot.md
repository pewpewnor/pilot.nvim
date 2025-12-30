<br />

A Neovim plugin that allows you to **run** your **project or file** based on a
**JSON run configuration file** with placeholder support and customizable execution
locations. You can edit configurations on the fly, and the plugin supports advanced
features like fallback configs, custom executors, and more.

This plugin requires Neovim v0.11.0 at the minimum. We always strive to use the latest Neovim major release version.

The source code for this plugin is available in the [GitHub Repository](https://github.com/pewpewnor/pilot.nvim).

---

## Motivation

I wanted a code runner plugin that supports placeholder interpolation, allowing me to use a single keystroke to compile, build, and run my code at the same time, whilst still having full control over the commands.

---

## Features

- **Run arbitrary commands** for any file or project, with full control over execution.
- **Placeholder interpolation** for file paths, names, directories, and more.
- **On-the-fly configuration editing**: No need to reload Neovim after changes.
- **Fallback project run configuration**: Use a default config if none is found for a project.
- **Customizable config file locations**: Store configs wherever you want.
- **Customizable execution location**: Run commands in new tabs, splits, vsplits, background jobs, or your own custom locations.
- **Custom executors**: Define your own ways to run commands, including integration with tools like tmux.
- **UI selection**: If multiple commands are available, select which to run via `vim.ui.select`.
- **Automatic single-command execution**: Optionally auto-run if only one command is available.
- **Purge/delete config files**: Easily remove or reset run configurations.
- **Import other config files**: Use `"import"` in your JSON to include commands from other files.
- **JSON validation and helpful errors**: Clear error messages for misconfigured files.
- **Template writing**: Optionally auto-generate a template when creating a new config file.
- **Full Lua API**: All features are accessible programmatically.

---

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
    "pewpewnor/pilot.nvim",
    opts = {},
}
-- or
return {
    "pewpewnor/pilot.nvim",
    config = function()
        require("pilot").setup()
    end,
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
    "pewpewnor/pilot.nvim",
    config = function()
        require("pilot").setup()
    end
}
```

---

## General Terms

- **Project run configuration**: JSON file containing commands to run for the current project.
- **File type run configuration**: JSON file containing commands to run for the current file type.

---

## Default Configuration

You do not need to pass anything to `setup()` if you want the defaults.

```lua
{
    project_run_config_path = nil, -- string | [string] | nil (nil = "{{pilot_data_path}}/projects/{{hash(cwd_path)}}.json")
    file_type_run_config_path = nil, -- string | nil (nil = "{{pilot_data_path}}/filetypes/{{file_type}}.json")
    automatically_run_single_command = {
        project = true, -- boolean
        file_type = true, -- boolean
    },
    fallback_project_run_config = nil, -- function() -> string | nil
    write_template_to_new_run_config = true, -- boolean
    default_executor = {
        project = nil, -- function(string) -> string | nil (nil = pilot.executors.new_tab)
        file_type = nil, -- function(string) -> string | nil (nil = pilot.executors.new_tab)
    },
    custom_locations = {}, -- table<string, function(command: string, args: string[])>
}
```

---

## Configuration Options

### `project_run_config_path`

- **Type:** `string | string[] | nil`
- **Default:** `nil` (internally resolves to `{{pilot_data_path}}/projects/{{hash(cwd_path)}}.json`)
- **Description:**  
  Path or list of paths to the project run configuration file(s).  
  If a list, the first readable file is used.  
  Supports placeholders (see [Placeholders](#placeholders)).
- **Example:**  
  `"{{cwd_path}}/pilot.json"`  
  `{ "{{cwd_path}}/pilot.json", "{{cwd_path}}/.pilot.json" }`

### `file_type_run_config_path`

- **Type:** `string | nil`
- **Default:** `nil` (internally resolves to `{{pilot_data_path}}/filetypes/{{file_type}}.json`)
- **Description:**
  Path to the file type run configuration file.  
  Supports placeholders.

### `automatically_run_single_command.project`

- **Type:** `boolean`
- **Default:** `true`
- **Description:**
  If only one command is found in the project run config, run it immediately without prompting the user.

### `automatically_run_single_command.file_type`

- **Type:** `boolean`
- **Default:** `true`
- **Description:**
  If only one command is found in the filetype run config, run it immediately without prompting the user.

### `fallback_project_run_config`

- **Type:** `function() -> string | nil`
- **Default:** `nil`
- **Description:**
  Function returning a path to a fallback config file if the main one is missing.  
  Useful for providing a default config for certain project types.

### `write_template_to_new_run_config`

- **Type:** `boolean`
- **Default:** `true`
- **Description:**
  If true, writes a JSON template when creating a new config file (when editing a config that does not exist).

### `default_executor.project`

- **Type:** `function(command: string) -> string`
- **Default:** `nil` (internally resolves to `pilot.executors.new_tab`)
- **Description:**
  The default executor function used to run commands which have no specified `custom_location` in the project run config.  
  See [Preset Executors](#preset-executors) for available executors and their signatures.

### `default_executor.file_type`

- **Type:** `function(command: string) -> string`
- **Default:** `nil` (internally resolves to `pilot.executors.new_tab`)
- **Description:**
  The default executor function used to run commands which have no specified `custom_location` in the filetype run config.  
  See [Preset Executors](#preset-executors) for available executors and their signatures.

### `custom_locations`

- **Type:** `table<string, function(command: string, args: string[])>`
- **Default:** `{}`
- **Description:**  
  Table mapping location names to executor functions.  
  Used when a run config entry specifies a `"location"` field.  
  The executor function receives two arguments:
    - `command` (string): The shell command to run (with placeholders already expanded).
    - `args` (list of string): The whole string that was written in the `custom_location` field split with whitespaces as the seperator and without the location name (first argument) inside the list.

---

## Example Configuration

```lua
local pilot = require("pilot")
pilot.setup({
    project_run_config_path = "{{cwd_path}}/pilot.json",
    fallback_project_run_config = function()
        if vim.fn.filereadable(vim.fn.getcwd() .. "/package-lock.json") == 1 then
            return "{{pilot_data_path}}/npm_project.json"
        elseif vim.fn.filereadable(vim.fn.getcwd() .. "/CMakeLists.txt") == 1 then
            return "/home/user/templates/cmake_project.json"
        end
    end,
    default_executor = {
        file_type = pilot.executors.split,
    },
    custom_locations = {
        tmux_new_window = function(command, args)
            vim.fn.system("tmux new-window -d")
            vim.fn.system("tmux send-keys -t +. '" .. command .. "' Enter")
        end,
        vsplit = pilot.executors.vsplit,
    },
    write_template_to_new_run_config = false,
})

vim.keymap.set("n", "<F10>", pilot.run_project)
vim.keymap.set("n", "<F12>", pilot.run_file_type)
vim.keymap.set("n", "<F11>", pilot.run_previous_task)
vim.keymap.set("n", "<Leader><F10>", pilot.edit_project_run_config)
vim.keymap.set("n", "<Leader><F12>", pilot.edit_file_type_run_config)

vim.api.nvim_create_user_command("PilotDeleteProjectRunConfig",
    pilot.delete_project_run_config, { nargs = 0, bar = false })
vim.api.nvim_create_user_command("PilotDeleteFileTypeRunConfig",
    pilot.delete_file_type_run_config, { nargs = 0, bar = false })
```

---

## Run Configuration Format

Both project and file type run configurations use the same JSON format: an array of entries.

Each entry can be:

- A **string** (the command to run)
- An **object** with fields:
    - `name` (optional): Display name for the command.
    - `command`: String or array of strings (joined with `&&`).
    - `location` (optional): Name of a custom location/executor (see [custom_locations](#custom_locations)).
    - `import` (optional): Path to another JSON file to import entries from.  
      Imported entries are merged in place.

---

## Example Project Run Configuration

```json
[
    {
        "name": "build & run project",
        "command": "make build && make run"
    },
    {
        "name": "run hovered test function name",
        "command": "go test -v --run {{cword}}"
    },
    {
        "command": ["ls {{dir_path}}", "touch 'hello world.txt'"],
        "location": "tmux_new_window"
    },
    "echo Hello, World!"
]
```

> **Tip:**  
> Use the mustache syntax like `{{cword}}` to insert a placeholder that will
> automatically be replaced by pilot.nvim on the fly!

---

## Example File Type Run Configuration

Let's say you want to write a file type run configuration for compiling and
running C source code files.

```json
[
    {
        "name": "clang",
        "command": "clang {{file_path_relative}} && ./a.out"
    },
    "gcc {{file_path}} -o {{file_name_no_extension}} ; ./{{file_name_no_extension}}"
]
```

> **Tip:**  
> For each entry, you don't have to specify a display name if you want it to be
> the same as the raw command string. You can also instead use a string for
> defining an entry/command.

**Importing/Including Existing Run Configuration:**

```json
[{ "import": "{{pilot_data_path}}/common_commands.json" }]
```

---

## Placeholders

All placeholders are expanded in config paths and commands.  
You can escape a placeholder by using triple braces, e.g. `{{{not_a_placeholder}}}`.

| Placeholder                  | Resolved value                                      |
| ---------------------------- | --------------------------------------------------- |
| `{{file_path}}`              | Current buffer's absolute file path                 |
| `{{file_path_relative}}`     | File path relative to current working directory     |
| `{{file_name}}`              | File name (with extension)                          |
| `{{file_name_no_extension}}` | File name without extension                         |
| `{{file_type}}`              | Filetype of current buffer (`vim.bo.filetype`)      |
| `{{file_extension}}`         | File extension                                      |
| `{{dir_path}}`               | Directory containing the current buffer             |
| `{{dir_name}}`               | Name of the directory containing the current buffer |
| `{{cwd_path}}`               | Absolute path of the current working directory      |
| `{{cwd_name}}`               | Name of the current working directory               |
| `{{pilot_data_path}}`        | Path to `vim.fn.stdpath("data") .. "/pilot"`        |
| `{{cword}}`                  | Word under the cursor                               |
| `{{cWORD}}`                  | WORD under the cursor                               |
| `{{hash(cwd_path)}}`         | SHA256 hash of the current working directory path   |
| `{{hash(file_path)}}`        | SHA256 hash of the current buffer's absolute path   |

---

## Preset Executors

Executors are functions that run the command in a specific way.  
All executors receive two arguments:

- `command` (string): The shell command to run (with placeholders already expanded).
- `args` (table): List of arguments (see [custom_locations](#custom_locations)).

### Built-in Executors

| Executor                                 | Description                                                                     |
| ---------------------------------------- | ------------------------------------------------------------------------------- | ------------- |
| `pilot.executors.new_tab` (default)      | Run the command in a new Neovim tab. Uses `:tabnew                              | term <cmd>`.  |
| `pilot.executors.current_buffer`         | Run the command in the current buffer (replaces buffer with terminal).          |
| `pilot.executors.split`                  | Run the command in a new horizontal split (`:split                              | term <cmd>`). |
| `pilot.executors.vsplit`                 | Run the command in a new vertical split (`:vsplit                               | term <cmd>`). |
| `pilot.executors.print`                  | Run the command and print output to a message (blocking, uses `vim.fn.system`). |
| `pilot.executors.silent`                 | Run the command silently (blocking, no output shown).                           |
| `pilot.executors.background_silent`      | Run the command as a background job (no output, uses `vim.fn.jobstart`).        |
| `pilot.executors.background_exit_status` | Run as background job, print exit status on completion.                         |

### Custom Executors

You can define your own executor functions and add them to `custom_locations`.  
The executor function signature is:

```lua
function(command: string, args: string[])
    -- implementation
end
```

**Example:**

```lua
custom_locations = {
    tmux_new_window = function(command, args)
        vim.fn.system("tmux new-window -d")
        vim.fn.system("tmux send-keys -t +. '" .. command .. "' Enter")
    end,
    vsplit = require("pilot").executors.vsplit,
}
```

---

## Functions

All functions are available via `require("pilot")`.

| Function Name                                  | Description                                                                                    |
| ---------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| `setup(options)`                               | Configure pilot.nvim. See [Configuration Options (Detailed)](#configuration-options-detailed). |
| `run_project()`                                | Run a project command (from project run config). Prompts if multiple commands.                 |
| `run_file_type()`                              | Run a file type command (from file type run config). Prompts if multiple commands.             |
| `run_previous_task()`                          | Re-run the last executed task (project or file type).                                          |
| `edit_project_run_config()`                    | Open the project run config for editing (creates template if missing).                         |
| `edit_file_type_run_config()`                  | Open the file type run config for editing (creates template if missing).                       |
| `delete_project_run_config()`                  | Delete the current project run config file.                                                    |
| `delete_file_type_run_config()`                | Delete the current file type run config file.                                                  |
| `purge_all_default_project_run_config_dir()`   | Delete all default project run config files (in `{{pilot_data_path}}/projects`).               |
| `purge_all_default_file_type_run_config_dir()` | Delete all default file type run config files (in `{{pilot_data_path}}/filetypes`).            |

---

## Tips & Recommendations

- Use [telescope-ui-select.nvim](https://github.com/nvim-telescope/telescope-ui-select.nvim) or [mini.nvim's mini-pick](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-pick.md) for a better `vim.ui.select()` experience.
- You can import common commands into multiple configs using the `"import"` key.
- Placeholders can be escaped by using extra braces, e.g. `{{{not_a_placeholder}}}`.
- If you want to always use a specific executor for a certain location, add it to `custom_locations` and reference it by name in your config.
- To disable template writing for new configs, set `write_template_to_new_run_config = false`.
- All config files are validated on load; errors are shown in the command line.

---

## Links

- [GitHub Discussions](https://github.com/pewpewnor/pilot.nvim/discussions)
- [telescope-ui-select.nvim](https://github.com/nvim-telescope/telescope-ui-select.nvim)
- [mini.nvim's mini-pick](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-pick.md)
- [Neovim](https://neovim.io/)
- [Lua](https://www.lua.org/)

---

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

---

## FAQ

**Q: How do I add a new executor?**  
A: Add a function to `custom_locations` in your config and reference its key in your run config's `"location"`.

**Q: How do I use placeholders in config paths?**  
A: All config paths support placeholders like `{{cwd_path}}`, `{{file_type}}`, etc.

**Q: What happens if my config file is missing or invalid?**  
A: For project configs, the fallback function is used if provided. For file type configs, a message is printed and nothing runs.

**Q: Can I use arrays for the `command` field?**  
A: Yes, arrays are joined with `&&` to form a single shell command.

**Q: What is passed to custom executors?**  
A: Both the expanded command string and an `arg` string (see [Preset Executors](#preset-executors)).

---
