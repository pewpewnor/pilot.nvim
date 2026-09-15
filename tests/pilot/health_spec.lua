---@diagnostic disable: undefined-field

local common = require("pilot.common")
local health = require("pilot.health")
local pilot = require("pilot")

describe("health", function()
    local original_health_error
    local original_health_ok
    local original_health_start
    local original_health_warn

    before_each(function()
        original_health_error = common.health_error
        original_health_ok = common.health_ok
        original_health_start = common.health_start
        original_health_warn = common.health_warn

        ---@diagnostic disable-next-line: duplicate-set-field
        common.health_error = function() end
        ---@diagnostic disable-next-line: duplicate-set-field
        common.health_ok = function() end
        ---@diagnostic disable-next-line: duplicate-set-field
        common.health_start = function() end
        ---@diagnostic disable-next-line: duplicate-set-field
        common.health_warn = function() end
    end)

    after_each(function()
        common.health_error = original_health_error
        common.health_ok = original_health_ok
        common.health_start = original_health_start
        common.health_warn = original_health_warn
    end)

    it("can run before setup", function()
        assert.has_no.errors(health.check)
    end)

    it("checks configured targets after setup", function()
        local checked_paths = 0
        local function count_checked_path(message)
            if message:find("write pilot files", 1, true) then
                checked_paths = checked_paths + 1
            end
        end
        ---@diagnostic disable-next-line: duplicate-set-field
        common.health_ok = count_checked_path
        ---@diagnostic disable-next-line: duplicate-set-field
        common.health_warn = count_checked_path
        pilot.setup()

        health.check()

        assert.equals(2, checked_paths)
    end)
end)
