local string_utils = require("string_utils")

local M = {}

M.get_cwd_path = function()
    return vim.fn.fnameescape(vim.fn.getcwd())
end

M.get_data_path = function()
    return vim.fn.stdpath("data")
end

M.hash_sha_256 = vim.fn.sha256

---@param path string The directory path to create
M.mkdir = function(path)
    vim.fn.system("mkdir -p " .. path)
end

---@return string Word The word under the cursor (equivalent to `yiw`)
M.get_current_word = function()
    return vim.fn.expand("<cword>")
end

---@return string DirName The name of the current working directory
M.get_current_working_dir_name = function()
    return string_utils.slice_from_last_occur_char_to_end(M.get_current_working_dir_path(), "/")
end

---@return string DirPath The absolute path of the current working directory
M.get_current_working_dir_path = function()
    return vim.fn.fnameescape(vim.fn.getcwd())
end

---@return string DirPath The absolute path of the currently opened directory
M.get_current_dir_path = function()
    return vim.fn.fnameescape(vim.fn.expand("%:p:h"))
end

---@return string DirName The name of the current directory
M.get_current_dir_name = function()
    return vim.fn.fnameescape(vim.fn.expand("%:p:h:t"))
end

---@return string FilePath The absolute path of the currently opened file
M.get_current_file_path = function()
    return vim.fn.fnameescape(vim.fn.expand("%:p"))
end

---@return string FilePath The relative path of the currently opened file
M.get_current_file_path_relative = function()
    return vim.fn.fnameescape(vim.fn.expand("%"))
end

---@return string FileName The name of the currently opened file with extension
M.get_current_file_name = function()
    return vim.fn.fnameescape(vim.fn.expand("%:t"))
end

---@return string FileName The name of the currently opened file without last extension
M.get_current_file_name_without_extension = function()
    return string_utils.slice_from_start_up_to_last_occur_char(M.get_current_file_name(), ".")
end

---@return string FileExtension The last extension of the currently opened file
M.get_current_file_extension = function()
    return string_utils.slice_from_last_occur_char_to_end(M.get_current_file_name(), ".")
end

---@return string FileType The file type (according to neovim) of the currently opened file
M.get_current_file_type = function()
    return vim.bo.filetype
end

return M
