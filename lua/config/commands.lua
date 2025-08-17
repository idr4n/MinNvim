-- Own commands

-- Shorten function name
local command = vim.api.nvim_create_user_command
local opts = { noremap = true, silent = true }
local map = function(mode, keys, cmd, options)
  options = options or {}
  options = vim.tbl_deep_extend('force', opts, options)
  vim.keymap.set(mode, keys, cmd, options)
end

-- Open markdown file in Marked 2
command('OpenMarked2', 'execute \'silent !open -a Marked\\ 2 "%"\'', {})

-- Markdown preview commands using `gh-markdown-preview`
command('MarkdownPreviewStart', function()
  vim.cmd('MarkdownPreviewStop')
  local file = vim.fn.expand('%')

  -- Check if file is markdown
  if vim.bo.filetype ~= 'markdown' then
    vim.notify('Not a markdown file', vim.log.levels.WARN)
    return
  end

  _G.md_preview_job = vim.fn.jobstart('gh markdown-preview ' .. file, {
    detach = false,
    on_exit = function()
      _G.md_preview_job = nil
      vim.notify('Markdown preview exited', vim.log.levels.INFO)
    end,
  })
  vim.notify('Markdown preview started at http://localhost:3333', vim.log.levels.INFO)
end, {})
command('MarkdownPreviewStop', function()
  if _G.md_preview_job then
    vim.fn.jobstop(_G.md_preview_job)
    _G.md_preview_job = nil
    vim.notify('Markdown preview stopped', vim.log.levels.INFO)
  end
end, {})
command('MarkdownPreviewToggle', function()
  if _G.md_preview_job then
    vim.cmd('MarkdownPreviewStop')
  else
    vim.cmd('MarkdownPreviewStart')
  end
end, {})
map('n', '<leader>mp', '<cmd>MarkdownPreviewToggle<cr>', { desc = 'Toggle markdown preview' })

-- Open markdown in Deckset
command('OpenDeckset', 'execute \'silent !open -a Deckset "%"\'', {})

-- Convert markdown file to pdf using pandoc
command('MdToPdf', 'execute \'silent !pandoc "%" --listings -H ~/.config/pandoc/listings-setup.tex -o "%:r.pdf"\'', {})
command(
  'MdToPdfNumbered',
  'execute \'silent !pandoc "%" --listings -H ~/.config/pandoc/listings-setup.tex -o "%:r.pdf" --number-sections\'',
  {}
)
command('MdToPdfWatch', function()
  if _G.fswatch_job_id then
    print('Fswatch job already running.')
    return
  end
  vim.cmd(
    'execute \'silent !pandoc "%" --listings -H ~/.config/pandoc/listings-setup.tex -L ~/.config/pandoc/pagebreak.lua --include-in-header ~/.config/pandoc/header.tex -o "%:r.pdf"\''
  )
  local cmd = string.format(
    'fswatch -o "%s" | xargs -n1 -I{} pandoc "%s" --listings -H ~/.config/pandoc/listings-setup.tex -L ~/.config/pandoc/pagebreak.lua --include-in-header ~/.config/pandoc/header.tex -o "%s.pdf"',
    vim.fn.expand('%:p'),
    vim.fn.expand('%:p'),
    vim.fn.expand('%:r')
  )
  _G.fswatch_job_id = vim.fn.jobstart(cmd)
  if _G.fswatch_job_id ~= 0 then
    print('Started watching file changes.')
    vim.cmd('execute \'silent !zathura "%:r.pdf" & ~/scripts/focus_app zathura\'')
  else
    print('Failed to start watching file changes.')
  end
end, {})

-- Stop watching markdown file changes
command('MdToPdfStopWatch', function()
  if _G.fswatch_job_id then
    vim.fn.jobstop(_G.fswatch_job_id)
    print('Stopped watching file changes.')
    _G.fswatch_job_id = nil
  else
    print('No fswatch process found.')
  end
end, {})

map('n', '<leader>mw', function()
  if _G.fswatch_job_id then
    vim.cmd('MdToPdfStopWatch')
  else
    vim.cmd('MdToPdfWatch')
  end
end, { desc = 'Custom Command: Convert MD to PDF - Toggle Watch' })

