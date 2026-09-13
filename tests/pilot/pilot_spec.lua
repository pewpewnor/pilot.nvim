---@diagnostic disable: undefined-field

local pilot = require("pilot")
local module = require("pilot.module")

describe("setup", function()
    it("works with no options", function()
        local success = pcall(pilot.setup)
        assert.is_truthy(success)
    end)

    it("works with empty options", function()
        local success = pcall(pilot.setup, {})
        assert.is_truthy(success)
    end)

    it("provides the built-in target names", function()
        pilot.setup()
        assert.same({ "filetype", "project" }, module.get_target_names())
    end)
end)
