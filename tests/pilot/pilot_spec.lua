---@diagnostic disable: undefined-field

local pilot = require("pilot")

describe("setup", function()
    it("works with no options", function()
        local success = pcall(pilot.setup)
        assert.is_truthy(success)
    end)

    it("works with empty options", function()
        local success = pcall(pilot.setup, {})
        assert.is_truthy(success)
    end)
end)
