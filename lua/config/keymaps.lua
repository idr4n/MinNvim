-- Keymap helper functions
local opts = { noremap = true, silent = true }
local keymap = function(mode, keys, cmd, options)
  options = options or {}
  options = vim.tbl_deep_extend("force", opts, options)
  vim.api.nvim_set_keymap(mode, keys, cmd, options)
end
local keyset = function(modes, keys, cmd, options)
  options = options or {}
  options = vim.tbl_deep_extend("force", opts, options)
  vim.keymap.set(modes, keys, cmd, options)
end

-- Leader keys
keyset("", "<Space>", "<Nop>")
vim.g.mapleader = " "
vim.g.maplocalleader = "," -- "\" is the default

-- Move around in insert mode
keymap("i", "jk", "<ESC>")
keymap("i", "<C-a>", "<Home>")
keymap("i", "<C-e>", "<End>")
keymap("i", "<A-b>", "<ESC>bi")
keymap("i", "<A-f>", "<ESC>lwi")

-- General mappings
keymap("n", "j", "gj")
keymap("n", "k", "gk")
keyset({ "n", "i" }, "<C-S>", "<cmd>w<CR><esc>", { desc = "Save file" })
keyset("n", "<leader>fs", "<cmd>w<CR>", { desc = "Save file" })
keymap("n", "<leader>qq", ":qa<CR>", { desc = "Quit all" })
keymap("n", "<leader>x", ":bdelete<CR>", { desc = "Delete Buffer and Window" })
keymap("n", ",A", "ggVG<c-$>", { desc = "Select All" })

-- Comment mappings
keymap("n", "<C-c>", "gcc", { noremap = false, desc = "Comment line" })
keymap("x", "<C-c>", "gc", { noremap = false, desc = "Comment select" })
keymap("n", "gcy", "gcc:t.<cr>gcc", { noremap = false, desc = "Duplicate-comment line" })
keymap("v", "gy", ":t'><cr>gvgcgv<esc>", { noremap = false, desc = "Duplicate and comment" })

-- Buffer navigation
keymap("n", "<S-l>", ":bnext<CR>")
keymap("n", "<S-h>", ":bprevious<CR>")
keymap("n", "ga", "<cmd>b#<cr>zz", { desc = "Reopen buffer" })
keyset("n", "s", function()
  vim.api.nvim_feedkeys(":b ", "n", false)
end, { desc = "Switch buffer" })

-- Search mappings
keymap("n", "*", "*N")
keymap("n", "#", "#N")
keymap("n", "g*", "g*N", { desc = "Search not exact" })
keymap("n", "g#", "g#N", { desc = "BckSearch not exact" })
keymap("v", "*", "y/\\V<C-R>=escape(@\",'/')<CR><CR>N", { desc = "Search selection" })
keymap("v", "g*", "y/\\V\\C<C-R>=escape(@\",'/')<CR><CR>N", { desc = "Search selection (case sensitive)" })

-- Text manipulation
keymap("n", "g;", "^v$h", { desc = "Select line-no-end" })
keymap("n", "<leader>tw", "<cmd>set wrap!<cr>", { desc = "Line wrap" })
keymap("n", "<c-d>", "<c-d>zz")
keymap("n", "<c-u>", "<c-u>zz")
keyset("n", "n", "nzzzv")
keyset("n", "N", "Nzzzv")
keymap("v", "<", "<gv")
keymap("v", ">", ">gv")
keymap("n", "<esc>", "<esc><cmd>noh<cr><cmd>echon ''<cr>", { desc = "No highlight escape" })

-- Move text up and down
keymap("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
keymap("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
keymap("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move line down" })
keymap("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move line up" })
keymap("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move line down" })
keymap("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move line up" })

-- Movement mappings
keyset({ "n", "v", "o" }, "gk", "0", { desc = "Go to start of line" })
keyset({ "n", "v", "o" }, "gh", "^", { desc = "Go to beginning of line" })
keyset({ "n", "o" }, "gl", "$", { desc = "Go to end of line" })
keyset("v", "gl", "$h", { desc = "Select to end of line" })

-- Quickfix and loclist
keyset("n", "[q", "<cmd>cprev<cr>zvzz", { desc = "Previous quickfix item" })
keyset("n", "]q", "<cmd>cnext<cr>zvzz", { desc = "Next quickfix item" })
keyset("n", "[l", "<cmd>lprev<cr>zvzz", { desc = "Previous loclist item" })
keyset("n", "]l", "<cmd>lnext<cr>zvzz", { desc = "Next loclist item" })
vim.keymap.set('n', '<C-q>', function ()
  local qf_exists = false
  local loc_exists = false
  for _, win in pairs(vim.fn.getwininfo()) do
    if win["quickfix"] == 1 then
      qf_exists = true
    elseif win["loclist"] == 1 then
      loc_exists = true
    end
  end
  if qf_exists or loc_exists then
    vim.cmd("cclose")
    vim.cmd("lclose")
  else
    if vim.fn.getloclist(0, {size = 0}).size > 0 then
      vim.cmd("lopen 10")
    elseif vim.fn.getqflist({size = 0}).size > 0 then
      vim.cmd("copen 10")
    else
      vim.cmd("copen 10")
    end
  end
end, { desc = 'Toggle quickfix/location list' })

