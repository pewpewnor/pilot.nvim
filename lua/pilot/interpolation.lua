local required_braces = 2

---@param placeholder string
---@return string
local function resolve_placeholder(placeholder)
    if placeholder == "file_path" then
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
        return vim.fn.fnamemodify(placeholder, ":h:t")
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
    elseif placeholder == "hash(cwd_path)" then
        return vim.fn.sha256(vim.fn.getcwd())
    elseif placeholder == "hash(file_path)" then
        return vim.fn.sha256(vim.fn.expand("%:p"))
    end
    error(
        string.format(
            "[Pilot] Unknown command placeholder '%s', you can try surrounding it with {} to escape it.",
            placeholder
        )
    )
end

-- The reason why we need to do this dance is because e.g. the user expects the
-- bash command `echo %` (without any placeholder interpolation) to work
-- perfectly fine since it makes sense. Unfortunately, in the end, it would
-- become something like `tabnew | terminal echo %` which is illegal in vim
-- because of the `%` symbol. We need to not only escape the interpolated part
-- with fnameescape, but also the non interpolated part.
---@param command string
---@return string
local function escape_non_interpolated(command)
    -- example of how this works:
    -- interpolation will convert "ls {{dir_name}} {{file_name}}" to "ls a\ b %"
    -- fnameescape will produce "ls\ a\\\ b \%"
    -- gsub escaped space once to produce "ls a\\ b \%"
    -- gsub escaped space again to produce ls a\ b \%"
    -- extra gsubs for things that should not be escaped
    return vim.fn
        .fnameescape(command)
        :gsub("\\ ", " ")
        :gsub("\\ ", " ")
        :gsub("\\'", "'")
        :gsub('\\"', '"')
        :gsub("\\!", "!")
end

---@param command string
---@return string
local function interpolate(command)
    local pattern = "({+)([^}]+)(}+)"

    local result = command:gsub(
        pattern,
        function(open_braces, placeholder, closing_braces)
            local open_count = #open_braces
            local close_count = #closing_braces

            if
                open_count > required_braces
                and close_count > required_braces
            then
                return open_braces:sub(1, open_count - 1)
                    .. placeholder
                    .. closing_braces:sub(1, close_count - 1)
            elseif
                open_count < required_braces
                or close_count < required_braces
            then
                return open_braces .. placeholder .. closing_braces
            end

            -- we don't use fnameescape here since it will be done later
            -- but space should be escaped so that later it can be
            -- differentiated from literal command argument spaces
            -- see the description of the escape_non_interpolated function
            -- to understand why we need to do this dance
            local interpolated =
                resolve_placeholder(placeholder):gsub(" ", "\\ ")
            if open_count > required_braces then
                interpolated = open_braces:sub(1, open_count - required_braces)
                    .. interpolated
            end
            if close_count > required_braces then
                interpolated = interpolated
                    .. closing_braces:sub(1, close_count - required_braces)
            end
            return interpolated
        end
    )
    return escape_non_interpolated(result)
end

return interpolate
