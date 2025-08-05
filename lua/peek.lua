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
local function create_popup_window(bufnr, title, custom_opts)
  custom_opts = custom_opts or {}

  local default_opts = {
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

  -- Merge custom options with defaults
  local opts = vim.tbl_deep_extend('force', default_opts, custom_opts)

  local win = vim.api.nvim_open_win(bufnr, false, opts)
  vim.api.nvim_set_option_value('scrolloff', 0, { win = win })
  vim.api.nvim_set_option_value('wrap', false, { win = win })

  return win
end

-- Add highlighting to line with configurable duration
local function add_line_highlight(bufnr, line, duration, namespace_suffix)
  duration = duration or 2000
  namespace_suffix = namespace_suffix or 'highlight'

  local ns_id = vim.api.nvim_create_namespace('peek_' .. namespace_suffix)
  local line_content = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ''
  local line_length = #line_content

  vim.api.nvim_buf_set_extmark(bufnr, ns_id, line - 1, 0, {
    end_row = line - 1,
    end_col = line_length > 0 and line_length or 1,
    hl_group = 'IncSearch',
    priority = 200,
  })

  -- Only set timeout if duration > 0 (permanent highlight if duration is 0 or nil)
  if duration > 0 then
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(bufnr) then vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1) end
    end, duration)
  end

  return ns_id
end

-- Clear highlight namespace
local function clear_line_highlight(bufnr, namespace_suffix)
  if vim.api.nvim_buf_is_valid(bufnr) then
    local ns_id = vim.api.nvim_create_namespace('peek_' .. namespace_suffix)
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  end
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

  -- Copy callback if provided (for diagnostics)
  if copy_callback then vim.keymap.set('n', 'y', copy_callback, { buffer = bufnr, desc = 'Copy content' }) end
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

  vim.lsp.buf_request(0, lsp_method, params, function(err, result)
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

    local ns_id = add_line_highlight(bufnr, line, 2000, 'definition_highlight')
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
local function setup_diagnostics_navigation(popup_win, bufnr, diagnostic_data, original_win)
  local current_highlighted_line = nil
  local original_bufnr = vim.api.nvim_win_get_buf(original_win)

  vim.api.nvim_create_autocmd('CursorMoved', {
    buffer = bufnr,
    callback = function()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local line_idx = cursor[1]
      if diagnostic_data[line_idx] and vim.api.nvim_win_is_valid(original_win) then
        local diagnostic = diagnostic_data[line_idx]
        local target_line = diagnostic.lnum + 1

        -- Only update if we're highlighting a different line
        if current_highlighted_line ~= target_line then
          -- Clear previous highlight
          if current_highlighted_line then clear_line_highlight(original_bufnr, 'diagnostic_highlight') end

          -- Position diagnostic line with offset from top (5 lines or scrolloff)
          local scrolloff = vim.api.nvim_get_option_value('scrolloff', { win = original_win })
          local offset = math.max(5, scrolloff)
          local line = target_line
          local col = diagnostic.col
          local topline = math.max(1, line - offset)

          vim.api.nvim_win_set_cursor(original_win, { line, col })
          vim.api.nvim_win_call(
            original_win,
            function() vim.fn.winrestview({ topline = topline, lnum = line, col = col }) end
          )

          -- Apply permanent highlight to new diagnostic line
          add_line_highlight(original_bufnr, target_line, 0, 'diagnostic_highlight')
          current_highlighted_line = target_line
        end
      end
    end,
  })
  vim.keymap.set('n', '<CR>', function()
    if not diagnostic_data then
      print('No diagnostic data available')
      return
    end

    local cursor = vim.api.nvim_win_get_cursor(popup_win)
    local line_idx = cursor[1]
    if diagnostic_data[line_idx] then
      local diagnostic = diagnostic_data[line_idx]
      -- Clear diagnostic highlight before closing
      clear_line_highlight(original_bufnr, 'diagnostic_highlight')
      vim.api.nvim_win_close(popup_win, true)
      if vim.api.nvim_win_is_valid(original_win) then
        vim.api.nvim_set_current_win(original_win)
        vim.api.nvim_win_set_cursor(original_win, { diagnostic.lnum + 1, diagnostic.col })
      end
    end
  end, { buffer = bufnr, desc = 'Jump to diagnostic' })
end

function M.peek_diagnostics()
  local diagnostics_bufnr, err, diagnostic_data = create_diagnostics_buffer()
  if not diagnostics_bufnr then
    print(err)
    return
  end

  local original_win = vim.api.nvim_get_current_win()
  local current_file = vim.fn.expand('%:t')
  local title = ' Diagnostics @' .. current_file .. ' '

  -- Position popup at bottom-right corner, fixed position
  local win_height = vim.api.nvim_win_get_height(original_win)
  local win_width = vim.api.nvim_win_get_width(original_win)

  local popup_width = math.min(80, math.floor(win_width * 0.7))
  local popup_height = math.min(15, math.floor(win_height * 0.3))

  local win = create_popup_window(diagnostics_bufnr, title, {
    relative = 'win',
    win = original_win,
    width = popup_width,
    height = popup_height,
    row = win_height - popup_height - 2,
    col = win_width - popup_width - 1,
  })

  local copy_callback = create_diagnostics_copy_callback(diagnostic_data)
  local ns_id = vim.api.nvim_create_namespace('peek_diagnostics')

  -- Create custom close function that clears diagnostic highlights
  local close_with_cleanup = function()
    clear_line_highlight(vim.api.nvim_win_get_buf(original_win), 'diagnostic_highlight')
    local close_popup = create_close_function(win, diagnostics_bufnr, ns_id)
    close_popup()
  end

  -- Use custom popup management with cleanup
  setup_popup_keymaps(win, diagnostics_bufnr, vim.api.nvim_get_current_buf(), close_with_cleanup, copy_callback)
  setup_popup_autocmds(win, vim.api.nvim_get_current_buf(), original_win, close_with_cleanup)
  setup_diagnostics_navigation(win, diagnostics_bufnr, diagnostic_data, original_win)
end

function M.peek_definition() peek_lsp_result('textDocument/definition', 'Definition', 'No definition found') end

function M.peek_implementation()
  peek_lsp_result('textDocument/implementation', 'Implementation', 'No implementation found')
end

return M