-- Moving around windows
keyset({ "n", "t" }, "<C-t>", function()
  if vim.b.is_zoomed then
    vim.b.is_zoomed = false
    vim.api.nvim_call_function("execute", { vim.w.original_window_layout })
    vim.cmd("wincmd w")
  else
    vim.cmd("wincmd w")
  end
end, { desc = "Smart window cycle" })

-- Fold mappings
keyset("n", "z0", ":set foldlevel=0<cr>", { desc = "Fold level 0" })
keyset("n", "z1", ":set foldlevel=1<cr>", { desc = "Fold level 1" })
keyset("n", "z2", ":set foldlevel=2<cr>", { desc = "Fold level 2" })
keyset("n", "z9", ":set foldlevel=99<cr>", { desc = "Fold level 99" })
keyset("n", "<leader>fi", ":set foldmethod=indent<cr>", { desc = "Set fold indent" })
keyset("n", "<leader>fm", ":set foldmethod=marker<cr>", { desc = "Set fold marker" })
keyset( "n", "<leader>ft", ":set foldmethod=expr<cr>:set foldexpr=nvim_treesitter#foldexpr()<cr>", { desc = "Set fold treesitter" })
keyset("n", "zm", ":set foldmethod=marker<cr>:set foldlevel=0<cr>", { desc = "Set fold marker" })

-- Line number toggle with statuscolumn
keyset("n", "<leader>tl", function()
  if vim.opt.statuscolumn:get() == "" then
    vim.opt.statuscolumn = "%s%l %r  "
    vim.opt.number = true
    vim.opt.relativenumber = true
    vim.opt.cursorline = true
  else
    vim.opt.statuscolumn = ""
    vim.opt.number = false
    vim.opt.relativenumber = false
    vim.opt.cursorline = false
  end
end, { desc = "Toggle Line Numbers" })

-- Utility mappings
keyset("n", "<space>y", "<cmd>let @+ = expand('%:p')<CR>")
keyset("n", "<space>cs", function()
  local command = vim.fn.input("Shell Command: ")
  if command == "" then return end
  vim.cmd("nos ene | setl bt=nofile")
  vim.cmd("r !" .. command)
  vim.cmd("1d")
  vim.bo.filetype = "sh"
end, { desc = "Shell Command to Scratch" })
keyset("n", "<space>cv", function()
  local command = vim.fn.input("Vim Command: ", "", "command")
  if command == "" then return end
  vim.cmd("nos ene | setl bt=nofile")
  local output = vim.fn.execute(command)
  local lines = vim.split(output, '\n', { plain = true })
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  if command:match("^hi") or command:match("^highlight") or command:match("^map") then
    vim.bo.filetype = "vim"
  else
    vim.bo.filetype = "text"
  end
end, { desc = "Vim Command to Scratch" })
keyset({ "n", "i", "v" }, "<C-l>", require("utils").cursorMoveAround, { desc = "Move Around Cursor" })
keyset({ "n", "t" }, "<A-,>", require("utils").toggle_maximize_buffer, { desc = "Maximize buffer" })
keyset("n", "<leader>e", function() vim.api.nvim_feedkeys(":find **/*", "n", false) end, { desc = "Switch buffer" })
keyset("n", "<leader>gd", require("utils").git_diff, { desc = "Diff with git HEAD" })

-- Add undo break-points
keymap("i", ",", ",<c-g>u")
keymap("i", ".", ".<c-g>u")
keymap("i", ";", ";<c-g>u")
keymap("i", "<Space>", "<Space><c-g>u")

-- Sanity keymaps (easyclip emulation)
keymap("v", "p", '"_dP')
keymap("x", "p", '"_dP')
keymap("n", "d", '"_d')
keymap("n", "D", '"_D')
keymap("v", "d", '"_d')
keyset("n", "gm", "m", { desc = "Add mark" })
keymap("", "m", "d")
keymap("", "M", "D")
keymap("n", "x", '"_x')
keymap("n", "X", '"_X')
keyset({ "n", "x", "o" }, "c", '"_c')
keymap("n", "cc", '"_cc')
keymap("n", "cl", '"_cl')
keymap("n", "ce", '"_ce')
keymap("n", "ci", '"_ci')
keymap("n", "C", '"_C')
keymap("v", "x", '"_x')

-- If using native neovim completions
-- keyset('i', '<C-Space>', '<C-x><C-o>', { desc = 'Omnicompletion' })
-- keyset('i', '<C-f>', '<C-x><C-f>', { desc = 'File Omnicompletion' })
-- keyset('i', '<C-b>', '<C-x><C-l>', { desc = 'Line Omnicompletion' })
-- keyset('i', '<Tab>', function()
--   if vim.fn.pumvisible() == 1 then
--     return '<C-n>'
--   else
--     return '<Tab>'
--   end
-- end, { expr = true, desc = 'Next completion or Tab' })
-- keyset('i', '<S-Tab>', function()
--   if vim.fn.pumvisible() == 1 then
--     return '<C-p>'
--   else
--     return '<S-Tab>'
--   end
-- end, { expr = true, desc = 'Previous completion or Shift-Tab' })