-- Reveal file in finder (macOS)
command('RevealInFinder', 'execute \'silent !open -R "%"\'', {})
map('n', '<leader>;', ':RevealInFinder<cr>', { desc = 'Custom command: Reveal in Finder' })

command('OpenGithubRepo', function()
  local mode = vim.api.nvim_get_mode().mode
  local text = ''

  if mode == 'v' then
    text = vim.getVisualSelection()
    vim.fn.setreg('"', text) -- yank the selected text
  else
    local node = vim.treesitter.get_node() --[[@as TSNode]]
    -- Get the text of the node
    text = vim.treesitter.get_node_text(node, 0)
  end

  if text:match('^[%w%-%.%_%+]+/[%w%-%.%_%+]+$') == nil then
    local msg = string.format("OpenGithubRepo: '%s' Invalid format. Expected 'foo/bar' format.", text)
    vim.notify(msg, vim.log.levels.ERROR)
    return
  end

  local url = string.format('https://www.github.com/%s', text)
  print('Opening', url)
  vim.ui.open(url)
end, {})
map({ 'n', 'v' }, '<leader>og', '<cmd>OpenGithubRepo<cr>', { desc = 'Open Github Repo' })

command('LuaInspect', function()
  local sel = vim.fn.mode() == 'v' and vim.getVisualSelection() or nil
  if sel then
    local chunk, load_error = load('return ' .. sel)
    if chunk then
      local success, result = pcall(chunk)
      if success then
        vim.notify(vim.inspect(result), vim.log.levels.INFO)
      else
        vim.notify('Error evaluating expression: ' .. result, vim.log.levels.ERROR)
      end
    else
      vim.notify('Error loading expression: ' .. load_error, vim.log.levels.ERROR)
    end
  else
    vim.api.nvim_feedkeys(':lua print(vim.inspect())', 'n', true)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Left><Left>', true, false, true), 'n', true)
  end
end, {})
map({ 'n', 'v' }, '<leader>pi', '<cmd>LuaInspect<cr>', { desc = 'Lua Inspect' })

command('LuaPrint', function()
  if vim.fn.mode() == 'v' then
    vim.cmd('LuaInspect')
  else
    vim.api.nvim_feedkeys(':lua print()', 'n', true)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Left>', true, false, true), 'n', true)
  end
end, {})
map({ 'n', 'v' }, '<leader>pp', '<cmd>LuaPrint<cr>', { desc = 'Lua Print' })

command('TypstWatch', function()
  local input_file = vim.fn.expand('%:p')
  local output_file = vim.fn.expand('%:r') .. '.pdf'
  -- local cmd = string.format("typst watch %s --open sioyek", input_file)
  local cmd = string.format('typst watch "%s"', input_file)

  if _G.typst_job_id then
    vim.fn.jobstart({ 'sioyek', string.format('"%s"', output_file) })
    -- vim.fn.jobstart({ "sioyek", string.format('"%s"', output_file) }, { detach = true })
    print('Typst watch job already running.')
    return
  end

  _G.typst_job_id = vim.fn.jobstart(cmd)

  if _G.typst_job_id ~= 0 then
    print('Started watching Typst file changes.')

    vim.fn.jobstart({ 'sioyek', output_file })
    -- vim.cmd(string.format("execute 'silent !zathura \"%s\" & ~/scripts/focus_app zathura'", output_file))
  else
    print('Failed to start watching Typst file changes.')
  end
end, {})

command('TypstWatchStop', function()
  if _G.typst_job_id then
    vim.fn.jobstop(_G.typst_job_id)
    print('Stopped watching file changes.')
    _G.typst_job_id = nil
  else
    print('No typst watch process found.')
  end
end, {})

map('n', '<leader>mt', function()
  if _G.typst_job_id then
    vim.cmd('TypstWatchStop')
  else
    vim.cmd('TypstWatch')
  end
end, { desc = 'Custom command: TypstWatch Toggle' })

