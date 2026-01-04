local required_braces = 2

---@param placeholder string
---@return string?, string?
local function extract_placeholder_function_call(placeholder)
    if placeholder:sub(1, 1) ~= "(" and placeholder:sub(-1) == ")" then
        local func_name, balanced_parens = placeholder:match("^(%w+)(%b())$")
        if func_name and balanced_parens then
            return func_name, balanced_parens:sub(2, -2)
        end
    end
    return nil, nil
end

---@param placeholder string?
---@return string
local function resolve_placeholder(placeholder)
    placeholder = vim.fn.trim(placeholder or "")
    if placeholder == "" then
        return ""
    elseif placeholder == "file_path" then
        return vim.fn.expand("%:p")
    elseif placeholder == "file_path_relative" then
        return vim.fn.expand("%")
    elseif placeholder == "file_name" then
        return vim.fn.expand("%:t")
    elseif placeholder == "file_name_no_extension" then
        return vim.fn.expand("%:t:r")
    elseif placeholder == "file_type" then
        return vim.bo.filetype
    elseif placeholder == "file_extension" then
        return vim.fn.expand("%:e")
    elseif placeholder == "dir_path" then
        return vim.fn.expand("%:p:h")
    elseif placeholder == "dir_name" then
        return vim.fn.expand("%:p:h:t")
    elseif placeholder == "cwd_path" then
        return vim.fn.getcwd()
    elseif placeholder == "cwd_name" then
        return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
    elseif placeholder == "pilot_data_path" then
        local pilot_data_path = vim.fs.joinpath(vim.fn.stdpath("data"), "pilot")
        if vim.fn.isdirectory(pilot_data_path) == 0 then
            vim.fn.mkdir(pilot_data_path, "p")
        end
        return pilot_data_path
    elseif placeholder == "cword" then
        return vim.fn.expand("<cword>")
    elseif placeholder == "cWORD" then
        return vim.fn.expand("<cWORD>")
    else
        local func_name, func_arg =
            extract_placeholder_function_call(placeholder)
        if func_name == "hash" and func_arg then
            local resolved_arg = resolve_placeholder(func_arg)
            return vim.fn.sha256(resolved_arg)
        end
    end
    error(
        string.format(
            "[Pilot] Unknown/invalid command placeholder '%s', you can try surrounding it with {} to escape it.",
            placeholder
        )
    )
end

---@param text string
---@return string
local function escape_vim_specials(text)
    return (text:gsub("%%", "\\%%"):gsub("#", "\\#"):gsub("<", "\\<"))
end

---@param command string
---@return string
local function interpolate(command)
    local result = {}
    local cursor = 1
    local pattern = "({+)([^}]+)(}+)"

    function insert_result_for_joining(text)
        table.insert(result, escape_vim_specials(text))
    end

    while true do
        local start_idx, end_idx, open_braces, placeholder, close_braces =
            command:find(pattern, cursor)

        local static_end = start_idx and (start_idx - 1) or #command
        if static_end >= cursor then
            -- case for normal text
            local static_text = command:sub(cursor, static_end)
            insert_result_for_joining(static_text)
        end

        if not start_idx then
            break
        end

        local open_len = #open_braces
        local close_len = #close_braces

        if open_len > required_braces and close_len > required_braces then
            -- case for escaped braces
            local prefix = open_braces:sub(1, open_len - 1)
            local suffix = close_braces:sub(1, close_len - 1)
            local raw_segment = prefix .. placeholder .. suffix
            insert_result_for_joining(raw_segment)
        elseif open_len < required_braces or close_len < required_braces then
            -- case for insufficient braces
            local raw_segment = open_braces .. placeholder .. close_braces
            insert_result_for_joining(raw_segment)
        else
            -- case for valid interpolation
            local resolved_placeholder = resolve_placeholder(placeholder)
            local escaped_resolved = vim.fn.fnameescape(resolved_placeholder)

            -- handle potential extra braces
            local prefix = open_len > required_braces
                    and open_braces:sub(1, open_len - required_braces)
                or ""
            local suffix = close_len > required_braces
                    and close_braces:sub(1, close_len - required_braces)
                or ""

            insert_result_for_joining(prefix .. escaped_resolved .. suffix)
        end

        cursor = end_idx + 1
    end

    return table.concat(result)
end

return interpolate
