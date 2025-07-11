# ✈️ pilot.nvim

![Neovim](https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=white&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

A Neovim plugin that allows you to **run** your **project or file** based
on the **custom JSON run configuration file** that you can edit on the go.

Usually you will have one run configuration file for each file type and project
(although, specifically for project, you can use the fallback feature instead).

_Requirement: Neovim v0.11.x_

![Preview](https://github.com/user-attachments/assets/51c88f07-a551-4ae8-a49f-5c25bc42251e)

## Motivation

I wanted a code runner plugin with placeholder interpolation so that I can hit a
single key to compile/build and run my code with full control over the commands.

## Features

- Run arbitrary commands to run, test, and debug any file or project.
- Placeholders for current file path, file name, directory name, cwd name, etc.
- You can adjust it on the fly without needing to reload Neovim every time.
- Supports fallback project run configuration so you don't have to create the
  same JSON run configuration for each project
- Unlike many other code runner plugins, it is possible to compile code and run the program.
- Customizable path/location for your project and file run configurations.
- Customizable location of command execution (presets are also provided).
- Bindable functions to run, edit, and remove your project and file type run configuration.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
    "pewpewnor/pilot.nvim",
    opts = {},
}
--or
return {
    "pewpewnor/pilot.nvim",
    config = function()
        require("pilot").setup()
    end,
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
    "pewpewnor/pilot.nvim",
    config = function()
        require("pilot").setup()
    end
}
```

### General terms

- Project run configuration -> the customizable JSON file containing your
  commands to run the current project.
- File type run configuration -> the customizable JSON file containing your
  commands to run the current file based on the file type.

## Default configuration

There is no need to pass anything to the `setup` function if you don't want to
change any of the options.

```lua
{
    project_run_config_path = nil, -- string | nil -> by default equivalent to "{{pilot_data_path}}/projects/{{hash(cwd_path)}}.json"
    file_type_run_config_path = nil, -- string | nil -> by default equivalent to "{{pilot_data_path}}/filetypes/{{file_type}}.json"
    -- if there is only one command listed, should we immediately run the command?
    automatically_run_single_command = {
        project = true, -- boolean
        file_type = true, -- boolean
    },
    fallback_project_run_config = nil, -- (function that returns a string) | nil
    custom_locations = nil, -- (key/value table with the values being strings) | nil
}
```

> [!NOTE]
> Check out the [configuration options documentation section](docs/pilot.md#configuration-options)
> to see every possible configuration option for the setup function.

## Example configuration

```lua
local pilot = require("pilot")
pilot.setup({
    -- grab the pilot configuration from the current working directory instead
    -- of automatically generating one
    project_run_config_path = "{{cwd_path}}/pilot.json",
    -- will be used instead if there is no project run configuration file
    -- at the path specified in the 'project_run_config_path' option
    fallback_project_run_config = function()
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
    -- define custom locations that can be used in any pilot run configuration
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
vim.api.nvim_create_user_command("PilotDeleteProjectRunConfig",
    pilot.delete_project_run_config, { nargs = 0, bar = false })
vim.api.nvim_create_user_command("PilotDeleteFileTypeRunConfig",
    pilot.delete_file_type_run_config, { nargs = 0, bar = false })
```

> [!NOTE]
> Check out the [function documentation section](docs/pilot.md#functions) to
> see the details of every pilot function.

## Example project run configuration

As an example, if you set your `project_run_config_path` as "{{cwd_path}}/pilot.json",
then here is what the _pilot.json_'s file content may look like.

> [!TIP]
> Use the mustache syntax like `{{cword}}` to insert a placeholder that will
> automatically be replaced by pilot.nvim on the fly!

```json
[
    {
        "name": "run specific test (cursor hover over the function name)",
        "command": "go test -v --run {{cword}}"
    },
    {
        "name": "build & run project",
        "command": "make build && make run"
    },
    {
        "command": "ls {{dir_path}}",
        "location": "tmux_new_window"
    }
]
```

## Example file type run configuration

Let's say you want to write a file type run configuration for compiling and
running any file with "c" as its Vim file type (the c programming language).

> [!TIP]
> For each entry, you don't have to specify a display name if you want it to be
> the same as the raw command string. You can also instead use a string for
> defining an entry/command.

```json
[
    {
        "name": "clang",
        "command": "clang {{file_path_relative}} && ./a.out"
    },
    "gcc {{file_path}} -o {{file_name_no_extension}} ; ./{{file_name_no_extension}}"
]
```

> [!NOTE]
> Check out the [run configuration documentation section](docs/pilot.md#run-configuration)
> to see more details about the JSON format for project and file type run
> configurations.

> [!NOTE]
> Both the project run and file type run configurations use the exact same JSON
> format.

## Placeholders

| Placeholder                  | Resolved value                                                               |
| ---------------------------- | ---------------------------------------------------------------------------- |
| `{{file_path}}`              | Current buffer's absolute file path                                          |
| `{{file_path_relative}}`     | Current buffer's file path that is relative to the current working directory |
| `{{file_name}}`              | Current buffer's file name (file extension included)                         |
| `{{file_name_no_extension}}` | Current buffer's file name without the file extension                        |
| `{{file_type}}`              | The filetype of the current buffer according to Neovim (`vim.bo.filetype`)   |
| `{{file_extension}}`         | Extension of the current file                                                |
| `{{dir_path}}`               | Absolute path of the directory that contains the current buffer              |
| `{{dir_name}}`               | Name of the directory that contains the current buffer                       |
| `{{cwd_path}}`               | Absolute path of the current working directory (`vim.fn.getcwd()`)           |
| `{{cwd_name}}`               | The directory name of the current working directory                          |
| `{{pilot_data_path}}`        | Absolute path to `vim.fn.stdpath("data") .. "/pilot"`                        |
| `{{cword}}`                  | Current word of which your cursor is hovering over                           |
| `{{cWORD}}`                  | Current complete word (between spaces) of which your cursor is hovering over |
| `{{hash(cwd_path)}}`         | Hash of the current working directory absolute path using sha256             |
| `{{hash(file_path)}}`        | Hash of the current buffer's absolute path using sha256                      |

## Preset executors

| Executor                                | Description                                                    |
| --------------------------------------- | -------------------------------------------------------------- |
| `pilot.nvim_new_tab_executor` (default) | Run the command on a new Neovim tab                            |
| `pilot.nvim_current_buffer_executor`    | Run the command on the current buffer                          |
| `pilot.nvim_split_executor`             | Run the command on a new horizontal buffer at the bottom right |
| `pilot.nvim_vsplit_executor`            | Run the command on a new vertical buffer at the right side     |
| `pilot.print_executor`                  | Run the command with the output shown using the print function |
| `pilot.silent_executor`                 | Run the command with no output displayed                       |

Simply set the `default_executor` option in your configuration to use one of the above.
You can also create your own default executor like this:

```lua
{
    default_executor = function(command)
        vim.fn.system(command)
    end
}
```

The example code above is actually the implementation of `pilot.silent_executor`.

> [!NOTE]
> There is no need to escape the command, pilot.nvim already does it for you 😉

## Recommendation

Use plugin like [telescope-ui-select.nvim](https://github.com/nvim-telescope/telescope-ui-select.nvim)
or [mini.nvim's mini-pick](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-pick.md)
which creates a nice wrapper for `vim.ui.select()` when you are selecting which command to run

### Got questions or have any ideas on how to improve this plugin?

Check out the [github discussions page](https://github.com/pewpewnor/pilot.nvim/discussions) or simply create a new issue!
