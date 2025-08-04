-- Keymap helper functions
local opts = { noremap = true, silent = true }
local keyset = function(modes, keys, cmd, options)
  options = options or {}
  options = vim.tbl_deep_extend('force', opts, options)
  vim.keymap.set(modes, keys, cmd, options)
end

-- Get visual selection
function vim.getVisualSelection()
  vim.cmd('noau normal! "vy"')
  local text = tostring(vim.fn.getreg('v'))
  vim.fn.setreg('v', {})

  text = string.gsub(text, '\n', '')
  if #text > 0 then
    return text
  else
    return ''
  end
end

-- Leader keys
keyset('', '<Space>', '<Nop>')
vim.g.mapleader = ' '
vim.g.maplocalleader = ',' -- "\" is the default

-- Move around in insert mode
keyset('i', 'jk', '<ESC>')
keyset('i', '<C-a>', '<Home>')
keyset('i', '<C-e>', '<End>')
keyset('i', '<A-b>', '<ESC>bi')
keyset('i', '<A-f>', '<ESC>lwi')

-- General mappings
keyset('n', 'j', 'gj')
keyset('n', 'k', 'gk')
keyset({ 'n', 'i' }, '<C-S>', '<cmd>w<CR><esc>', { desc = 'Save file' })
keyset('n', '<leader>qq', ':qa<CR>', { desc = 'Quit all' })
keyset('n', '<leader>x', ':bdelete<CR>', { desc = 'Delete Buffer and Window' })
keyset('n', ',A', 'ggVG<c-$>', { desc = 'Select All' })

-- Comment mappings
keyset('n', '<C-c>', 'gcc', { noremap = false, desc = 'Comment line' })
keyset('x', '<C-c>', 'gc', { noremap = false, desc = 'Comment select' })
keyset('n', 'gcy', 'gcc:t.<cr>gcc', { noremap = false, desc = 'Duplicate-comment line' })
keyset('v', 'gy', ":t'><cr>gvgcgv<esc>", { noremap = false, desc = 'Duplicate and comment' })

-- Buffer navigation
keyset('n', '<S-l>', ':bnext<CR>')
keyset('n', '<S-h>', ':bprevious<CR>')
keyset('n', 'ga', '<cmd>b#<cr>zz', { desc = 'Reopen buffer' })
keyset('n', 's', function() vim.api.nvim_feedkeys(':b ', 'n', false) end, { desc = 'Switch buffer' })

-- Search mappings
keyset('n', '*', '*N')
keyset('n', '#', '#N')
keyset('n', 'g*', 'g*N', { desc = 'Search not exact' })
keyset('n', 'g#', 'g#N', { desc = 'BckSearch not exact' })
keyset('v', '*', "y/\\V<C-R>=escape(@\",'/')<CR><CR>N", { desc = 'Search selection' })
keyset('v', 'g*', "y/\\V\\C<C-R>=escape(@\",'/')<CR><CR>N", { desc = 'Search selection (case sensitive)' })

-- Text manipulation
keyset('n', 'g;', '^v$h', { desc = 'Select line-no-end' })
keyset('n', '<leader>tw', '<cmd>set wrap!<cr>', { desc = 'Line wrap' })
keyset('n', '<c-d>', '<c-d>zz')
keyset('n', '<c-u>', '<c-u>zz')
keyset('n', 'n', 'nzzzv')
keyset('n', 'N', 'Nzzzv')
keyset('v', '<', '<gv')
keyset('v', '>', '>gv')
keyset('n', '<esc>', "<esc><cmd>noh<cr><cmd>echon ''<cr>", { desc = 'No highlight escape' })

-- Move text up and down
keyset('n', '<A-j>', '<cmd>m .+1<cr>==', { desc = 'Move line down' })
keyset('n', '<A-k>', '<cmd>m .-2<cr>==', { desc = 'Move line up' })
keyset('i', '<A-j>', '<esc><cmd>m .+1<cr>==gi', { desc = 'Move line down' })
keyset('i', '<A-k>', '<esc><cmd>m .-2<cr>==gi', { desc = 'Move line up' })
keyset('v', '<A-j>', ":m '>+1<cr>gv=gv", { desc = 'Move line down' })
keyset('v', '<A-k>', ":m '<-2<cr>gv=gv", { desc = 'Move line up' })

-- Movement mappings
keyset({ 'n', 'v', 'o' }, 'gk', '0', { desc = 'Go to start of line' })
keyset({ 'n', 'v', 'o' }, 'gh', '^', { desc = 'Go to beginning of line' })
keyset({ 'n', 'o' }, 'gl', '$', { desc = 'Go to end of line' })
keyset('v', 'gl', '$h', { desc = 'Select to end of line' })

-- Quickfix and loclist
keyset('n', '[q', '<cmd>cprev<cr>zvzz', { desc = 'Previous quickfix item' })
keyset('n', ']q', '<cmd>cnext<cr>zvzz', { desc = 'Next quickfix item' })
keyset('n', '[l', '<cmd>lprev<cr>zvzz', { desc = 'Previous loclist item' })
keyset('n', ']l', '<cmd>lnext<cr>zvzz', { desc = 'Next loclist item' })
vim.keymap.set('n', '<C-q>', function()
  local qf_exists = false
  local loc_exists = false
  for _, win in pairs(vim.fn.getwininfo()) do
    if win['quickfix'] == 1 then
      qf_exists = true
    elseif win['loclist'] == 1 then
      loc_exists = true
    end
  end
  if qf_exists or loc_exists then
    vim.cmd('cclose')
    vim.cmd('lclose')
  else
    if vim.fn.getloclist(0, { size = 0 }).size > 0 then
      vim.cmd('lopen 10')
    elseif vim.fn.getqflist({ size = 0 }).size > 0 then
      vim.cmd('copen 10')
    else
      vim.cmd('copen 10')
    end
  end
end, { desc = 'Toggle quickfix/location list' })

