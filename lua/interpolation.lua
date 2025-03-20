local function resolve_command_placeholder(placeholder)
    if placeholder == "cword" then
        return fs_utils.get_current_word()
    elseif placeholder == "filename" then
        return fs_utils.get_current_file_name()
    elseif placeholder == "filename_without_extension" then
        return fs_utils.get_current_file_name_without_extension()
    elseif placeholder == "filetype" then
        return fs_utils.get_current_file_type()
    elseif placeholder == "filepath" then
        return fs_utils.get_current_file_path()
    elseif placeholder == "filepath_relative" then
        return fs_utils.get_current_file_path_relative()
    elseif placeholder == "dirname" then
        return fs_utils.get_current_dir_name()
    elseif placeholder == "dirpath" then
        return fs_utils.get_current_dir_path()
    elseif placeholder == "cwdname" then
        return fs_utils.get_current_working_dir_name()
    elseif placeholder == "cwdpath" then
        return fs_utils.get_current_working_dir_path()
    end
    error(
        "[pilot] unknown command placeholder '" .. placeholder .. "', you can surrounding it again with {} to escape it"
    )
end

local function interpolate_command(command)
    local number_of_braces_needed = 2
    local pattern = "({+)([^}]+)(}+)" -- this regex matches <text>, <<text>>, <<<text>>>, and so on

    return command:gsub(pattern, function(open_braces, placeholder, closing_braces)
        local number_of_open_braces = #open_braces
        local number_of_closing_braces = #closing_braces

        if number_of_open_braces > number_of_braces_needed and number_of_closing_braces > number_of_braces_needed then
            return open_braces:sub(1, number_of_open_braces - 1)
                .. placeholder
                .. closing_braces:sub(1, number_of_closing_braces - 1)
        elseif
            number_of_open_braces < number_of_braces_needed
            or number_of_closing_braces < number_of_braces_needed
        then
            return open_braces .. placeholder .. closing_braces
        end

        local interpolated = resolve_command_placeholder(placeholder)
        if number_of_open_braces > number_of_braces_needed then
            interpolated = open_braces:sub(1, number_of_open_braces - number_of_braces_needed) .. interpolated
        end
        if number_of_closing_braces > number_of_braces_needed then
            interpolated = interpolated .. closing_braces:sub(1, number_of_closing_braces - number_of_braces_needed)
        end
        return interpolated
    end)
end

return interpolate_command
