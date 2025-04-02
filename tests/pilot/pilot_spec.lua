local pilot = require("pilot")

describe("setup", function()
    it("works with no options", function()
        local success = pcall(pilot.setup)
        assert(success, "setup must work with no options")
    end)

    it("works with empty options", function()
        local success = pcall(pilot.setup, {})
        assert(success, "setup must work with empty options")
    end)
end)
