-- Basic options
vim.o.clipboard = "unnamedplus"
vim.o.laststatus = 2
vim.o.undofile = true
vim.opt.autowrite = true
vim.opt.backup = false
vim.opt.breakindent = true
vim.opt.completeopt = { 'menu', 'menuone', 'noselect', 'fuzzy', 'popup' }
vim.opt.expandtab = true
vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.ignorecase = true
vim.opt.linebreak = true
vim.opt.list = true
vim.opt.scrolloff = 5
vim.opt.shiftwidth = 2
vim.opt.showbreak = "↪ "
vim.opt.signcolumn = "yes:2"
-- vim.opt.signcolumn = "yes"
-- vim.opt.softtabstop = -1
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.swapfile = false
vim.opt.tabstop = 2
vim.opt.writebackup = false

-- List chars
vim.opt.listchars = { trail = "·", tab = "  ", nbsp = "␣" }
vim.opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  -- eob = " ",
}

-- Disable treesitter
-- vim.treesitter.start = function() end
-- vim.api.nvim_create_autocmd("BufEnter", {callback = function() vim.treesitter.stop() end})

-- Enable syntax and load colorscheme
vim.cmd.colorscheme("minimal")

-- Use ripgrep for grepping.
vim.o.grepprg = "rg --vimgrep"
vim.o.grepformat = "%f:%l:%c:%m"

-- Explorer settings
vim.g.netrw_browse_split = 0
vim.g.netrw_winsize = 25
vim.g.netrw_fastbrowse = 0
vim.g.netrw_bufsettings = "noma nomod nu nowrap ro nobl"
vim.g.netrw_preview = 1
vim.g.netrw_alto = 0