-- open same file in nvim in a new tmux pane
command('NewTmuxNvim', function()
  if os.getenv('TERM_PROGRAM') == 'tmux' and vim.fn.expand('%'):len() > 0 then
    -- vim.cmd("execute 'silent !tmux new-window nvim %'")
    vim.cmd("execute 'silent !tmux split-window -h -e NVIM_APPNAME=MinNvim nvim %'")
  else
    print('Nothing to open...')
  end
end, {})
map('n', '<leader>on', '<cmd>NewTmuxNvim<cr>', { desc = 'Open Same file in TMUX window' })

-- Function to shuffle lines
local function shuffle_lines()
  local start_line = vim.fn.line("'<")
  local end_line = vim.fn.line("'>")

  local lines = vim.fn.getline(start_line, end_line)

  math.randomseed(os.time())
  for i = #lines, 2, -1 do
    local j = math.random(i)
    lines[i], lines[j] = lines[j], lines[i]
  end

  vim.fn.setline(start_line, lines)
end
command('ShuffleLines', shuffle_lines, { range = true })

-- Command to copy bullet list without bullets
command('CopyNoBullets', function(cmd_opts)
  local lines = vim.fn.getline(cmd_opts.line1, cmd_opts.line2)
  if type(lines) == 'string' then lines = { lines } end
  local text = table.concat(lines, '\n')

  if #text > 0 then
    local cleaned_text = text:gsub('(%s*)%- ?', '%1')
    vim.fn.setreg('+', cleaned_text)
    print('Bullet list copied without bullets!')
  end
end, { range = true })
map('v', '<leader>cb', ':CopyNoBullets<CR>', { desc = 'Copy without bullets' })

command(
  'ConvertHEXtoUpper',
  function() vim.cmd("'<,'>s/#[0-9A-Fa-f]\\{3,8}\\(\"\\)\\?/\\=toupper(submatch(0))") end,
  { range = true }
)
map('v', '<leader>ch', ':ConvertHEXtoUpper<cr>', { desc = 'Covert HEX color to Uppercase' })

command('ToggleSpellCheck', function()
  if vim.wo.spell then
    vim.wo.spell = false
    vim.notify('Spell checking disabled', vim.log.levels.INFO)
  else
    vim.wo.spell = true
    vim.cmd('setlocal spell spelllang=en_us')
    vim.notify('Spell checking enabled', vim.log.levels.INFO)
  end
end, {})
map('n', '<leader>tS', ':ToggleSpellCheck<cr>', { desc = 'Toggle spell checking' })

-- Command to remove trailing whitespace
command('TrimTrailingWhitespace', function(cmd_opts)
  local start_line, end_line

  if cmd_opts.range == 0 then
    start_line = vim.fn.line('.')
    end_line = start_line
  else
    start_line = cmd_opts.line1
    end_line = cmd_opts.line2
  end

  -- Execute the substitution command
  vim.cmd(string.format('silent %d,%ds/\\s\\+$//e', start_line, end_line))
  vim.cmd('nohlsearch')

  -- Provide feedback
  local count = end_line - start_line + 1
  local message = 'Trimmed trailing whitespace from ' .. count .. ' line' .. (count > 1 and 's' or '')
  vim.notify(message, vim.log.levels.INFO)
end, { range = true })
map({ 'n', 'v' }, '<leader>cw', ':TrimTrailingWhitespace<cr>', { desc = 'Trim trailing whitespace' })

-- Command to shuffle paragraphs within a visual selection
command('ShuffleParagraphs', function(cmd_opts)
  local start_line = cmd_opts.line1
  local end_line = cmd_opts.line2

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  local paragraphs = {}
  local current_paragraph = {}

  for _, line in ipairs(lines) do
    table.insert(current_paragraph, line)
    -- Empty line marks paragraph boundary
    if line:match('^%s*$') then
      table.insert(paragraphs, current_paragraph)
      current_paragraph = {}
    end
  end

  if #current_paragraph > 0 then table.insert(paragraphs, current_paragraph) end

  math.randomseed(os.time())
  for i = #paragraphs, 2, -1 do
    local j = math.random(i)
    paragraphs[i], paragraphs[j] = paragraphs[j], paragraphs[i]
  end

  local shuffled_lines = {}
  for _, paragraph in ipairs(paragraphs) do
    for _, line in ipairs(paragraph) do
      table.insert(shuffled_lines, line)
    end
  end

  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, shuffled_lines)
