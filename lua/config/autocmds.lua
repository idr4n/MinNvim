-- Autocommands
local aucmd = vim.api.nvim_create_autocmd
local function augroup(name)
  return vim.api.nvim_create_augroup("idr4n/" .. name, { clear = true })
end

-- Custom message without loading time
local startup_group = augroup("StartUpScreen")
vim.api.nvim_create_autocmd("VimEnter", {
  group = startup_group,
  desc = "Show minimal startup screen",
  callback = function()
    -- require('utils').show_startup_screen("", false)
    require('utils').show_startup_screen("Neovim")
    -- require('utils').show_startup_screen("Neovim", false)
  end,
})

-- Restore normal settings when opening actual files
aucmd({"BufRead", "BufNewFile"}, {
  group = startup_group,
  callback = function()
    require('utils').restore_ui_settings()
  end,
})

-- close some filetypes with <q>
aucmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "help",
    "lspinfo",
    "man",
    "qf",
    "query",
    "checkhealth",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- go to last loc when opening a buffer
aucmd("BufReadPost", {
  group = augroup("LastLocation"),
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Lazy load statusline
aucmd({ 'BufReadPost', 'BufNewFile' }, {
  group = augroup('LazyLoadStatusline'),
  once = true,
  callback = function()
    vim.opt.statusline = '%!v:lua.require("config.statusline").StatusLine()'
  end,
  once = true
})

-- Redraw statusline on DiagnosticChanged
aucmd("DiagnosticChanged", {
  group = augroup("Status_Diagnostics"),
  callback = vim.schedule_wrap(function()
    vim.cmd("redrawstatus")
  end),
})

-- Lazy load commands
aucmd({ 'BufReadPost', 'BufNewFile' }, {
  group = augroup('LazyLoadCommands'),
  once = true,
  callback = function()
    require('config.commands')
  end,
  once = true
})

-- Lazy load LSP
aucmd({ 'BufReadPre', 'BufNewFile' }, {
  group = augroup('LazyLoadLSP'),
  once = true,
  callback = function()
    require('lsp')
  end,
  once = true
})
