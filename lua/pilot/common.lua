local M = {}

---@param command string
function M.cmd(command)
    vim.cmd(command)
end

---@param name string
---@param func fun(opts: table?)
---@param opts table
function M.create_user_command(name, func, opts)
    vim.api.nvim_create_user_command(name, func, opts)
end

---@param json_string string
---@return any?
function M.decode_json(json_string)
    local success, result = pcall(vim.json.decode, json_string)
    return success and result or nil
end

---@param path string
---@return string
function M.dirname(path)
    return vim.fs.dirname(path)
end

---@param value any
---@return string
function M.encode_json(value)
    return vim.json.encode(value)
end

---@param expr string
---@return string
function M.expand(expr)
    return vim.fn.expand(expr)
end

---@param path string
---@return string
function M.fnameescape(path)
    return vim.fn.fnameescape(path)
end

---@param path string
---@param modifier string
---@return string
function M.fnamemodify(path, modifier)
    return vim.fn.fnamemodify(path, modifier)
end

---@return string
function M.get_cwd()
    return vim.fn.getcwd()
end

---@return string
function M.get_filetype()
    return vim.bo.filetype
end

---@return string
function M.get_shell()
    return vim.o.shell
end

---@param what string
---@return string
function M.get_stdpath(what)
    return vim.fn.stdpath(what)
end

---@return string
function M.get_tempname()
    return vim.fn.tempname()
end

---@param feature string
---@return boolean
function M.has(feature)
    return vim.fn.has(feature) == 1
end

---@param str string
---@return string
function M.hash_sha256(str)
    return vim.fn.sha256(str)
end

---@param message string
---@param advice string?
function M.health_error(message, advice)
    vim.health.error(message, advice)
end

---@param message string
function M.health_ok(message)
    vim.health.ok(message)
end

---@param name string
function M.health_start(name)
    vim.health.start(name)
end

---@param message string
---@param advice string?
function M.health_warn(message, advice)
    vim.health.warn(message, advice)
end

---@param path string
---@return boolean
function M.is_directory(path)
    local stat = vim.uv.fs_stat(path)
    return stat ~= nil and stat.type == "directory"
end

---@param path string
---@return boolean
function M.is_directory_writable(path)
    return vim.fn.filewritable(path) == 2
end

---@param name string
---@return boolean
function M.is_executable(name)
    return vim.fn.executable(name) == 1
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
    local parent = M.dirname(path)
    if parent and parent ~= path then
        M.mkdir_with_parents(parent)
    end
    return vim.uv.fs_mkdir(path, 493) == true
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

---@param path string
function M.path_remove_recursive(path)
    vim.fs.rm(path, { force = true, recursive = true })
end

---@param path string
---@return string?
function M.read_file(path)
    local success, lines = pcall(vim.fn.readfile, path)
    return success and vim.fn.join(lines) or nil
end

---@param path string
function M.rtp_append(path)
    vim.opt.runtimepath:append(path)
end

---@param args string[]
function M.run_process_silent(args)
    vim.system(args):wait()
end

---@param command string
---@param on_exit? fun(result: {code: integer, stdout: string, stderr: string})
function M.run_shell_async(command, on_exit)
    vim.system({ vim.o.shell, vim.o.shellcmdflag, command }, {}, on_exit)
end

---@param command string
---@return string
function M.run_shell_output(command)
    local result = vim.system(
        { vim.o.shell, vim.o.shellcmdflag, command },
        { text = true }
    ):wait()
    return result.stdout
end

---@param command string
function M.run_shell_silent(command)
    vim.system({ vim.o.shell, vim.o.shellcmdflag, command }):wait()
end

---@param pattern string
---@return integer
function M.search(pattern)
    return vim.fn.search(pattern)
end

---@param lines string[]
function M.set_current_buffer_lines(lines)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

---@param name string
function M.set_current_buffer_name(name)
    vim.api.nvim_buf_set_name(0, name)
end

---@param filetype string
function M.set_filetype(filetype)
    vim.bo.filetype = filetype
end

---@param ... any
---@return table
function M.tbl_deep_extend(...)
    return vim.tbl_deep_extend(...)
end

---@param str string
---@return string
function M.trim(str)
    return vim.trim(str)
end

---@param items any[]
---@param opts table
---@param on_choice fun(item: any?)
function M.ui_select(items, opts, on_choice)
    vim.ui.select(items, opts, on_choice)
end

---@param name string
---@param val any
---@param expected_type any
function M.validate(name, val, expected_type)
    vim.validate(name, val, expected_type)
end

---@param path string
---@param lines string[]
---@param mode nil|"a"
---@return boolean
function M.write_file(path, lines, mode)
    return vim.fn.writefile(lines, path, mode or "") == 0
end

return M
