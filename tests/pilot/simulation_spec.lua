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

    before_each(function()
        executed_commands = {}

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

        temp_base_dir = vim.fs.joinpath(
            vim.fn.tempname(),
            "pilot_test_" .. tostring(math.random(100000))
        )
    end)

    after_each(function()
        vim.ui.select = original_ui_select
        vim.fn.inputlist = original_inputlist
        vim.fn.input = original_input
        vim.cmd = original_vim_cmd

        if temp_base_dir and common.is_directory(temp_base_dir) then
            vim.fn.system({ "rm", "-rf", temp_base_dir })
        end
    end)

    local function test_executor(command)
        table.insert(executed_commands, command)
    end

    it("creates proper directory structure", function()
        local pilot_data_dir = vim.fs.joinpath(temp_base_dir, "pilot_data")
        local projects_dir = vim.fs.joinpath(pilot_data_dir, "projects")
        local filetypes_dir = vim.fs.joinpath(pilot_data_dir, "filetypes")

        assert.is_truthy(common.mkdir_with_parents(projects_dir))
        assert.is_truthy(common.mkdir_with_parents(filetypes_dir))

        assert.is_truthy(common.is_directory(pilot_data_dir))
        assert.is_truthy(common.is_directory(projects_dir))
        assert.is_truthy(common.is_directory(filetypes_dir))
    end)

    it("can create and parse project pilot file", function()
        local pilot_data_dir = vim.fs.joinpath(temp_base_dir, "pilot_data")
        local projects_dir = vim.fs.joinpath(pilot_data_dir, "projects")
        local pilot_json_path = vim.fs.joinpath(projects_dir, "pilot.json")

        common.mkdir_with_parents(projects_dir)

        local pilot_content = vim.fn.json_encode({
            { name = "Run Project Build", command = "echo 'Building project'" },
            { name = "Run Project Tests", command = "echo 'Running tests'" },
        })

        vim.fn.writefile(vim.fn.split(pilot_content, "\n"), pilot_json_path)

        assert.is_truthy(common.is_file_and_readable(pilot_json_path))

        local file_content = common.read_file(pilot_json_path)
        assert.is_truthy(file_content)
        ---@cast file_content string
        assert.is_truthy(string.find(file_content, "Building project"))
    end)

    it("can create and parse lua filetype pilot file", function()
        local pilot_data_dir = vim.fs.joinpath(temp_base_dir, "pilot_data")
        local filetypes_dir = vim.fs.joinpath(pilot_data_dir, "filetypes")
        local lua_json_path = vim.fs.joinpath(filetypes_dir, "lua.json")

        common.mkdir_with_parents(filetypes_dir)

        local lua_content = vim.fn.json_encode({
            { name = "Run Lua File", command = "lua {{file_path}}" },
            { name = "Format Lua", command = "stylua {{file_path}}" },
        })

        vim.fn.writefile(vim.fn.split(lua_content, "\n"), lua_json_path)

        assert.is_truthy(common.is_file_and_readable(lua_json_path))

        local file_content = common.read_file(lua_json_path)
        assert.is_truthy(file_content)
        ---@cast file_content string
        assert.is_truthy(string.find(file_content, "stylua"))
    end)

    it("runs project target with custom config", function()
        local projects_dir =
            vim.fs.joinpath(temp_base_dir, "pilot_data", "projects")
        local custom_pilot_path = vim.fs.joinpath(projects_dir, "project.json")

        common.mkdir_with_parents(projects_dir)

        local pilot_content = vim.fn.json_encode({
            {
                name = "Build Project",
                command = "echo 'Project build command'",
            },
        })

        vim.fn.writefile(vim.fn.split(pilot_content, "\n"), custom_pilot_path)

        pilot.setup({
            targets = {
                project = {
                    pilot_file_path = function()
                        return custom_pilot_path
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
                file_type = {
                    pilot_file_path = function()
                        return vim.fs.joinpath(temp_base_dir, "dummy.json")
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
            },
            executors = { test_exec = test_executor },
        })

        pilot.run_target("project")

        assert.equals(#executed_commands, 1)
        assert.is_truthy(string.find(executed_commands[1], "Project build"))
    end)

    it("runs file_type target with lua filetype", function()
        local projects_dir =
            vim.fs.joinpath(temp_base_dir, "pilot_data", "projects")
        local filetypes_dir =
            vim.fs.joinpath(temp_base_dir, "pilot_data", "filetypes")
        local lua_json_path = vim.fs.joinpath(filetypes_dir, "lua.json")

        common.mkdir_with_parents(filetypes_dir)

        local lua_content = vim.fn.json_encode({
            { name = "Execute Lua", command = "lua" },
        })

        vim.fn.writefile(vim.fn.split(lua_content, "\n"), lua_json_path)

        pilot.setup({
            targets = {
                project = {
                    pilot_file_path = function()
                        return vim.fs.joinpath(projects_dir, "dummy.json")
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
                file_type = {
                    pilot_file_path = function()
                        return lua_json_path
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
            },
            executors = { test_exec = test_executor },
        })

        pilot.run_target("file_type")

        assert.equals(#executed_commands, 1)
        assert.is_truthy(string.find(executed_commands[1], "lua"))
    end)

    it("runs both targets sequentially", function()
        local projects_dir =
            vim.fs.joinpath(temp_base_dir, "pilot_data", "projects")
        local filetypes_dir =
            vim.fs.joinpath(temp_base_dir, "pilot_data", "filetypes")
        local project_pilot_path = vim.fs.joinpath(projects_dir, "project.json")
        local lua_json_path = vim.fs.joinpath(filetypes_dir, "lua.json")

        common.mkdir_with_parents(projects_dir)
        common.mkdir_with_parents(filetypes_dir)

        vim.fn.writefile(
            vim.fn.split(
                vim.fn.json_encode({
                    {
                        name = "Project Command",
                        command = "echo 'project task'",
                    },
                }),
                "\n"
            ),
            project_pilot_path
        )

        vim.fn.writefile(
            vim.fn.split(
                vim.fn.json_encode({
                    { name = "Lua Command", command = "echo 'lua task'" },
                }),
                "\n"
            ),
            lua_json_path
        )

        pilot.setup({
            targets = {
                project = {
                    pilot_file_path = function()
                        return project_pilot_path
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
                file_type = {
                    pilot_file_path = function()
                        return lua_json_path
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
            },
            executors = { test_exec = test_executor },
        })

        pilot.run_target("project")
        assert.equals(#executed_commands, 1)

        pilot.run_target("file_type")
        assert.equals(#executed_commands, 2)

        assert.is_truthy(string.find(executed_commands[1], "project task"))
        assert.is_truthy(string.find(executed_commands[2], "lua task"))
    end)

    it("handles cross-platform paths correctly", function()
        local projects_dir =
            vim.fs.joinpath(temp_base_dir, "pilot_data", "projects")
        local filetypes_dir =
            vim.fs.joinpath(temp_base_dir, "pilot_data", "filetypes")

        common.mkdir_with_parents(projects_dir)
        common.mkdir_with_parents(filetypes_dir)

        local project_pilot_path = vim.fs.joinpath(projects_dir, "test.json")

        vim.fn.writefile(
            vim.fn.split(
                vim.fn.json_encode({
                    { command = "echo 'test'" },
                }),
                "\n"
            ),
            project_pilot_path
        )

        assert.is_truthy(common.is_directory(projects_dir))
        assert.is_truthy(common.is_directory(filetypes_dir))
        assert.is_truthy(common.is_file_and_readable(project_pilot_path))

        local joined_path = vim.fs.joinpath(temp_base_dir, "subdir", "file.txt")
        assert.is_truthy(string.find(joined_path, temp_base_dir))
    end)

    it("integration: setup, create, and run targets", function()
        local projects_dir =
            vim.fs.joinpath(temp_base_dir, "pilot_data", "projects")
        local filetypes_dir =
            vim.fs.joinpath(temp_base_dir, "pilot_data", "filetypes")
        local project_pilot_path = vim.fs.joinpath(projects_dir, "main.json")
        local lua_json_path = vim.fs.joinpath(filetypes_dir, "lua.json")

        common.mkdir_with_parents(projects_dir)
        common.mkdir_with_parents(filetypes_dir)

        vim.fn.writefile(
            vim.fn.split(
                vim.fn.json_encode({
                    { name = "Build", command = "make build" },
                }),
                "\n"
            ),
            project_pilot_path
        )

        vim.fn.writefile(
            vim.fn.split(
                vim.fn.json_encode({
                    { name = "Run", command = "lua {{file_name}}" },
                }),
                "\n"
            ),
            lua_json_path
        )

        pilot.setup({
            targets = {
                project = {
                    pilot_file_path = function()
                        return project_pilot_path
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
                file_type = {
                    pilot_file_path = function()
                        return lua_json_path
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
            },
            executors = { test_exec = test_executor },
        })

        executed_commands = {}
        pilot.run_target("project")
        assert.equals(#executed_commands, 1)
        assert.is_truthy(string.find(executed_commands[1], "make build"))

        executed_commands = {}
        pilot.run_target("file_type")
        assert.equals(#executed_commands, 1)
        assert.is_truthy(string.find(executed_commands[1], "lua"))
    end)

    it("handles multiple entries with auto_run disabled", function()
        local projects_dir =
            vim.fs.joinpath(temp_base_dir, "pilot_data", "projects")
        local project_pilot_path = vim.fs.joinpath(projects_dir, "multi.json")

        common.mkdir_with_parents(projects_dir)

        vim.fn.writefile(
            vim.fn.split(
                vim.fn.json_encode({
                    { name = "Option 1", command = "echo 'first'" },
                    { name = "Option 2", command = "echo 'second'" },
                    { name = "Option 3", command = "echo 'third'" },
                }),
                "\n"
            ),
            project_pilot_path
        )

        pilot.setup({
            targets = {
                project = {
                    pilot_file_path = function()
                        return project_pilot_path
                    end,
                    auto_run_single_command = false,
                    default_executor = test_executor,
                },
                file_type = {
                    pilot_file_path = function()
                        return vim.fs.joinpath(temp_base_dir, "dummy.json")
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
            },
            executors = { test_exec = test_executor },
        })

        executed_commands = {}
        pilot.run_target("project")
        assert.equals(#executed_commands, 1)
        assert.is_truthy(string.find(executed_commands[1], "first"))
    end)

    it("supports custom executor in pilot file", function()
        local projects_dir =
            vim.fs.joinpath(temp_base_dir, "pilot_data", "projects")
        local project_pilot_path = vim.fs.joinpath(projects_dir, "custom.json")

        common.mkdir_with_parents(projects_dir)

        vim.fn.writefile(
            vim.fn.split(
                vim.fn.json_encode({
                    {
                        name = "With Custom Executor",
                        command = "echo 'custom'",
                        executor = "test_exec",
                    },
                }),
                "\n"
            ),
            project_pilot_path
        )

        pilot.setup({
            targets = {
                project = {
                    pilot_file_path = function()
                        return project_pilot_path
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
                file_type = {
                    pilot_file_path = function()
                        return vim.fs.joinpath(temp_base_dir, "dummy.json")
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
            },
            executors = { test_exec = test_executor },
        })

        executed_commands = {}
        pilot.run_target("project")

        assert.equals(#executed_commands, 1)
        assert.is_truthy(string.find(executed_commands[1], "custom"))
    end)

    it("handles placeholder interpolation in commands", function()
        local projects_dir =
            vim.fs.joinpath(temp_base_dir, "pilot_data", "projects")
        local project_pilot_path =
            vim.fs.joinpath(projects_dir, "placeholders.json")

        common.mkdir_with_parents(projects_dir)

        vim.fn.writefile(
            vim.fn.split(
                vim.fn.json_encode({
                    {
                        name = "With Placeholders",
                        command = "echo {{cwd_name}} {{file_extension}}",
                    },
                }),
                "\n"
            ),
            project_pilot_path
        )

        pilot.setup({
            targets = {
                project = {
                    pilot_file_path = function()
                        return project_pilot_path
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
                file_type = {
                    pilot_file_path = function()
                        return vim.fs.joinpath(temp_base_dir, "dummy.json")
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
            },
            executors = { test_exec = test_executor },
        })

        executed_commands = {}
        pilot.run_target("project")

        assert.equals(#executed_commands, 1)
        assert.is_truthy(executed_commands[1])
        assert.is_truthy(string.find(executed_commands[1], "echo"))
    end)

    it("handles pilot file with only command property", function()
        local projects_dir =
            vim.fs.joinpath(temp_base_dir, "pilot_data", "projects")
        local project_pilot_path = vim.fs.joinpath(projects_dir, "minimal.json")

        common.mkdir_with_parents(projects_dir)

        vim.fn.writefile(
            vim.fn.split(
                vim.fn.json_encode({
                    "echo 'string entry'",
                    { command = "echo 'object entry'" },
                }),
                "\n"
            ),
            project_pilot_path
        )

        pilot.setup({
            targets = {
                project = {
                    pilot_file_path = function()
                        return project_pilot_path
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
                file_type = {
                    pilot_file_path = function()
                        return vim.fs.joinpath(temp_base_dir, "dummy.json")
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
            },
            executors = { test_exec = test_executor },
        })

        executed_commands = {}
        pilot.run_target("project")

        assert.equals(#executed_commands, 1)
        assert.is_truthy(string.find(executed_commands[1], "string entry"))
    end)

    it("verifies project target finds correct pilot file", function()
        local pilot_data_dir = vim.fs.joinpath(temp_base_dir, "pilot_data")
        local projects_dir = vim.fs.joinpath(pilot_data_dir, "projects")

        common.mkdir_with_parents(projects_dir)

        local project1 = vim.fs.joinpath(projects_dir, "proj1.json")
        local project2 = vim.fs.joinpath(projects_dir, "proj2.json")

        vim.fn.writefile(
            vim.fn.split(
                vim.fn.json_encode({
                    { name = "First Project", command = "echo 'proj1'" },
                }),
                "\n"
            ),
            project1
        )

        vim.fn.writefile(
            vim.fn.split(
                vim.fn.json_encode({
                    { name = "Second Project", command = "echo 'proj2'" },
                }),
                "\n"
            ),
            project2
        )

        pilot.setup({
            targets = {
                project = {
                    pilot_file_path = function()
                        return project2
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
                file_type = {
                    pilot_file_path = function()
                        return vim.fs.joinpath(temp_base_dir, "dummy.json")
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
            },
            executors = { test_exec = test_executor },
        })

        executed_commands = {}
        pilot.run_target("project")

        assert.equals(#executed_commands, 1)
        assert.is_truthy(string.find(executed_commands[1], "proj2"))
        assert.is_falsy(string.find(executed_commands[1], "proj1"))
    end)

    it("handles filetype target with multiple filetypes", function()
        local filetypes_dir =
            vim.fs.joinpath(temp_base_dir, "pilot_data", "filetypes")

        common.mkdir_with_parents(filetypes_dir)

        local lua_path = vim.fs.joinpath(filetypes_dir, "lua.json")
        local python_path = vim.fs.joinpath(filetypes_dir, "python.json")

        vim.fn.writefile(
            vim.fn.split(
                vim.fn.json_encode({
                    { name = "Lua Run", command = "lua script.lua" },
                }),
                "\n"
            ),
            lua_path
        )

        vim.fn.writefile(
            vim.fn.split(
                vim.fn.json_encode({
                    { name = "Python Run", command = "python script.py" },
                }),
                "\n"
            ),
            python_path
        )

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
                        return python_path
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
            },
            executors = { test_exec = test_executor },
        })

        executed_commands = {}
        pilot.run_target("file_type")

        assert.equals(#executed_commands, 1)
        assert.is_truthy(string.find(executed_commands[1], "python"))
        assert.is_falsy(string.find(executed_commands[1], "lua"))
    end)

    it("handles special characters in commands and paths", function()
        local projects_dir =
            vim.fs.joinpath(temp_base_dir, "pilot_data", "projects")
        local project_pilot_path = vim.fs.joinpath(projects_dir, "special.json")

        common.mkdir_with_parents(projects_dir)

        vim.fn.writefile(
            vim.fn.split(
                vim.fn.json_encode({
                    {
                        name = "Special Chars",
                        command = "echo 'test | grep pattern & bg'",
                    },
                }),
                "\n"
            ),
            project_pilot_path
        )

        pilot.setup({
            targets = {
                project = {
                    pilot_file_path = function()
                        return project_pilot_path
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
                file_type = {
                    pilot_file_path = function()
                        return vim.fs.joinpath(temp_base_dir, "dummy.json")
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
            },
            executors = { test_exec = test_executor },
        })

        executed_commands = {}
        pilot.run_target("project")

        assert.equals(#executed_commands, 1)
        assert.is_truthy(string.find(executed_commands[1], "grep pattern"))
    end)

    it("verifies cross-platform consistency across multiple runs", function()
        local pilot_data_dir = vim.fs.joinpath(temp_base_dir, "pilot_data")
        local projects_dir = vim.fs.joinpath(pilot_data_dir, "projects")
        local filetypes_dir = vim.fs.joinpath(pilot_data_dir, "filetypes")

        common.mkdir_with_parents(projects_dir)
        common.mkdir_with_parents(filetypes_dir)

        local project_path = vim.fs.joinpath(projects_dir, "consistent.json")
        local filetype_path = vim.fs.joinpath(filetypes_dir, "javascript.json")

        vim.fn.writefile(
            vim.fn.split(
                vim.fn.json_encode({
                    { name = "Project Run", command = "npm start" },
                }),
                "\n"
            ),
            project_path
        )

        vim.fn.writefile(
            vim.fn.split(
                vim.fn.json_encode({
                    { name = "File Run", command = "node {{file_path}}" },
                }),
                "\n"
            ),
            filetype_path
        )

        pilot.setup({
            targets = {
                project = {
                    pilot_file_path = function()
                        return project_path
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
                file_type = {
                    pilot_file_path = function()
                        return filetype_path
                    end,
                    auto_run_single_command = true,
                    default_executor = test_executor,
                },
            },
            executors = { test_exec = test_executor },
        })

        for i = 1, 3 do
            executed_commands = {}
            pilot.run_target("project")
            assert.equals(#executed_commands, 1)
            assert.is_truthy(
                string.find(executed_commands[1], "npm start"),
                "Run " .. i .. " failed"
            )
        end

        for i = 1, 3 do
            executed_commands = {}
            pilot.run_target("file_type")
            assert.equals(#executed_commands, 1)
            assert.is_truthy(
                string.find(executed_commands[1], "node"),
                "Filetype run " .. i .. " failed"
            )
        end
    end)
end)
