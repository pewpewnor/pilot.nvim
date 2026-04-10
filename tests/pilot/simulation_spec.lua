---@diagnostic disable: undefined-field

local pilot = require("pilot")
local common = require("pilot.common")

describe("simulation", function()
    local executed_commands = {}
    local temp_base_dir
    local original_ui_select
    local original_inputlist
    local original_input
    local original_vim_cmd

    ---@type Executor
    local function test_executor(command)
        table.insert(executed_commands, command)
    end

    local output_files = {}

    ---@type Executor
    local function system_output_executor(command)
        local output = vim.fn.system(command)

        table.insert(output_files, output)
        table.insert(executed_commands, command)
    end

    local function setup_mock_ui()
        original_ui_select = vim.ui.select
        original_inputlist = vim.fn.inputlist
        original_input = vim.fn.input
        original_vim_cmd = vim.cmd

        vim.ui.select = function(items, _, on_choice)
            on_choice(items[1], 1)
        end

        vim.fn.inputlist = function(_)
            return 1
        end

        vim.fn.input = function(_)
            return "1"
        end

        vim.cmd = function(cmd)
            if
                type(cmd) == "string"
                and not string.find(cmd, "tabnew")
                and not string.find(cmd, "split")
                and not string.find(cmd, "terminal")
            then
                original_vim_cmd(cmd)
            end
        end
    end

    local function restore_ui()
        vim.ui.select = original_ui_select
        vim.fn.inputlist = original_inputlist
        vim.fn.input = original_input
        vim.cmd = original_vim_cmd
    end

    local function get_pilot_dirs()
        local pilot_data_dir = vim.fs.joinpath(temp_base_dir, "pilot_data")
        local projects_dir = vim.fs.joinpath(pilot_data_dir, "projects")
        local filetypes_dir = vim.fs.joinpath(pilot_data_dir, "filetypes")
        return {
            pilot_data = pilot_data_dir,
            projects = projects_dir,
            filetypes = filetypes_dir,
        }
    end

    local function write_pilot_json(file_path, data)
        local pilot_content = vim.fn.json_encode(data)
        vim.fn.writefile(vim.fn.split(pilot_content, "\n"), file_path)
    end

    local function setup_pilot_with_paths(
        project_path,
        filetype_path,
        use_auto_run
    )
        use_auto_run = use_auto_run ~= false and true or false
        pilot.setup({
            targets = {
                project = {
                    pilot_file_path = function()
                        return project_path
                            or vim.fs.joinpath(temp_base_dir, "dummy.json")
                    end,
                    auto_run_single_command = use_auto_run,
                    default_executor = test_executor,
                },
                file_type = {
                    pilot_file_path = function()
                        return filetype_path
                            or vim.fs.joinpath(temp_base_dir, "dummy.json")
                    end,
                    auto_run_single_command = use_auto_run,
                    default_executor = test_executor,
                },
            },
        })
    end

    local function setup_pilot_with_custom_executors(
        project_path,
        filetype_path,
        executors
    )
        pilot.setup({
            targets = {
                project = {
                    pilot_file_path = function()
                        return project_path
                            or vim.fs.joinpath(temp_base_dir, "dummy.json")
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
                file_type = {
                    pilot_file_path = function()
                        return filetype_path
                            or vim.fs.joinpath(temp_base_dir, "dummy.json")
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
            },
            executors = executors,
        })
    end

    local function cleanup_temp_dir()
        if temp_base_dir and common.is_directory(temp_base_dir) then
            vim.fn.system({ "rm", "-rf", temp_base_dir })
        end
    end

    before_each(function()
        executed_commands = {}
        output_files = {}
        setup_mock_ui()
        temp_base_dir = vim.fs.joinpath(
            vim.fn.tempname(),
            "pilot_test_" .. tostring(math.random(100000))
        )
    end)

    after_each(function()
        restore_ui()
        cleanup_temp_dir()
    end)

    it("creates proper directory structure", function()
        local dirs = get_pilot_dirs()

        assert.is_truthy(common.mkdir_with_parents(dirs.projects))
        assert.is_truthy(common.mkdir_with_parents(dirs.filetypes))

        assert.is_truthy(common.is_directory(dirs.pilot_data))
        assert.is_truthy(common.is_directory(dirs.projects))
        assert.is_truthy(common.is_directory(dirs.filetypes))
    end)

    it("can create and parse project pilot file", function()
        local dirs = get_pilot_dirs()
        local pilot_json_path = vim.fs.joinpath(dirs.projects, "pilot.json")

        common.mkdir_with_parents(dirs.projects)

        write_pilot_json(pilot_json_path, {
            { name = "Run Project Build", command = "echo 'Building project'" },
            { name = "Run Project Tests", command = "echo 'Running tests'" },
        })

        assert.is_truthy(common.is_file_and_readable(pilot_json_path))

        local file_content = common.read_file(pilot_json_path)
        assert.is_truthy(file_content)
        ---@cast file_content string
        assert.is_truthy(string.find(file_content, "Building project"))
    end)

    it("can create and parse lua filetype pilot file", function()
        local dirs = get_pilot_dirs()
        local lua_json_path = vim.fs.joinpath(dirs.filetypes, "lua.json")

        common.mkdir_with_parents(dirs.filetypes)

        write_pilot_json(lua_json_path, {
            { name = "Run Lua File", command = "lua {{file_path}}" },
            { name = "Format Lua", command = "stylua {{file_path}}" },
        })

        assert.is_truthy(common.is_file_and_readable(lua_json_path))

        local file_content = common.read_file(lua_json_path)
        assert.is_truthy(file_content)
        ---@cast file_content string
        assert.is_truthy(string.find(file_content, "stylua"))
    end)

    it("runs project target with custom config", function()
        local dirs = get_pilot_dirs()
        local custom_pilot_path = vim.fs.joinpath(dirs.projects, "project.json")

        common.mkdir_with_parents(dirs.projects)

        write_pilot_json(custom_pilot_path, {
            {
                name = "Build Project",
                command = "echo 'Project build command'",
            },
        })

        setup_pilot_with_paths(custom_pilot_path, nil, true)

        pilot.run_target("project")

        assert.equals(1, #executed_commands)
        assert.is_truthy(string.find(executed_commands[1], "Project build"))
    end)

    it("runs file_type target with lua filetype", function()
        local dirs = get_pilot_dirs()
        local lua_json_path = vim.fs.joinpath(dirs.filetypes, "lua.json")
        local lua_script_file = vim.fs.joinpath(temp_base_dir, "script.lua")

        common.mkdir_with_parents(dirs.filetypes)

        vim.fn.writefile({ "print('Hello World')" }, lua_script_file)

        write_pilot_json(lua_json_path, {
            { name = "Execute Lua", command = "lua {{file_path}}" },
        })

        pilot.setup({
            targets = {
                project = {
                    pilot_file_path = function()
                        return vim.fs.joinpath(temp_base_dir, "dummy.json")
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
                file_type = {
                    pilot_file_path = function()
                        return lua_json_path
                    end,
                    auto_run_single_command = true,
                    default_executor = system_output_executor,
                },
            },
        })

        vim.cmd(":e " .. lua_script_file)

        executed_commands = {}
        output_files = {}
        pilot.run_target("file_type")

        assert.equals(1, #executed_commands)
        assert.is_truthy(string.find(executed_commands[1], "lua"))
        assert.equals(1, #output_files)
        assert.is_truthy(string.find(output_files[1], "Hello World"))
    end)

    it("runs both targets sequentially", function()
        local dirs = get_pilot_dirs()
        local project_pilot_path =
            vim.fs.joinpath(dirs.projects, "project.json")
        local lua_json_path = vim.fs.joinpath(dirs.filetypes, "lua.json")

        common.mkdir_with_parents(dirs.projects)
        common.mkdir_with_parents(dirs.filetypes)

        write_pilot_json(project_pilot_path, {
            { name = "Project Command", command = "echo 'project task'" },
        })

        write_pilot_json(lua_json_path, {
            { name = "Lua Command", command = "echo 'lua task'" },
        })

        setup_pilot_with_paths(project_pilot_path, lua_json_path, true)

        pilot.run_target("project")
        assert.equals(1, #executed_commands)

        executed_commands = {}
        pilot.run_target("file_type")
        assert.equals(1, #executed_commands)

        assert.is_truthy(string.find(executed_commands[1], "lua task"))
    end)

    it("handles cross-platform paths correctly", function()
        local dirs = get_pilot_dirs()
        common.mkdir_with_parents(dirs.projects)
        common.mkdir_with_parents(dirs.filetypes)

        local project_pilot_path = vim.fs.joinpath(dirs.projects, "test.json")

        write_pilot_json(project_pilot_path, {
            { command = "echo 'test'" },
        })

        assert.is_truthy(common.is_directory(dirs.projects))
        assert.is_truthy(common.is_directory(dirs.filetypes))
        assert.is_truthy(common.is_file_and_readable(project_pilot_path))

        local joined_path = vim.fs.joinpath(temp_base_dir, "subdir", "file.txt")
        assert.is_truthy(string.find(joined_path, temp_base_dir))
    end)

    it("integration: setup, create, and run targets", function()
        local dirs = get_pilot_dirs()
        local project_pilot_path = vim.fs.joinpath(dirs.projects, "main.json")
        local lua_json_path = vim.fs.joinpath(dirs.filetypes, "lua.json")

        common.mkdir_with_parents(dirs.projects)
        common.mkdir_with_parents(dirs.filetypes)

        write_pilot_json(project_pilot_path, {
            { name = "Build", command = "make build" },
        })

        write_pilot_json(lua_json_path, {
            { name = "Run", command = "lua {{file_name}}" },
        })

        setup_pilot_with_paths(project_pilot_path, lua_json_path, true)

        executed_commands = {}
        pilot.run_target("project")
        assert.equals(1, #executed_commands)
        assert.is_truthy(string.find(executed_commands[1], "make build"))

        executed_commands = {}
        pilot.run_target("file_type")
        assert.equals(1, #executed_commands)
        assert.is_truthy(string.find(executed_commands[1], "lua"))
    end)

    it("handles multiple entries with auto_run disabled", function()
        local dirs = get_pilot_dirs()
        local project_pilot_path = vim.fs.joinpath(dirs.projects, "multi.json")

        common.mkdir_with_parents(dirs.projects)

        write_pilot_json(project_pilot_path, {
            { name = "Option 1", command = "echo 'first'" },
            { name = "Option 2", command = "echo 'second'" },
            { name = "Option 3", command = "echo 'third'" },
        })

        setup_pilot_with_paths(project_pilot_path, nil, false)

        executed_commands = {}
        pilot.run_target("project")
        assert.equals(1, #executed_commands)
        assert.is_truthy(string.find(executed_commands[1], "first"))
    end)

    it("supports custom executor in pilot file", function()
        local dirs = get_pilot_dirs()
        local project_pilot_path = vim.fs.joinpath(dirs.projects, "custom.json")

        common.mkdir_with_parents(dirs.projects)

        write_pilot_json(project_pilot_path, {
            {
                name = "With Custom Executor",
                command = "echo 'custom'",
                executor = "test_exec",
            },
        })

        setup_pilot_with_custom_executors(project_pilot_path, nil, {
            test_exec = test_executor,
        })

        executed_commands = {}
        pilot.run_target("project")

        assert.equals(1, #executed_commands)
        assert.is_truthy(string.find(executed_commands[1], "custom"))
    end)

    it("handles placeholder interpolation in commands", function()
        local dirs = get_pilot_dirs()
        local project_pilot_path =
            vim.fs.joinpath(dirs.projects, "placeholders.json")

        common.mkdir_with_parents(dirs.projects)

        write_pilot_json(project_pilot_path, {
            {
                name = "With Placeholders",
                command = "echo {{cwd_name}} {{file_extension}}",
            },
        })

        setup_pilot_with_paths(project_pilot_path, nil, true)

        executed_commands = {}
        pilot.run_target("project")

        assert.equals(1, #executed_commands)
        assert.is_truthy(executed_commands[1])
        assert.is_truthy(string.find(executed_commands[1], "echo"))
    end)

    it("handles pilot file with only command property", function()
        local dirs = get_pilot_dirs()
        local project_pilot_path =
            vim.fs.joinpath(dirs.projects, "minimal.json")

        common.mkdir_with_parents(dirs.projects)

        write_pilot_json(project_pilot_path, {
            "echo 'string entry'",
            { command = "echo 'object entry'" },
        })

        setup_pilot_with_paths(project_pilot_path, nil, true)

        executed_commands = {}
        pilot.run_target("project")

        assert.equals(1, #executed_commands)
        assert.is_truthy(string.find(executed_commands[1], "string entry"))
    end)

    it("verifies project target finds correct pilot file", function()
        local dirs = get_pilot_dirs()
        common.mkdir_with_parents(dirs.projects)

        local project1 = vim.fs.joinpath(dirs.projects, "proj1.json")
        local project2 = vim.fs.joinpath(dirs.projects, "proj2.json")

        write_pilot_json(project1, {
            { name = "First Project", command = "echo 'proj1'" },
        })

        write_pilot_json(project2, {
            { name = "Second Project", command = "echo 'proj2'" },
        })

        setup_pilot_with_paths(project2, nil, true)

        executed_commands = {}
        pilot.run_target("project")

        assert.equals(1, #executed_commands)
        assert.is_truthy(string.find(executed_commands[1], "proj2"))
        assert.is_falsy(string.find(executed_commands[1], "proj1"))
    end)

    it("handles filetype target with multiple filetypes", function()
        local dirs = get_pilot_dirs()
        common.mkdir_with_parents(dirs.filetypes)

        local lua_path = vim.fs.joinpath(dirs.filetypes, "lua.json")
        local python_path = vim.fs.joinpath(dirs.filetypes, "python.json")

        write_pilot_json(lua_path, {
            { name = "Lua Run", command = "lua script.lua" },
        })

        write_pilot_json(python_path, {
            { name = "Python Run", command = "python script.py" },
        })

        setup_pilot_with_paths(nil, python_path, true)

        executed_commands = {}
        pilot.run_target("file_type")

        assert.equals(1, #executed_commands)
        assert.is_truthy(string.find(executed_commands[1], "python"))
        assert.is_falsy(string.find(executed_commands[1], "lua"))
    end)

    it("handles special characters in commands and paths", function()
        local dirs = get_pilot_dirs()
        local project_pilot_path =
            vim.fs.joinpath(dirs.projects, "special.json")

        common.mkdir_with_parents(dirs.projects)

        write_pilot_json(project_pilot_path, {
            {
                name = "Special Chars",
                command = "echo 'test | grep pattern & bg'",
            },
        })

        setup_pilot_with_paths(project_pilot_path, nil, true)

        executed_commands = {}
        pilot.run_target("project")

        assert.equals(1, #executed_commands)
        assert.is_truthy(string.find(executed_commands[1], "grep pattern"))
    end)

    it("verifies cross-platform consistency across multiple runs", function()
        local dirs = get_pilot_dirs()
        common.mkdir_with_parents(dirs.projects)
        common.mkdir_with_parents(dirs.filetypes)

        local project_path = vim.fs.joinpath(dirs.projects, "consistent.json")
        local filetype_path = vim.fs.joinpath(dirs.filetypes, "javascript.json")

        write_pilot_json(project_path, {
            { name = "Project Run", command = "npm start" },
        })

        write_pilot_json(filetype_path, {
            { name = "File Run", command = "node {{file_path}}" },
        })

        setup_pilot_with_paths(project_path, filetype_path, true)

        for i = 1, 3 do
            executed_commands = {}
            pilot.run_target("project")
            assert.equals(1, #executed_commands)
            assert.is_truthy(
                string.find(executed_commands[1], "npm start"),
                "Run " .. i .. " failed"
            )
        end

        for i = 1, 3 do
            executed_commands = {}
            pilot.run_target("file_type")
            assert.equals(1, #executed_commands)
            assert.is_truthy(
                string.find(executed_commands[1], "node"),
                "Filetype run " .. i .. " failed"
            )
        end
    end)
end)
