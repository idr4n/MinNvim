local M = {}

-- Window maximize toggle
vim.b.is_zoomed = false
vim.w.original_window_layout = {}

function M.toggle_maximize_buffer()
  if not vim.b.is_zoomed then
    vim.w.original_window_layout = vim.api.nvim_call_function("winrestcmd", {})
    vim.cmd("wincmd _")
    vim.cmd("wincmd |")
    vim.b.is_zoomed = true
  else
    vim.api.nvim_call_function("execute", { vim.w.original_window_layout })
    vim.b.is_zoomed = false
  end
end

function M.cursorMoveAround()
  local win_height = vim.api.nvim_win_get_height(0)
  local cursor_winline = vim.fn.winline()
  local middle_line = math.floor(win_height / 2)

  local current_mode = vim.api.nvim_get_mode().mode
  if cursor_winline <= middle_line + 1 and cursor_winline >= middle_line - 1 then
    if current_mode == "i" then
      local current_cursor_pos = vim.api.nvim_win_get_cursor(0)
      local current_row = current_cursor_pos[1]
      local current_col = current_cursor_pos[2]

      -- Center the screen without leaving insert mode
      vim.cmd("keepjumps normal! zt")
      -- Adjust the cursor position back to the original position
      vim.api.nvim_win_set_cursor(0, { current_row, current_col })
    else
      vim.cmd("normal! zt")
    end
  else
    if current_mode == "i" then
      local current_cursor_pos = vim.api.nvim_win_get_cursor(0)
      local current_row = current_cursor_pos[1]
      local current_col = current_cursor_pos[2]

      -- Center the screen without leaving insert mode
      vim.cmd("keepjumps normal! zz")
      -- Adjust the cursor position back to the original position
      vim.api.nvim_win_set_cursor(0, { current_row, current_col })
    else
      vim.cmd("normal! zz")
    end
  end
end

-- Git diff function
function M.git_diff()
  local current_file = vim.fn.expand("%")
  if current_file == "" then
    print("No file name")
    return
  end

  -- Create vertical split with git HEAD version
  vim.cmd("vert new")
  vim.cmd("set bt=nofile")
  vim.cmd("r !git show HEAD:" .. vim.fn.shellescape(current_file))
  vim.cmd("0d_")
  vim.cmd("diffthis")
  vim.cmd("wincmd p")
  vim.cmd("diffthis")

  -- Set local keymap to quit diff mode and close scratch buffer
  vim.keymap.set("n", "q", function()
    vim.cmd("diffoff!")
    local buffers = vim.api.nvim_list_bufs()
    for _, buf in ipairs(buffers) do
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "nofile" then
        vim.api.nvim_buf_delete(buf, { force = true })
        break
      end
    end
  end, { buffer = true, desc = "Quit diff and close scratch buffer" })
end

return M