end, { range = true })

-- Open Dash
command('OpenDashLang', function()
  local ft_to_key = { python = 'py' }
  local ft = vim.bo.filetype
  local key = ft_to_key[ft] or ft

  local query
  if vim.fn.mode():match('[vV]') then
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    local lines = vim.fn.getregion(start_pos, end_pos, { type = vim.fn.mode() })
    query = table.concat(lines, '\n')
  else
    -- Normal mode: word under cursor
    query = vim.fn.expand('<cword>')
  end

  query = vim.trim(query)
  if query == '' then
    vim.notify('Nothing to search for', vim.log.levels.WARN)
    return
  end

  vim.fn.system(string.format('open -g "dash-plugin://keys=%s&query=%s"', key, query))
end, { range = true })
map({ 'n', 'v' }, '<leader>sd', ':OpenDashLang<cr>', { desc = 'Open Dash Docs' })

--: Scratch to Quickfix {{{
-- Initially taken and modified from https://github.com/yobibyte/yobitools/blob/main/dotfiles/init.lua
local function scratch()
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'wipe'
  vim.bo.swapfile = false
end

_G.basic_excludes = { '.git', '*.egg-info', '__pycache__', 'wandb', 'target' }
_G.ext_excludes = vim.list_extend(vim.deepcopy(_G.basic_excludes), { '.venv' })

local function pre_search()
  if vim.bo.filetype == 'netrw' then
    return vim.b.netrw_curdir, _G.basic_excludes, {}
  else
    return vim.fn.getcwd(), _G.ext_excludes, {}
  end
end

local function scratch_to_quickfix(close_qf)
  local items, bufnr = {}, vim.api.nvim_get_current_buf()
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    if line ~= '' then
      local filename, lnum, text = line:match('^([^:]+):(%d+):(.*)$')
      if filename and lnum then
        table.insert(items, { filename = vim.fn.fnamemodify(filename, ':p'), lnum = tonumber(lnum), text = text }) -- for grep filename:line:text
      else
        lnum, text = line:match('^(%d+):(.*)$')
        if lnum and text then
          table.insert(items, { filename = vim.fn.bufname(vim.fn.bufnr('#')), lnum = tonumber(lnum), text = text }) -- for current buffer grep
        else
          table.insert(items, { filename = vim.fn.fnamemodify(line, ':p') }) -- for find results, only fnames
        end
      end
    end
  end
  vim.api.nvim_buf_delete(bufnr, { force = true })
  vim.fn.setqflist(items, 'r')
  vim.cmd('copen | cc')
  if close_qf then vim.cmd('cclose') end
end

vim.keymap.set('n', '<leader>sx', scratch_to_quickfix, { desc = 'Scratch to Quickfix' })

local function extcmd(cmd, qf, close_qf, novsplit)
  local output = vim.fn.systemlist(cmd)
  if not output or #output == 0 then return end
  vim.cmd(novsplit and 'enew' or 'vnew')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, output)
  scratch()
  if qf then scratch_to_quickfix(close_qf) end
end

vim.keymap.set('n', '<leader>sb', function()
  vim.ui.input({ prompt = '  > ' }, function(pat)
    if pat then extcmd("grep -iEn '" .. pat .. "' " .. vim.fn.shellescape(vim.api.nvim_buf_get_name(0)), false) end
  end)
end, { desc = 'Search Buffer - ScratchToQuickfix' })

vim.keymap.set('n', '<leader>sg', function()
  vim.ui.input({ prompt = '  > ' }, function(pat)
    if pat then
      local path, excludes, parts = pre_search()
      for _, pattern in ipairs(excludes) do
        table.insert(parts, string.format("--exclude-dir='%s'", pattern))
      end
      -- extcmd(string.format("grep -IEnr %s '%s' %s", table.concat(parts, " "), pat, path), true)
      extcmd(string.format("grep -IEnr %s '%s' %s", table.concat(parts, ' '), pat, path), false)
    end
  end)
end, { desc = 'Search Project - ScratchToQuickfix' })
--: }}}
