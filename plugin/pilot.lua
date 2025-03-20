vim.api.nvim_create_user_command(
    "PilotRemoveProjectRunConfig",
    require("pilot").remove_project_run_config,
    {
        nargs = 0,
        bar = false,
    }
)

vim.api.nvim_create_user_command(
    "PilotRemoveFileTypeRunConfig",
    require("pilot").remove_file_type_run_config,
    {
        nargs = 0,
        bar = false,
    }
)
