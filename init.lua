-- Start measuring startup time
vim.g.start_time = vim.uv.hrtime()

-- Load configuration modules
require("config.keymaps")
require("config.options")
require("config.autocmds")
require("config.commands")
require("lsp")
require("plugins")
