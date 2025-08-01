local M = {}

-- Window maximize toggle
vim.b.is_zoomed = false
vim.w.original_window_layout = {}

-- Toggle between maximized and normal window layout
function M.toggle_maximize_buffer()
  if not vim.b.is_zoomed then
    vim.w.original_window_layout = vim.api.nvim_call_function('winrestcmd', {})
    vim.cmd('wincmd _')
    vim.cmd('wincmd |')
    vim.b.is_zoomed = true
  else
    vim.api.nvim_call_function('execute', { vim.w.original_window_layout })
    vim.b.is_zoomed = false
  end
end

-- Center cursor in window, preserving position in insert mode
function M.cursorMoveAround()
  local win_height = vim.api.nvim_win_get_height(0)
  local cursor_winline = vim.fn.winline()
  local middle_line = math.floor(win_height / 2)

  local current_mode = vim.api.nvim_get_mode().mode
  if cursor_winline <= middle_line + 1 and cursor_winline >= middle_line - 1 then
    if current_mode == 'i' then
      local current_cursor_pos = vim.api.nvim_win_get_cursor(0)
      local current_row = current_cursor_pos[1]
      local current_col = current_cursor_pos[2]

      -- Center the screen without leaving insert mode
      vim.cmd('keepjumps normal! zt')
      -- Adjust the cursor position back to the original position
      vim.api.nvim_win_set_cursor(0, { current_row, current_col })
    else
      vim.cmd('normal! zt')
    end
  else
    if current_mode == 'i' then
      local current_cursor_pos = vim.api.nvim_win_get_cursor(0)
      local current_row = current_cursor_pos[1]
      local current_col = current_cursor_pos[2]

      -- Center the screen without leaving insert mode
      vim.cmd('keepjumps normal! zz')
      -- Adjust the cursor position back to the original position
      vim.api.nvim_win_set_cursor(0, { current_row, current_col })
    else
      vim.cmd('normal! zz')
    end
  end
end

-- Git diff function
function M.git_diff()
  local current_file = vim.fn.expand('%')
  if current_file == '' then
    print('No file name')
    return
  end

  -- Create vertical split with git HEAD version
  vim.cmd('vert new')
  vim.cmd('set bt=nofile')
  vim.cmd('r !git show HEAD:' .. vim.fn.shellescape(current_file))
  vim.cmd('0d_')
  vim.cmd('diffthis')
  vim.cmd('wincmd p')
  vim.cmd('diffthis')

  -- Set local keymap to quit diff mode and close scratch buffer
  vim.keymap.set('n', 'q', function()
    vim.cmd('diffoff!')
    local buffers = vim.api.nvim_list_bufs()
    for _, buf in ipairs(buffers) do
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == 'nofile' then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
  end, { buffer = true, desc = 'Quit diff and close scratch buffer(s)' })
end

-- Calculate startup time and format as a message string
local function get_startup_time_message(prefix)
  local startup_time_ns = vim.uv.hrtime() - vim.g.start_time
  local startup_time_ms = startup_time_ns / 1000000
  return (prefix or 'Loaded in ') .. string.format('%.2f', startup_time_ms) .. 'ms'
end

