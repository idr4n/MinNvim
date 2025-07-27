-- Plugins
vim.pack.add({
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/echasnovski/mini.diff",
  "https://github.com/ibhagwan/fzf-lua",
})

-- Treesitter
require('nvim-treesitter.configs').setup({
  ensure_installed = { "lua", "vim", "vimdoc", "query", "go" },
  highlight = { enable = true, additional_vim_regex_highlighting = false },
  -- highlight = { enable = true },
  indent = { enable = true },
})

-- mini.diff
local minidiff = require('mini.diff')
minidiff.setup({
  view = {
    signs = { add = ' +', change = ' ~', delete = ' -' },
  },
  mappings = {
    apply = '<leader>hs',
    reset = '<leader>hS',
    textobject = '<leader>hs',
    goto_first = '[C',
    goto_prev = '[c',
    goto_next = ']c',
    goto_last = ']C',
  },
})
vim.keymap.set("n", "<leader>gt", minidiff.toggle, { desc = "Toggle Mini Diff" })
vim.keymap.set("n", "<leader>go", minidiff.toggle_overlay, { desc = "Toggle Mini Diff" })

-- fzf-lua
require("fzf-lua").setup({
  winopts = {
    -- Open in a split at the bottom instead of floating window
    -- split = "belowright 13new",
    row = 0.5,
    height = 0.7,
    width = 89,
    backdrop = 100,
    preview = {
      hidden = true,
      layout = "vertical",
      -- layout = "horizontal",
      vertical = "down:50%",
      horizontal = "right:50%",
    },
  },
  keymap = {
    builtin = {
      ["<C-l>"] = "toggle-preview",
      ["<C-d>"] = "preview-page-down",
      ["<C-u>"] = "preview-page-up",
    },
    fzf = {
      ["ctrl-l"] = "toggle-preview",
      ["ctrl-q"] = "select-all+accept",
    },
  },
})
vim.keymap.set("n", "<C-Space>", ":FzfLua files<cr>")
