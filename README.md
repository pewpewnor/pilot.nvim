# pilot.nvim

![Neovim](https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=white&style=for-the-badge)
![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)

A Neovim plugin that allows you to execute your project or file based on the custom run configuration that you wrote yourself.

## Features

- Run/execute a file or a project.
- Location of execution can be picked and customized as you wish.
- Edit or remove your current project and file type run config file.

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

## Configuration

These are the default configuration options.
> [!NOTE]
> There is no need to pass anything to the `setup` function if you don't want to change any of the options.

```lua
require("pilot").setup({
    local_project_config_dir = nil, -- must be a string | nil
    automatically_run_single_command = {
        project = true, -- must be a boolean
        file_type = true, -- must be a boolean
    },
    fallback_project_run_config = nil, -- must be a (function that returns a string) | nil
    custom_locations = nil, -- must be a (table with the values in the key/value pair being strings) | nil
})
```

## Usage

| Module                        | Description                                                       | Details               |
|-------------------------------|-------------------------------------------------------------------|-----------------------|
| PilotRemoveProjectRunConfig   | Remove the current project run config file from the file system   | Uses the `rm` command |
| PilotRemoveFileTypeRunConfig  | Remove the current file type run config file from the file system | Uses the `rm` command |

### Got questions or have any ideas on how to improve this plugin?

Check out our [github discussions page](https://github.com/pewpewnor/pilot.nvim/discussions)!

### Contributing

- You can also create a github issue or start a github discussion in order to propose a feature.
- You can create pull requests immediately to fix a bug or add new a feature.
- Please reference the issue in the PR if the PR is related to an issue.
- Try to use the following commit message format if you can:
  - `fix: commit message` for fixes.
  - `feat: commit message` for new features.
  - `docs: commit message` for adding or updating the documentation.
  - `chore: commit message` for anything else.
