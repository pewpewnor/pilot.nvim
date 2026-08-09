package.path = "./lua/?.lua;./lua/?/init.lua;" .. package.path

local common = require("pilot.common")

local plenary_dir = os.getenv("PLENARY_DIR") or "/tmp/plenary.nvim"
if not common.is_directory(plenary_dir) then
    common.run_process_silent({
        "git",
        "clone",
        "https://github.com/nvim-lua/plenary.nvim",
        plenary_dir,
    })
end

common.rtp_append(".")
common.rtp_append(plenary_dir)

common.cmd("runtime " .. common.path_join("plugin", "plenary.vim"))
require("plenary.busted")