-- Display a centered startup screen with optional custom message and loading time
function M.show_startup_screen(custom_message, show_loading)
  -- Only show startup screen when no files are opened
  if vim.fn.argc() > 0 then return end

  -- Clear the screen and create new buffer
  vim.cmd('enew')
  vim.api.nvim_buf_set_name(0, '[Startup]')

  -- Get screen dimensions
  local height = vim.api.nvim_win_get_height(0)
  local width = vim.api.nvim_win_get_width(0)

  -- Determine message content
  local message_lines = {}

  if custom_message == nil then
    -- No arguments passed - show only startup time
    table.insert(message_lines, get_startup_time_message('Neovim loaded in '))
  elseif custom_message == '' and show_loading == false then
    -- Empty message with no loading - show nothing
    message_lines = {}
  else
    -- Custom message provided
    if type(custom_message) == 'string' then
      -- Split string by newlines
      for line in custom_message:gmatch('[^\r\n]+') do
        table.insert(message_lines, line)
      end
    elseif type(custom_message) == 'table' then
      -- Use table directly as lines
      message_lines = custom_message
    end

    -- Add loading message if show_loading is not explicitly false
    if show_loading ~= false then table.insert(message_lines, get_startup_time_message()) end
  end

  -- If no message lines, just set up empty buffer and return
  if #message_lines == 0 then
    -- Configure buffer settings for empty startup screen
    vim.api.nvim_set_option_value('modified', false, { buf = 0 })
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = 0 })
    vim.api.nvim_set_option_value('swapfile', false,  { buf = 0 })

    -- Hide all UI elements
    vim.wo.cursorline = false
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.wo.signcolumn = 'no'
    vim.o.laststatus = 0
    vim.o.ruler = false

    vim.g.startup_buffer_id = vim.api.nvim_get_current_buf()
    return
  end

  -- Calculate the maximum width needed for centering
  local max_message_width = 0
  for _, line in ipairs(message_lines) do
    max_message_width = math.max(max_message_width, #line)
  end

  -- Create empty lines to center vertically
  local lines = {}
  local total_message_height = #message_lines
  local start_row = math.floor((height - total_message_height) / 2)

  -- Add empty lines before message
  for _ = 1, start_row do
    table.insert(lines, '')
  end

  -- Add centered message lines (centered as a block)
  local message_start_row = start_row
  local block_padding = string.rep(' ', math.floor((width - max_message_width) / 2))

  for _, message_line in ipairs(message_lines) do
    -- Center each line within the block width
    local line_padding = string.rep(' ', math.floor((max_message_width - #message_line) / 2))
    table.insert(lines, block_padding .. line_padding .. message_line)
  end

  -- Add remaining empty lines
  local remaining_lines = height - start_row - total_message_height
  for _ = 1, remaining_lines do
    table.insert(lines, '')
  end

  -- Set the lines in buffer
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

  -- Clear the modified flag so no [+] appears
  vim.api.nvim_set_option_value('modified', false, { buf = 0 })

  -- Configure buffer settings
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = 0 })
  vim.api.nvim_set_option_value('swapfile', false, { buf = 0 })

  -- Modern highlighting with extmarks
  vim.api.nvim_set_hl(0, 'Startup', { fg = '#555555' })
  local ns_id = vim.api.nvim_create_namespace('startup_screen')

  -- Highlight each message line with proper block centering
  for i, message_line in ipairs(message_lines) do
    local line_padding = string.rep(' ', math.floor((max_message_width - #message_line) / 2))
    local total_padding = block_padding .. line_padding
    local line_row = message_start_row + i - 1
    vim.api.nvim_buf_set_extmark(0, ns_id, line_row, #total_padding, {
      end_col = #total_padding + #message_line,
      hl_group = 'Startup',
    })
  end

  -- Hide all UI elements for minimal startup screen
  vim.wo.cursorline = false
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = 'no'
  vim.o.laststatus = 0 -- Hide statusline
  vim.o.ruler = false -- Hide ruler

  -- Store buffer ID for later reference
  vim.g.startup_buffer_id = vim.api.nvim_get_current_buf()
end

-- Restore UI settings when leaving startup screen
function M.restore_ui_settings()
  local current_buf = vim.api.nvim_get_current_buf()
  if current_buf ~= vim.g.startup_buffer_id then
    -- Restore preferred settings
    vim.wo.signcolumn = 'yes:2'
    vim.o.laststatus = 2 -- Show statusline always
    vim.o.ruler = true -- Restore ruler
  end
end

-- Lazy loading utilities
-- Create a lazy loader for modules to improve startup time
function M.lazy_require(module_name)
  local loaded = false
  local module = nil

  return function()
    if not loaded then
      module = require(module_name)
      loaded = true
    end
    return module
  end
end

return M
