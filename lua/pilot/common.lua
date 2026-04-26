local M = {}

---@param path string
---@return string?
function M.read_file(path)
    local success, lines = pcall(vim.fn.readfile, path)
    return success and vim.fn.join(lines) or nil
end

---@param path string
---@param lines string[]
---@param mode nil|"a"
---@return boolean
function M.write_file(path, lines, mode)
    return vim.fn.writefile(lines, path, mode) == 0
end

---@param json_string string
---@return any?
function M.json_decode(json_string)
    local success, result = pcall(vim.json.decode, json_string)
    return success and result or nil
end

---@param path string
---@return boolean
function M.is_directory(path)
    local stat = vim.uv.fs_stat(path)
    return stat ~= nil and stat.type == "directory"
end

---@param path string
---@return boolean
function M.is_file_and_readable(path)
    local stat = vim.uv.fs_stat(path)
    return stat ~= nil and stat.type == "file"
end

---@param path string
---@return boolean
function M.mkdir_with_parents(path)
    if M.is_directory(path) then
        return true
    end
    local parent = vim.fs.dirname(path)
    if parent and parent ~= path then
        M.mkdir_with_parents(parent)
    end
    return vim.uv.fs_mkdir(path, 493) == true
end

---@param command string
function M.run_cmd(command)
    vim.cmd(command)
end

---@param command string
function M.run_shell_silent(command)
    vim.system({ vim.o.shell, vim.o.shellcmdflag, command }):wait()
end

---@param command string
---@return string
function M.run_shell_output(command)
    local result =
        vim.system({ vim.o.shell, vim.o.shellcmdflag, command }, { text = true }):wait()
    return result.stdout
end

---@param command string
function M.run_shell_async(command)
    vim.system({ vim.o.shell, vim.o.shellcmdflag, command })
end

---@param command string
---@param on_exit fun(result: {code: integer, stdout: string, stderr: string})
function M.run_shell_async_on_exit(command, on_exit)
    vim.system({ vim.o.shell, vim.o.shellcmdflag, command }, {}, on_exit)
end

---@param ... string
---@return string
function M.path_join(...)
    return vim.fs.joinpath(...)
end

---@param path string
function M.path_remove(path)
    vim.fs.rm(path, { force = true })
end

---@param expr string
---@return string
function M.expand(expr)
    return vim.fn.expand(expr)
end

---@param path string
---@param modifier string
---@return string
function M.path_modify(path, modifier)
    return vim.fn.fnamemodify(path, modifier)
end

---@return string
function M.get_filetype()
    return vim.bo.filetype
end

---@return string
function M.get_cwd()
    return vim.fn.fnameescape(vim.fn.getcwd())
end

---@param what string
---@return string
function M.get_stdpath(what)
    return vim.fn.stdpath(what)
end

---@param str string
---@return string
function M.sha256(str)
    return vim.fn.sha256(str)
end

---@param path string
---@return string
function M.fnameescape(path)
    return vim.fn.fnameescape(path)
end

---@return string
function M.get_cwd_raw()
    return vim.fn.getcwd()
end

---@param str string
---@return string
function M.trim(str)
    return vim.trim(str)
end

---@param name string
---@param val any
---@param expected_type any
function M.validate(name, val, expected_type)
    vim.validate(name, val, expected_type)
end

---@param t table
function M.iter(t)
    return vim.iter(t)
end

---@param ... any
---@return table
function M.tbl_deep_extend(...)
    return vim.tbl_deep_extend(...)
end

---@param items any[]
---@param opts table
---@param on_choice fun(item: any?)
function M.ui_select(items, opts, on_choice)
    vim.ui.select(items, opts, on_choice)
end

return M