-- Moving around windows
keyset({ 'n', 't' }, '<C-t>', function()
  if vim.b.is_zoomed then
    vim.b.is_zoomed = false
    vim.api.nvim_call_function('execute', { vim.w.original_window_layout })
    vim.cmd('wincmd w')
  else
    vim.cmd('wincmd w')
  end
end, { desc = 'Smart window cycle' })

-- Fold mappings
keyset('n', 'z0', ':set foldlevel=0<cr>', { desc = 'Fold level 0' })
keyset('n', 'z1', ':set foldlevel=1<cr>', { desc = 'Fold level 1' })
keyset('n', 'z2', ':set foldlevel=2<cr>', { desc = 'Fold level 2' })
keyset('n', 'z9', ':set foldlevel=99<cr>', { desc = 'Fold level 99' })
keyset('n', '<leader>fi', ':set foldmethod=indent<cr>', { desc = 'Set fold indent' })
keyset('n', '<leader>fm', ':set foldmethod=marker<cr>', { desc = 'Set fold marker' })
keyset(
  'n',
  '<leader>ft',
  ':set foldmethod=expr<cr>:set foldexpr=nvim_treesitter#foldexpr()<cr>',
  { desc = 'Set fold treesitter' }
)
keyset('n', 'zm', ':set foldmethod=marker<cr>:set foldlevel=0<cr>', { desc = 'Set fold marker' })

-- Line number toggle with statuscolumn
keyset('n', '<leader>tl', function()
  if vim.opt.statuscolumn:get() == '' then
    vim.opt.statuscolumn = '%s%l %r  '
    vim.opt.number = true
    vim.opt.relativenumber = true
    vim.opt.cursorline = true
  else
    vim.opt.statuscolumn = ''
    vim.opt.number = false
    vim.opt.relativenumber = false
    vim.opt.cursorline = false
  end
end, { desc = 'Toggle Line Numbers' })

-- Utility mappings
keyset('n', '<space>y', "<cmd>let @+ = expand('%:p')<CR>")
keyset('n', '<space>cs', function()
  local command = vim.fn.input('Shell Command: ')
  if command == '' then return end
  vim.cmd('nos ene | setl bt=nofile')
  vim.cmd('r !' .. command)
  vim.cmd('1d')
  vim.bo.filetype = 'sh'
end, { desc = 'Shell Command to Scratch' })
keyset('n', '<space>cv', function()
  local command = vim.fn.input('Vim Command: ', '', 'command')
  if command == '' then return end
  vim.cmd('nos ene | setl bt=nofile')
  local output = vim.fn.execute(command)
  local lines = vim.split(output, '\n', { plain = true })
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  if command:match('^hi') or command:match('^highlight') or command:match('^map') then
    vim.bo.filetype = 'vim'
  else
    vim.bo.filetype = 'text'
  end
end, { desc = 'Vim Command to Scratch' })
keyset({ 'n', 'i', 'v' }, '<C-l>', require('utils').cursorMoveAround, { desc = 'Move Around Cursor' })
keyset({ 'n', 't' }, '<A-,>', require('utils').toggle_maximize_buffer, { desc = 'Maximize buffer' })
keyset('n', '<leader>e', function() vim.api.nvim_feedkeys(':find **/*', 'n', false) end, { desc = 'Switch buffer' })
keyset('n', '<leader>gd', require('utils').git_diff, { desc = 'Diff with git HEAD' })
keyset('n', '<C-P>', function()
  local peek = require('utils').lazy_require('peek')
  peek().peek_definition()
end, { desc = 'Peek Definition' })
keyset('n', '<leader>pd', function()
  local peek = require('utils').lazy_require('peek')
  peek().peek_diagnostics()
end, { desc = 'Peek Diagnostics' })

-- Terminal mappigs
keyset('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Enter normal mode' })
keyset('t', '<C-w>', [[<C-\><C-n><C-w>]])
keyset('n', '<C-\\>', function()
  vim.cmd('terminal')
  vim.cmd('startinsert')
end, { desc = 'Open Full Window Terminal' })
keyset('n', '<M-\\>', function()
  local height = math.floor(vim.o.lines * 0.4)
  vim.cmd('botright ' .. height .. 'split')
  vim.cmd('terminal')
  vim.cmd('startinsert')
end, { desc = 'Open Horizontal Terminal' })

-- Add undo break-points
keyset('i', ',', ',<c-g>u')
keyset('i', '.', '.<c-g>u')
keyset('i', ';', ';<c-g>u')
keyset('i', '<Space>', '<Space><c-g>u')

-- Sanity keymaps (easyclip emulation)
keyset('v', 'p', '"_dP')
keyset('x', 'p', '"_dP')
keyset('n', 'd', '"_d')
keyset('n', 'D', '"_D')
keyset('v', 'd', '"_d')
keyset('n', 'gm', 'm', { desc = 'Add mark' })
keyset('', 'm', 'd')
keyset('', 'M', 'D')
keyset('n', 'x', '"_x')
keyset('n', 'X', '"_X')
keyset({ 'n', 'x', 'o' }, 'c', '"_c')
keyset('n', 'cc', '"_cc')
keyset('n', 'cl', '"_cl')
keyset('n', 'ce', '"_ce')
keyset('n', 'ci', '"_ci')
keyset('n', 'C', '"_C')
keyset('v', 'x', '"_x')

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
