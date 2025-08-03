local M = {}

-- Helper function to format path for display
local function format_path_for_title(filepath, max_length)
  max_length = max_length or 50
  local cwd = vim.fn.getcwd()
  local full_path = vim.fn.fnamemodify(filepath, ':p')

  local display_path
  if vim.startswith(full_path, cwd) then
    display_path = vim.fn.fnamemodify(full_path, ':.')
  else
    display_path = vim.fn.fnamemodify(full_path, ':~')
  end

  if #display_path > max_length then display_path = vim.fn.pathshorten(display_path) end

  return display_path
end

-- Calculate dynamic z-index for proper stacking
local function calculate_zindex()
  local base_zindex = 1000
  local current_zindex = base_zindex

  for _, win_id in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win_id) then
      local win_config = vim.api.nvim_win_get_config(win_id)
      if win_config.relative ~= '' and win_config.zindex and win_config.zindex >= current_zindex then
        current_zindex = win_config.zindex + 10
      end
    end
  end

  return current_zindex
end

-- Create and configure popup window
local function create_popup_window(bufnr, title)
  local opts = {
    style = 'minimal',
    relative = 'cursor',
    width = 80,
    height = 15,
    row = 1,
    col = 0,
    border = 'rounded',
    title = title,
    title_pos = 'center',
    zindex = calculate_zindex(),
  }

  local win = vim.api.nvim_open_win(bufnr, false, opts)
  vim.api.nvim_set_option_value('scrolloff', 0, { win = win })

  return win
end

-- Add highlighting to definition line
local function add_line_highlight(bufnr, line)
  local ns_id = vim.api.nvim_create_namespace('peek_highlight')
  local line_content = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ''
  local line_length = #line_content

  vim.api.nvim_buf_set_extmark(bufnr, ns_id, line - 1, 0, {
    end_row = line - 1,
    end_col = line_length > 0 and line_length or 1,
    hl_group = 'IncSearch',
    priority = 200,
  })

  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(bufnr) then vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1) end
  end, 2000)

  return ns_id
end

-- Create popup close function
local function create_close_function(win, bufnr, ns_id)
  return function()
    if vim.api.nvim_win_is_valid(win) then
      if vim.api.nvim_buf_is_valid(bufnr) then vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1) end
      vim.api.nvim_win_close(win, true)
    end
  end
end

-- Set up popup keymaps
local function setup_popup_keymaps(win, bufnr, original_buf, close_popup, copy_callback)
  vim.keymap.set('n', 'q', close_popup, {
    buffer = bufnr,
    noremap = true,
    silent = true,
  })

  vim.keymap.set('n', '<C-w>p', function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_set_current_win(win) end
  end, { buffer = original_buf, desc = 'Peek - Focus popup' })

  vim.keymap.set('n', '<C-f>', function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_call(win, function() vim.cmd('normal! \5') end) end
  end, { buffer = original_buf })

  vim.keymap.set('n', '<C-b>', function()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_call(win, function() vim.cmd('normal! \25') end) end
  end, { buffer = original_buf })

  if copy_callback then
    vim.keymap.set('n', 'yp', copy_callback, {
      buffer = bufnr,
      noremap = true,
      silent = true,
      desc = 'Copy to clipboard',
    })
    vim.keymap.set('n', 'yp', copy_callback, {
      buffer = original_buf,
      noremap = true,
      silent = true,
      desc = 'Copy to clipboard',
    })
  end
end

-- Set up popup autocmds
local function setup_popup_autocmds(win, original_buf, original_win, close_popup)
  local close_autocmd = vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    buffer = original_buf,
    callback = function()
      local current_buf = vim.api.nvim_get_current_buf()
      local current_win = vim.api.nvim_get_current_win()

      if current_buf == original_buf and current_win == original_win then
        close_popup()
        return true
      end
    end,
  })

  vim.api.nvim_create_autocmd('BufLeave', {
    buffer = original_buf,
    once = true,
    callback = function()
      vim.defer_fn(function()
        local current_win = vim.api.nvim_get_current_win()
        if current_win ~= win then close_popup() end
      end, 50)
    end,
  })

  vim.api.nvim_create_autocmd('WinClosed', {
    pattern = tostring(win),
    once = true,
    callback = function()
      if close_autocmd then vim.api.nvim_del_autocmd(close_autocmd) end
    end,
  })
end

-- Set up popup window keymaps and autocmds
local function setup_popup_management(win, bufnr, ns_id, copy_callback)
  local original_buf = vim.api.nvim_get_current_buf()
  local original_win = vim.api.nvim_get_current_win()

  local close_popup = create_close_function(win, bufnr, ns_id)
  setup_popup_keymaps(win, bufnr, original_buf, close_popup, copy_callback)
  setup_popup_autocmds(win, original_buf, original_win, close_popup)
