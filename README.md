# ✈️ pilot.nvim

![Neovim](https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=white&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

**pilot.nvim** is a Neovim plugin that lets you run, build, or test your project or file using a simple, editable JSON configuration.  
It supports powerful placeholders, custom executors, and lets you edit or reload configs on the fly without needing to reload Neovim everytime.

_Requirement: Neovim v0.11.x_

![preview](https://github.com/user-attachments/assets/51c88f07-a551-4ae8-a49f-5c25bc42251e)

---

## Table of Important Contents

- [Installation](#installation)
- [Default configuration values](#default-configuration-values)
- [Example configuration](#example-configuration)
- [Run configuration format](#run-configuration-format)
- [Example project run configuration](#example-project-run-configuration)
- [Example file type run configuration](#example-file-type-run-configuration)
- [Placeholders](#placeholders)
- [Preset executors](#preset-executors)

---

## Motivation

I wanted a code runner plugin that supports placeholder interpolation, allowing me to use a single keystroke to compile, build, and run my code at the same time, whilst still having full control over the commands.

---

## Features

- Run arbitrary commands for any file or project, with full control over execution.
- Powerful placeholders for file paths, names, directories, and more.
- Edit configuration files on the fly without needing to reload Neovim everytime.
- Fallback project run configuration: use a default config if none is found for a project.
- Customizable run configuration file to define how it will be executed and the execution locations (tabs, splits, background jobs, custom location, etc).
- Much more other features such as importing/including other run configuration files.

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

## Default Configuration Values

You do not need to pass anything to `setup()` if you want the defaults.

```lua
{
    run_config_path = {
        project = vim.fs.joinpath("{{pilot_data_path}}", "projects", "{{hash_sha256(cwd_path)}}.json"), -- string | string[]
        file_type = vim.fs.joinpath("{{pilot_data_path}}", "filetypes", "{{file_type}}.json"), -- string
        fallback_project = nil, -- (function() -> string) | nil
    },
    auto_run_single_command = {
        project = true, -- boolean
        file_type = true, -- boolean
    },
    write_template_to_new_run_config = true, -- boolean
    default_executor = {
        project = pilot.preset_executors.new_tab, -- function(command: string)
        file_type = pilot.preset_executors.new_tab, -- function(command: string)
    },
    executors = {
        -- (filled with all preset executors, e.g. new_tab, split, vsplit)
    }, -- table<string, function(command: string, args: string[])>
    placeholders = {
        vars = {
            -- (filled with all preset placeholder vars, e.g. file_name, cwd_path)
        }, -- table<string, function(): string>
        funcs = {
            -- (filled with all preset placeholder funcs, e.g. hash_sha256)
        }, -- table<string, function(arg: string): string>
    },
}
```

> **See:** [full configuration options](docs/pilot.md#configuration-options)

---

## Example Configuration

This is a full example to see how the plugin can be configured.

```lua
local pilot = require("pilot")
pilot.setup({
    run_config_path = {
        -- grab the pilot configuration from the current working directory instead
        -- of automatically generating one
        project = "{{cwd_path}}/pilot.json",
        -- will be used instead if there is no project run configuration file
        -- at the path specified in the 'project_run_config_path' option
        fallback_project = function()
            -- you can customize this logic
            -- e.g. if the project has 'package-lock.json', then use our
            -- 'npm_project.json' as the project run configuration
            if vim.fn.filereadable(vim.fn.getcwd() .. "/package-lock.json") == 1 then
                return  "{{pilot_data_path}}/npm_project.json"
            -- e.g. if the project has CMakeLists.txt, then we will use our
            -- 'cmake_project.json' as our project run configuration
            elseif vim.fn.filereadable(vim.fn.getcwd() .. "/CMakeLists.txt") == 1 then
                return "/home/user/templates/cmake_project.json"
            end
        end,
    },
    write_template_to_new_run_config = false, -- disable json template that is written everytime for new run configs
    default_executor = {
        -- change so that by default, we execute the file on a new bottom buffer
        file_type = pilot.preset_executors.split,
    },
    -- define custom executors that can be used in any pilot run configuration
    executors = {
        -- custom executor that executes the command in a new tmux window
        tmux_new_window = function(command)
            vim.fn.system("tmux new-window -d")
            vim.fn.system("tmux send-keys -t +. '" .. command .. "' Enter")
        end,
        background = pilot.preset_executors.background_exit_status,
    },
    placeholders = {
        vars = {
            -- example to add custom placeholders
            new_temp_file = function() return vim.fn.tempname() end,
            template_path = function() return pilot.utils.interpolate("{{pilot_data_path}}/templates") end,
        },
    },
})

-- customize these keybindings to your liking
vim.keymap.set("n", "<F10>", pilot.run_project)
vim.keymap.set("n", "<F12>", pilot.run_file_type)
vim.keymap.set("n", "<F11>", pilot.run_previous_task)
vim.keymap.set("n", "<Leader><F10>", pilot.edit_project_run_config)
vim.keymap.set("n", "<Leader><F12>", pilot.edit_file_type_run_config)

-- example of creating vim user commands for pilot functions
vim.api.nvim_create_user_command("PilotDeleteProjectRunConfig",
    pilot.delete_project_run_config, { nargs = 0, bar = false })
vim.api.nvim_create_user_command("PilotDeleteFileTypeRunConfig",
    pilot.delete_file_type_run_config, { nargs = 0, bar = false })
```

> **See:** [functions documentation](docs/pilot.md#functions) for all available functions.

---

## Run Configuration Format

Both project and file type run configurations use the same JSON format: an array of entries.

Each entry can be:

- A **string** (the command to run)
- An **object** with fields:
    - `name` (optional): Display name for the command.
    - `command` (required): String or array of strings.
    - `executor` (optional): Name of an executor that exists in the `executors` configuration field.
    - `import` (optional): Path to another JSON file to import entries from.

---

## Example Project Run Configuration

Here is an example list of commands w/ placeholders which can be executed in the current
working directory.

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
    "echo Hello, World!",
    {
        "command": ["ls {{dir_path}}", "touch 'hello world.txt'"],
        "executor": "tmux_new_window"
    }
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
    "gcc {{file_path}} -o {{file_name_no_extension}} ; ./{{file_name_no_extension}}",
    {
        "name": "clang",
        "command": "clang {{file_path_relative}} && ./a.out"
    }
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

**Variables**

| Placeholder                  | Resolved value                                                               |
| ---------------------------- | ---------------------------------------------------------------------------- |
| `{{file_path}}`              | Current buffer's absolute file path                                          |
| `{{file_path_relative}}`     | Current buffer's file path relative to current working directory             |
| `{{file_name}}`              | Current buffer's file name (file extension included)                         |
| `{{file_name_no_extension}}` | Current buffer's file name without the file extension                        |
| `{{file_type}}`              | The Neovim file type of the current buffer (`vim.bo.filetype`)               |
| `{{file_extension}}`         | File extension of current buffer's file name                                 |
| `{{dir_path}}`               | Absolute path of the directory containing the current buffer                 |
| `{{dir_name}}`               | Name of the directory containing the current buffer                          |
| `{{cwd_path}}`               | Absolute path of the current working directory                               |
| `{{cwd_name}}`               | Directory name of the current working directory                              |
| `{{config_path}}`            | Absolute path to your Neovim configuration directory                         |
| `{{data_path}}`              | Absolute path to Neovim plugins data directory                               |
| `{{pilot_data_path}}`        | Absolute path to the pilot directory inside of Neovim plugins data directory |
| `{{cword}}`                  | Word under the cursor                                                        |
| `{{cWORD}}`                  | Complete word (between spaces) under the cursor                              |

**Functions**

| Placeholder            | Description / usage                                                            |
| ---------------------- | ------------------------------------------------------------------------------ |
| `{{hash_sha256(...)}}` | SHA256 hash of the supplied path or string (e.g. `{{hash_sha256(cwd_path)}}`). |

---

## Preset Executors

| Executor                                        | Description                                                               |
| ----------------------------------------------- | ------------------------------------------------------------------------- |
| `pilot.preset_executors.new_tab` _(default)_    | Run the command in a new tab                                              |
| `pilot.preset_executors.current_buffer`         | Run the command in the current buffer                                     |
| `pilot.preset_executors.split`                  | Run the command in a new horizontal split                                 |
| `pilot.preset_executors.vsplit`                 | Run the command in a new vertical split                                   |
| `pilot.preset_executors.print`                  | Run the command and print output (blocking)                               |
| `pilot.preset_executors.silent`                 | Run the command silently with no output (blocking)                        |
| `pilot.preset_executors.background_silent`      | Run the command as a background job silently                              |
| `pilot.preset_executors.background_exit_status` | Run the command as a background job and print exit status upon completion |

You can also create your own executor and use it in your config for pilot.nvim.

---

## Tips & Recommendations

- Use [telescope-ui-select.nvim](https://github.com/nvim-telescope/telescope-ui-select.nvim) or [mini.nvim's mini-pick](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-pick.md) for a better `vim.ui.select()` experience.
- You can import common commands into multiple configs using the `"import"` key.
- Placeholders can be escaped by using triple braces, e.g. `{{{not_a_placeholder}}}`.
- If you want to always use a specific executor, add it to `executors` and reference it by name in your config.
- To disable template writing for new configs, set `write_template_to_new_run_config = false`.
- All config files are validated on load; errors are shown in the command line.

---

## Links

- [Full documentation and advanced usage](docs/pilot.md)
- [GitHub discussions](https://github.com/pewpewnor/pilot.nvim/discussions)
- [telescope-ui-select.nvim](https://github.com/nvim-telescope/telescope-ui-select.nvim)
- [mini.nvim's mini-pick](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-pick.md)
- [Neovim](https://neovim.io/)
- [Lua](https://www.lua.org/)

---

## Have any questions or ideas?

- Create a new [issue](https://github.com/pewpewnor/pilot.nvim/issues)
- See the [contribution guidelines](CONTRIBUTING.md) for creating pull requests
- Open a [discussion](https://github.com/pewpewnor/pilot.nvim/discussions)
- See the [FAQ](docs/pilot.md#faq)
