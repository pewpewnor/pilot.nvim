vim.api.nvim_create_user_command("PilotRemoveCurrentProjectConfig", require("pilot").remove_current_project_config, {
    nargs = 0,
    bar = false,
})

vim.api.nvim_create_user_command("PilotRemoveCurrentFiletypeConfig", require("pilot").remove_current_filetype_config, {
    nargs = 0,
    bar = false,
})