end

-- Generic peek function that works with any LSP method
local function peek_lsp_result(lsp_method, title_prefix, no_result_msg)
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    print('No LSP client attached')
    return
  end

  local client = clients[1]
  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)

  vim.lsp.buf_request(0, lsp_method, params, function(err, result, ctx, config)
    if err or not result or vim.tbl_isempty(result) then
      print(no_result_msg)
      return
    end

    local location = result[1] or result
    local uri = location.uri or location.targetUri
    local range = location.range or location.targetSelectionRange or location.targetRange

    local bufnr = vim.uri_to_bufnr(uri)
    vim.fn.bufload(bufnr)

    local filepath = vim.uri_to_fname(uri)
    local formatted_path = format_path_for_title(filepath)
    local title = ' ' .. title_prefix .. ' @' .. formatted_path .. ' '

    local win = create_popup_window(bufnr, title)

    local line = range.start.line + 1
    local col = range.start.character
    vim.api.nvim_win_set_cursor(win, { line, col })

    vim.api.nvim_win_call(win, function() vim.fn.winrestview({ topline = line, lnum = line, col = col }) end)

    local ns_id = add_line_highlight(bufnr, line)
    setup_popup_management(win, bufnr, ns_id)
  end)
end

-- Create diagnostics popup buffer with formatted content
local function create_diagnostics_buffer()
  local diagnostics = vim.diagnostic.get(0)
  if #diagnostics == 0 then return nil, 'No diagnostics found' end

  local bufnr = vim.api.nvim_create_buf(false, true)
  local lines = {}
  local diagnostic_data = {}

  for _, diagnostic in ipairs(diagnostics) do
    local severity = vim.diagnostic.severity[diagnostic.severity]
    local line_num = diagnostic.lnum + 1
    local col_num = diagnostic.col + 1
    local message = diagnostic.message:gsub('\n', ' ')

    local formatted_line = string.format('[%s] Line %d:%d - %s', severity, line_num, col_num, message)
    table.insert(lines, formatted_line)
    table.insert(diagnostic_data, diagnostic)
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = bufnr })
  vim.api.nvim_set_option_value('filetype', 'diagnostics', { buf = bufnr })

  return bufnr, nil, diagnostic_data
end

-- Create copy callback for diagnostics
local function create_diagnostics_copy_callback(diagnostic_data)
  return function()
    if not diagnostic_data then
      print('No diagnostic data available')
      return
    end

    local all_diagnostics = {}
    for _, diagnostic in ipairs(diagnostic_data) do
      local severity = vim.diagnostic.severity[diagnostic.severity]
      local line_num = diagnostic.lnum + 1
      local col_num = diagnostic.col + 1
      local message = diagnostic.message

      table.insert(
        all_diagnostics,
        string.format('[%s] %s:%d:%d - %s', severity, vim.fn.expand('%'), line_num, col_num, message)
      )
    end

    local content = table.concat(all_diagnostics, '\n')
    vim.fn.setreg('+', content)
    print('Diagnostics copied to clipboard')
  end
end

-- Set up diagnostics navigation keymaps
local function setup_diagnostics_navigation(win, bufnr, diagnostic_data)
  vim.keymap.set('n', '<CR>', function()
    if not diagnostic_data then
      print('No diagnostic data available')
      return
    end

    local cursor = vim.api.nvim_win_get_cursor(win)
    local line_idx = cursor[1]
    if diagnostic_data[line_idx] then
      local diagnostic = diagnostic_data[line_idx]
      vim.api.nvim_win_close(win, true)
      vim.api.nvim_win_set_cursor(0, { diagnostic.lnum + 1, diagnostic.col })
    end
  end, { buffer = bufnr, desc = 'Jump to diagnostic' })
end

function M.peek_diagnostics()
  local diagnostics_bufnr, err, diagnostic_data = create_diagnostics_buffer()
  if not diagnostics_bufnr then
    print(err)
    return
  end

  local current_file = vim.fn.expand('%:t')
  local title = ' Diagnostics @' .. current_file .. ' '
  local win = create_popup_window(diagnostics_bufnr, title)
  vim.api.nvim_set_option_value('wrap', false, { win = win })

  local copy_callback = create_diagnostics_copy_callback(diagnostic_data)
  local ns_id = vim.api.nvim_create_namespace('peek_diagnostics')

  setup_popup_management(win, diagnostics_bufnr, ns_id, copy_callback)
  setup_diagnostics_navigation(win, diagnostics_bufnr, diagnostic_data)
end

function M.peek_definition() peek_lsp_result('textDocument/definition', 'Definition', 'No definition found') end

function M.peek_implementation()
  peek_lsp_result('textDocument/implementation', 'Implementation', 'No implementation found')
end

return M
