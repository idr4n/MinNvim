local M = {}

-- Helper function to format path for display
local function format_path_for_title(filepath, max_length)
  max_length = max_length or 50 -- Default max length
  local cwd = vim.fn.getcwd()
  local full_path = vim.fn.fnamemodify(filepath, ':p')

  -- Check if file is within current working directory
  local display_path
  if vim.startswith(full_path, cwd) then
    -- Use relative path
    display_path = vim.fn.fnamemodify(full_path, ':.')
  else
    -- Use path with ~ for home
    display_path = vim.fn.fnamemodify(full_path, ':~')
  end

  -- Only shorten if path exceeds max_length
  if #display_path > max_length then display_path = vim.fn.pathshorten(display_path) end

  return display_path
end

function M.pick_definition()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    print('No LSP client attached')
    return
  end

  local client = clients[1]
  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)

  -- Changed from 'textDocument/implementation' to 'textDocument/definition'
  vim.lsp.buf_request(0, 'textDocument/definition', params, function(err, result, ctx, config)
    if err or not result or vim.tbl_isempty(result) then
      print('No definition found')
      return
    end

    local location = result[1] or result
    local uri = location.uri or location.targetUri
    local range = location.range or location.targetSelectionRange or location.targetRange

    -- Open or get the buffer
    local bufnr = vim.uri_to_bufnr(uri)
    vim.fn.bufload(bufnr)

    -- Get the file path and format it for the title
    local filepath = vim.uri_to_fname(uri)
    local formatted_path = format_path_for_title(filepath)

    -- Popup window (10 lines, positioned near cursor)
    local opts = {
      style = 'minimal',
      relative = 'cursor',
      width = 80,
      height = 10,
      row = 1,
      col = 0,
      border = 'rounded',
      title = ' Definition @' .. formatted_path .. ' ',
      title_pos = 'center',
      zindex = 1000,
    }

    local win = vim.api.nvim_open_win(bufnr, false, opts) -- Still no initial focus

    -- Jump to the definition line in the popup
    local line = range.start.line + 1
    local col = range.start.character
    vim.api.nvim_win_set_cursor(win, { line, col })

    -- Center the line in the popup window
    vim.api.nvim_win_call(win, function() vim.cmd('normal! zz') end)

    -- Add temporary highlighting to the definition line
    local ns_id = vim.api.nvim_create_namespace('definition_highlight')
    local line_content = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1] or ''
    local line_length = #line_content
    vim.api.nvim_buf_set_extmark(bufnr, ns_id, line - 1, 0, {
      end_row = line - 1,
      end_col = line_length > 0 and line_length or 1, -- Highlight entire line
      hl_group = 'Search',
      priority = 200,
    })

    -- Auto-remove highlight after 1 second
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(bufnr) then vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1) end
    end, 1000)

    -- Function to close the popup
    local function close_popup()
      if vim.api.nvim_win_is_valid(win) then
        -- Clear highlight immediately when closing popup
        if vim.api.nvim_buf_is_valid(bufnr) then vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1) end
        vim.api.nvim_win_close(win, true)
      end
    end

    -- Close with 'q' when in the popup
    vim.keymap.set('n', 'q', close_popup, {
      buffer = bufnr,
      noremap = true,
      silent = true,
    })

    -- Store original buffer and window for smart auto-close
    local original_buf = vim.api.nvim_get_current_buf()
    local original_win = vim.api.nvim_get_current_win()

    -- Smart auto-close: only close when cursor moves in the ORIGINAL buffer
    local close_autocmd = vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      buffer = original_buf, -- Only watch the original buffer
      callback = function()
        -- Only close if we're still in the original buffer/window
        local current_buf = vim.api.nvim_get_current_buf()
        local current_win = vim.api.nvim_get_current_win()

        if current_buf == original_buf and current_win == original_win then
          close_popup()
          return true -- Remove the autocmd
        end
      end,
    })

    -- Also close if user switches away from both windows
    vim.api.nvim_create_autocmd('BufLeave', {
      buffer = original_buf,
      once = true,
      callback = function()
        -- Small delay to allow switching to popup
        vim.defer_fn(function()
          local current_win = vim.api.nvim_get_current_win()
          if current_win ~= win then close_popup() end
        end, 50)
      end,
    })

    -- Clean up autocmd when window is closed manually
    vim.api.nvim_create_autocmd('WinClosed', {
      pattern = tostring(win),
      once = true,
      callback = function()
        if close_autocmd then vim.api.nvim_del_autocmd(close_autocmd) end
      end,
    })

    -- Optional: Add a keymap to focus the popup window
    vim.keymap.set('n', '<C-w>p', function()
      if vim.api.nvim_win_is_valid(win) then vim.api.nvim_set_current_win(win) end
    end, { buffer = original_buf, desc = 'Focus definition popup' })
  end)
end

return M
