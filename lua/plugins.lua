-- Plugins
vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter.git", },
})

-- Treesitter
require('nvim-treesitter.configs').setup({
  ensure_installed = { "lua", "vim", "vimdoc", "query" },
  highlight = { enable = true, additional_vim_regex_highlighting = false },
  -- highlight = { enable = true },
  indent = { enable = true },
})

