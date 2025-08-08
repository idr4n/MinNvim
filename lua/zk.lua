local M = {}
local zk_dir = vim.env.ZK_NOTEBOOK_DIR

M.cache = {}
local pre_save_links = {}

function M.get_backlinks(path)
  if M.cache[path] then return M.cache[path] end

  local result = vim.fn.system(string.format('zk list -q -f json -l "%s"', path))
  local paths = {}

  if vim.v.shell_error == 0 then
    local ok, json_data = pcall(vim.fn.json_decode, result)
    if ok and json_data then
      for _, note in ipairs(json_data) do
        if note.path then table.insert(paths, note.path) end
      end
    end
  end

  M.cache[path] = paths
  return paths
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
function M.is_zk_note(bufnr)
  if not zk_dir then return false end

  local file_path = bufnr and vim.api.nvim_buf_get_name(bufnr) or vim.fn.expand('%:p')
  return vim.startswith(file_path, zk_dir)
end

-- Namespace for our virtual text
local ns_id = vim.api.nvim_create_namespace('zk_backlinks')

-- Store backlink data for navigation
local backlink_data = {}

-- Buffer utilities
local function get_current_buffer_info()
  local bufnr = vim.api.nvim_get_current_buf()
  local file_path = vim.fn.expand('%:p')
  return bufnr, file_path
end

local function get_zk_file_path(relative_path) return zk_dir and (zk_dir .. '/' .. relative_path) or relative_path end

local function is_valid_zk_buffer(bufnr, zk_directory)
  if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then return false end

  if vim.bo[bufnr].filetype ~= 'markdown' then return false end

  local buf_path = vim.api.nvim_buf_get_name(bufnr)
  return buf_path ~= '' and vim.startswith(buf_path, zk_directory)
end

local function create_backlink_virtual_lines(backlinks)
  local virt_lines = {}

  -- empty line between title and backlinks
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

  return virt_lines
end

local function setup_navigation_keymaps(bufnr)
  -- Enter key navigation
  vim.keymap.set('n', '<CR>', function()
    if M.is_in_backlinks_area() and M.navigate_to_backlink(1) then return end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<CR>', true, false, true), 'n', false)
  end, { buffer = bufnr, silent = true, desc = 'Navigate to first backlink or normal enter' })

  -- Number keys 1-9 for specific backlink navigation
  for i = 1, 9 do
    vim.keymap.set('n', tostring(i), function()
      local links = backlink_data[bufnr]
      if links and links[i] and M.is_in_backlinks_area() then
        M.navigate_to_backlink(i)
      else
        vim.api.nvim_feedkeys(tostring(i), 'n', false)
      end
    end, { buffer = bufnr, silent = true, desc = 'Navigate to backlink ' .. i .. ' or insert number' })
  end
end

-- Add backlinks as virtual text at top of buffer
function M.show_backlinks()
  local bufnr, current_file = get_current_buffer_info()
  if not M.is_zk_note(bufnr) then return end

  local backlinks = M.get_backlinks(current_file)
  if #backlinks == 0 then return end

  -- Clear existing backlinks
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

  -- Store backlink data for this buffer
  backlink_data[bufnr] = backlinks

  -- Create and display virtual lines
  local virt_lines = create_backlink_virtual_lines(backlinks)
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

  index = index or 1
  local selected_link = links[index]
  if selected_link then
    local full_path = get_zk_file_path(selected_link)
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

-- Get list of notes that a file links to
local function get_linked_notes(file_path)
  local result = vim.fn.system(string.format('zk list -q -f json -L "%s"', file_path))
  local linked_notes = {}

  if vim.v.shell_error == 0 then
    local ok, json_data = pcall(vim.fn.json_decode, result)
    if ok and json_data then
      for _, note in ipairs(json_data) do
        if note.path then
          local abs_path = get_zk_file_path(note.path)
          linked_notes[abs_path] = true
        end
      end
    end
  end

  return linked_notes
end

-- update only affected buffers after saving
local function refresh_affected_buffers(saved_file_path)
  -- Get current links after save
  local post_save_links = get_linked_notes(saved_file_path)
  local pre_links = pre_save_links[saved_file_path] or {}

  -- Find all notes that were affected (added or removed links)
  local affected_notes = {}

  -- Add notes that are now linked (new links)
  for note_path, _ in pairs(post_save_links) do
    affected_notes[note_path] = true
  end

  -- Add notes that were previously linked but no longer (removed links)
  for note_path, _ in pairs(pre_links) do
    affected_notes[note_path] = true
  end

  -- Clear cache for the saved file and all affected notes
  M.clear_cache_for(saved_file_path)
  for note_path, _ in pairs(affected_notes) do
    M.clear_cache_for(note_path)
  end

  -- Find and refresh only the open buffers that correspond to affected notes
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if is_valid_zk_buffer(buf, zk_dir) then
      local buf_path = vim.api.nvim_buf_get_name(buf)

      -- Check if this buffer is one of the affected notes (but not the saved file itself)
      if affected_notes[buf_path] and buf_path ~= saved_file_path then
        -- Clear cached data so it refreshes on BufEnter
        backlink_data[buf] = nil
      end
    end
  end

  -- Clean up pre-save data
  pre_save_links[saved_file_path] = nil
end

-- Setup global cache invalidation (called once)
local global_setup_done = false
local function setup_global_cache_invalidation()
  if global_setup_done then return end
  global_setup_done = true

  local global_group = vim.api.nvim_create_augroup('ZKGlobalCacheInvalidation', { clear = true })

  -- Capture links before saving
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = global_group,
    pattern = '*.md',
    callback = function()
      local file_path = vim.fn.expand('<afile>:p')

      if zk_dir and vim.startswith(file_path, zk_dir) then pre_save_links[file_path] = get_linked_notes(file_path) end
    end,
  })

  -- Update affected buffers after saving
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = global_group,
    pattern = '*.md',
    callback = function()
      local file_path = vim.fn.expand('<afile>:p')

      if zk_dir and vim.startswith(file_path, zk_dir) then refresh_affected_buffers(file_path) end
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
      if M.is_zk_note(bufnr) then M.show_backlinks() end
    end,
  })

  -- Hide backlinks when leaving buffer
  vim.api.nvim_create_autocmd('BufLeave', {
    group = group,
    buffer = bufnr,
    callback = M.hide_backlinks,
  })

  -- Setup buffer-local keymaps
  setup_navigation_keymaps(bufnr)
end

return M
