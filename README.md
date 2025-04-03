# ✈️ pilot.nvim

![Neovim](https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=white&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

A Neovim plugin that allows you to **execute** your **project or file** based
on the **custom run configuration file** (JSON) that you wrote yourself.

## Features

- Run/execute a file or a project.
- Location of command execution can be picked and customized to your heart's
  content (not just Neovim's integrated terminal).
- Edit or remove your current project and file type run config file.
- Highly customizable path/location for your project and file type run configs.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- init.lua:
{ "pewpewnor/pilot.nvim", opts = {} }

-- plugins/pilot.lua:
return {
    "pewpewnor/pilot.nvim",
    opts = {}
}
--or
return {
    "pewpewnor/pilot.nvim",
    config = function()
        require("pilot").setup()
    end
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use { "catppuccin/nvim", as = "catppuccin" }
```

### General terms

- project run config -> the customizable JSON file containing your commands to
  run the current project.
- file type run config -> the customizable JSON file containing your commands to
  run the current file based on the file type.

## Default configuration

There is no need to pass anything to the `setup` function if you don't want to
change any of the options.

```lua
{
    project_run_config_path = nil, -- must be a string | nil
    file_type_run_config_path = nil, -- must be a string | nil
    automatically_run_single_command = {
        project = true, -- must be a boolean
        file_type = true, -- must be a boolean
    },
    fallback_project_run_config = nil, -- must be a (function that returns a string) | nil
    custom_locations = nil, -- must be a (key/value table with the values being strings) | nil
}
```

> [!NOTE]
> Check out the [configurations documentation section](docs/pilot.md#configurations)
> to see every possible configuration options for the setup function.

## Example configuration

```lua
local pilot = require("pilot")
pilot.setup({
    -- grab the pilot configuration from the current working directory instead
    -- of automatically generating one
    project_run_config_path = "{{cwd_path}}/pilot.json",
    -- will be used instead if there is no project run config file
    -- at the path specified in the 'project_run_config_path' option
    fallback_project_run_config = function()
        -- you can customize this logic
        -- e.g. if the project has 'package-lock.json', then use our
        -- 'npm_project.json' as the project run config
        if vim.fn.filereadable(vim.fn.getcwd() .. "/package-lock.json") == 1 then
            return  "{{pilot_data_path}}/npm_project.json"
        -- e.g. if the project has CMakeLists.txt, then we will use our
        -- 'cmake_project.json' as our project run config
        elseif vim.fn.filereadable(vim.fn.getcwd() .. "/CMakeLists.txt") == 1 then
            return "{{pilot_data_path}}/cmake_project.json"
        end
    end,
    -- define custom locations that can be used in any pilot run config
    custom_locations = {
        -- custom location that executes the command in a new tmux window
        tmux_new_window = function(command)
            vim.fn.system("tmux new-window -d")
            vim.fn.system("tmux send-keys -t +. '" .. command .. "' Enter")
        end,
    },
})

-- customize these keybindings to your liking
vim.keymap.set("n", "<Leader>xp", pilot.run_project)
vim.keymap.set("n", "<Leader>xf", pilot.run_file_type)
vim.keymap.set("n", "<Leader>xl", pilot.run_last_executed_task)
vim.keymap.set("n", "<Leader>ep", pilot.edit_project_run_config)
vim.keymap.set("n", "<Leader>ef", pilot.edit_file_type_run_config)

-- example of creating vim user commands for pilot functions
vim.api.nvim_create_user_command("PilotDeleteProjectRunConfig", pilot.delete_project_run_config, { nargs = 0, bar = false })
vim.api.nvim_create_user_command("PilotDeleteFileTypeRunConfig", pilot.delete_file_type_run_config, { nargs = 0, bar = false })
```

> [!NOTE]
> Check out the [functions documentation section](docs/pilot.md#functions) to see
> the details of every pilot functions.

## Example project run config

> [!NOTE]
> The project run config and the file type run config use the exact same JSON
> format.

As an example, if you set your `project_run_config_path` as
"{{cwd_path}}/pilot.json", then here is what the _pilot.json_'s file content may
look like.

> [!TIP]
> For each entry, you don't have to specify a display name. You can also instead
> use astring for defining an entry/command.

```json
[
    {
        "name": "build & run project with Makefile",
        "command": "make build && make run"
    },
    {
        "name": "run script for unit testing",
        "command": "./test.sh"
    }
]
```

## Example file type run config

Let's say you want to write a file type run config for compiling and running any
file that has "c" as the vim file type (the c programming language).

> [!TIP]
> Use the mustache syntax to define placeholders that will be automatically
> replaced by pilot.nvim on the fly!

```json
[
    "gcc {{file_path}} -o {{file_name_no_extension}} && ./{{file_name_no_extension}}",
    {
        "command": "clang {{file_path_relative}} ; ./a.out"
    }
]
```

> [!NOTE]
> Check out the [run config documentation section](docs/pilot.md#run-config) to
> see the JSON format for project and file type run configs even further.

### Got questions or have any ideas on how to improve this plugin?

Check out our [github discussions page](https://github.com/pewpewnor/pilot.nvim/discussions)
or simply create a new pull request!
