local M = {}

M.cache = {}

function M.get_backlinks(path)
  -- Check cache first
  if M.cache[path] then return M.cache[path] end

  local current_file = path
  local result = vim.fn.system(string.format('zk list -q -f json -l "%s"', current_file))
  -- print(result)

  if vim.v.shell_error == 0 then
    local paths = {}

    -- Parse JSON response
    local ok, json_data = pcall(vim.fn.json_decode, result)
    -- print(vim.inspect(json_data))
    if ok and json_data then
      for _, note in ipairs(json_data) do
        if note.path then table.insert(paths, note.path) end
      end
    end

    -- Cache the result
    M.cache[path] = paths
    return paths
  else
    M.cache[path] = {} -- Cache empty result to avoid retrying
    return {}
  end
end

-- Clear all cache
function M.clear_cache() M.cache = {} end

-- Clear cache for specific path
function M.clear_cache_for(path) M.cache[path] = nil end

function M.cache_info()
  local count = 0
  for _ in pairs(M.cache) do
    count = count + 1
  end
  return count, M.cache
end

-- Check if current buffer is in ZK directory
function M.is_zk_note()
  local zk_dir = vim.env.ZK_NOTEBOOK_DIR
  if not zk_dir then return false end

  local current_file = vim.fn.expand('%:p')
  return vim.startswith(current_file, zk_dir)
end

-- Namespace for our virtual text
local ns_id = vim.api.nvim_create_namespace('zk_backlinks')

-- Store backlink data for navigation
local backlink_data = {}

-- Add backlinks as virtual text at top of buffer
function M.show_backlinks()
  if not M.is_zk_note() then return end

  local current_file = vim.fn.expand('%:p')
  local backlinks = M.get_backlinks(current_file)

  if #backlinks == 0 then return end

  local bufnr = vim.api.nvim_get_current_buf()

  -- Clear existing backlinks
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  -- Store backlink data for this buffer
  backlink_data[bufnr] = backlinks

  -- Create all virtual lines in one extmark for proper ordering
  local virt_lines = {}

  -- Add empty line between title and backlinks
  table.insert(virt_lines, { { '', 'Normal' } })

  -- Add header
  local header_text = string.format('🔗 Backlinks (%d) - Press <Enter> or number to navigate:', #backlinks)
  table.insert(virt_lines, { { header_text, 'Comment' } })

  -- Add each backlink
  for i, link in ipairs(backlinks) do
    local display_text = string.format('  %d. %s', i, link)
    table.insert(virt_lines, { { display_text, 'Directory' } })
  end

  -- Add separator after backlinks
  table.insert(virt_lines, { { '', 'Normal' } })

  -- Add all virtual lines after line 0 (title)
  vim.api.nvim_buf_set_extmark(bufnr, ns_id, 0, 0, {
    virt_lines = virt_lines,
    virt_lines_above = false,
  })
end

-- Navigate to specific backlink by index
function M.navigate_to_backlink(index)
  local bufnr = vim.api.nvim_get_current_buf()
  local links = backlink_data[bufnr]
  if not links or #links == 0 then return false end

  -- If no index provided, navigate to first backlink
  index = index or 1

  local selected_link = links[index]
  if selected_link then
    local zk_dir = vim.env.ZK_NOTEBOOK_DIR
    local full_path = zk_dir and (zk_dir .. '/' .. selected_link) or selected_link
    vim.cmd('edit ' .. vim.fn.fnameescape(full_path))
    return true
  end

  return false
end

-- Check if cursor is near backlinks area
function M.is_in_backlinks_area()
  local cursor_line = vim.fn.line('.')
  local bufnr = vim.api.nvim_get_current_buf()

  -- Check if we have backlinks for this buffer
  local links = backlink_data[bufnr]
  if not links or #links == 0 then return false end

  -- Virtual text appears after line 1 (title), so backlinks area is:
  -- Line 1: title (navigation works here)
  -- Line 2: where virtual backlinks appear (cursor can't actually be here)
  -- We allow navigation when cursor is on the title line
  return cursor_line == 1
end

-- Clear backlinks display
function M.hide_backlinks()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  backlink_data[bufnr] = nil
end

-- Setup global cache invalidation (called once)
local global_setup_done = false
local function setup_global_cache_invalidation()
  if global_setup_done then return end
  global_setup_done = true

  local global_group = vim.api.nvim_create_augroup('ZKGlobalCacheInvalidation', { clear = true })

  -- Clear cache when ANY markdown file in ZK directory is written
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = global_group,
    pattern = '*.md',
    callback = function()
      local file_path = vim.fn.expand('<afile>:p')
      local zk_dir = vim.env.ZK_NOTEBOOK_DIR

      -- If the written file is in ZK directory, clear cache and refresh all ZK buffers
      if zk_dir and vim.startswith(file_path, zk_dir) then
        M.clear_cache()

        -- Refresh backlinks in all currently open ZK note buffers
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == 'markdown' then
            local buf_path = vim.api.nvim_buf_get_name(buf)
            if buf_path ~= '' and vim.startswith(buf_path, zk_dir) then
              -- Schedule update for this buffer
              vim.schedule(function()
                if vim.api.nvim_buf_is_valid(buf) then
                  local current_buf = vim.api.nvim_get_current_buf()
                  if buf == current_buf then
                    -- If it's the current buffer, refresh immediately
                    M.show_backlinks()
                  else
                    -- For other buffers, we'll refresh when they become active
                    -- Clear their cached data so it refreshes on BufEnter
                    backlink_data[buf] = nil
                  end
                end
              end)
            end
          end
        end
      end
    end,
  })
end

-- Setup autocommands for automatic backlink display
function M.setup_auto_backlinks()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Setup global cache invalidation (only once)
  setup_global_cache_invalidation()

  -- Show backlinks immediately!
  M.show_backlinks()

  -- Create buffer-local autocmds
  local group = vim.api.nvim_create_augroup('ZKBacklinks_' .. bufnr, { clear = true })

  -- Refresh backlinks on buffer enter (not on save, since global handler does that)
  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    buffer = bufnr,
    callback = function()
      if M.is_zk_note() then M.show_backlinks() end
    end,
  })

  -- Hide backlinks when leaving buffer
  vim.api.nvim_create_autocmd('BufLeave', {
    group = group,
    buffer = bufnr,
    callback = M.hide_backlinks,
  })

  -- Setup buffer-local keymaps
  vim.keymap.set('n', '<CR>', function()
    if M.is_in_backlinks_area() and M.navigate_to_backlink(1) then return end
    -- Default behavior: just press enter
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<CR>', true, false, true), 'n', false)
  end, { buffer = bufnr, silent = true, desc = 'Navigate to first backlink or normal enter' })

  -- Number keys 1-9 to navigate to specific backlinks
  for i = 1, 9 do
    vim.keymap.set('n', tostring(i), function()
      local links = backlink_data[bufnr]
      if links and links[i] and M.is_in_backlinks_area() then
        M.navigate_to_backlink(i)
      else
        -- Default behavior: insert the number
        vim.api.nvim_feedkeys(tostring(i), 'n', false)
      end
    end, { buffer = bufnr, silent = true, desc = 'Navigate to backlink ' .. i .. ' or insert number' })
  end
end

return M
