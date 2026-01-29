local M = {}

---@param config Config
function M.init(config)
    M.config = config
end

local required_braces = 2

---@param placeholder string
---@return string?, string?
local function extract_placeholder_function_call(placeholder)
    if placeholder:sub(1, 1) ~= "(" and placeholder:sub(-1) == ")" then
        local func_name, balanced_parens =
            placeholder:match("^([%w_%-]+)(%b())$")
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

    for var_name, resolve_var in pairs(M.config.placeholders.vars) do
        if placeholder == var_name then
            if type(resolve_var) ~= "function" then
                error(
                    "[Pilot] option 'placeholders.vars' values must a function that returns a string"
                )
            end
            local resolved = resolve_var()
            if type(resolved) ~= "string" then
                error(
                    "[Pilot] option 'placeholders.vars' values must a function that returns a string"
                )
            end
            return resolved
        end
    end

    local extracted_func_name, extracted_func_arg =
        extract_placeholder_function_call(placeholder)
    if extracted_func_name and extracted_func_arg then
        for func_name, resolve_func in pairs(M.config.placeholders.funcs) do
            if extracted_func_name == func_name then
                if type(resolve_func) ~= "function" then
                    error(
                        "[Pilot] option 'placeholders.funcs' values must a function that returns a string"
                    )
                end
                local resolved_func_arg =
                    resolve_placeholder(extracted_func_arg)
                local resolved = resolve_func(resolved_func_arg)
                if type(resolved) ~= "string" then
                    error(
                        "[Pilot] option 'placeholders.funcs' values must a function that returns a string"
                    )
                end
                return resolved
            end
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
---@param no_escape boolean?
---@return string
function M.interpolate(command, no_escape)
    local result = {}
    local cursor = 1
    local pattern = "({+)([^}]+)(}+)"

    ---@param text string
    local function insert_result_for_joining(text)
        if no_escape then
            table.insert(result, text)
        else
            table.insert(result, escape_vim_specials(text))
        end
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
            local resolved = resolve_placeholder(placeholder)

            -- handle potential extra braces
            local prefix = open_len > required_braces
                    and open_braces:sub(1, open_len - required_braces)
                or ""
            local suffix = close_len > required_braces
                    and close_braces:sub(1, close_len - required_braces)
                or ""

            local interpolated_segment = prefix .. resolved .. suffix
            insert_result_for_joining(interpolated_segment)
        end

        cursor = end_idx + 1
    end

    return table.concat(result)
end

return M
