-- Custom statusline

local M = {}

---source: modified from https://github.com/MariaSolOs/dotfiles
---Keeps track of the highlight groups already created.
---@type table<string, boolean>
local statusline_hls = {}

---Get or create a highlight group for statusline components
---@param hl_fg string Foreground color (hex color or highlight group name)
---@param hl_bg? string Background color (hex color or highlight group name, defaults to 'Normal')
---@return string The highlight group escape sequence
function M.get_or_create_hl(hl_fg, hl_bg)
  hl_bg = hl_bg or 'Normal'
  local sanitized_hl_fg = hl_fg:gsub('#', '')
  local sanitized_hl_bg = hl_bg:gsub('#', '')
  local hl_name = 'SL' .. sanitized_hl_fg .. sanitized_hl_bg

  if not statusline_hls[hl_name] then
    -- If not in the cache, create the highlight group
    local bg_hl
    if hl_bg:match('^#') then
      -- If hl_bg starts with #, it's a hex color
      bg_hl = { bg = hl_bg }
    else
      -- Otherwise treat it as highlight group name
      bg_hl = vim.api.nvim_get_hl(0, { name = hl_bg })
    end

    local fg_hl
    if hl_fg:match('^#') then
      -- If hl_fg starts with #, it's a hex color
      fg_hl = { fg = hl_fg }
    else
      -- Otherwise treat it as highlight group name
      fg_hl = vim.api.nvim_get_hl(0, { name = hl_fg })
    end

    if not bg_hl.bg then bg_hl = vim.api.nvim_get_hl(0, { name = 'Statusline' }) end
    if not fg_hl.fg then fg_hl = vim.api.nvim_get_hl(0, { name = 'Statusline' }) end

    vim.api.nvim_set_hl(0, hl_name, {
      bg = bg_hl.bg and (type(bg_hl.bg) == 'string' and bg_hl.bg or ('#%06x'):format(bg_hl.bg)) or 'none',
      fg = fg_hl.fg and (type(fg_hl.fg) == 'string' and fg_hl.fg or ('#%06x'):format(fg_hl.fg)) or 'none',
    })
    statusline_hls[hl_name] = true
  end

  return '%#' .. hl_name .. '#'
end

---Create a highlighted string with the specified highlight group
---@param hl string The highlight group name
---@param str string The string to highlight
---@return string The formatted highlight string
local function hl_str(hl, str) return '%#' .. hl .. '#' .. str .. '%*' end

---Get the current working directory with resolved symlinks
---@return string The resolved current working directory path
local function get_cwd()
  local function realpath(path)
    if path == '' or path == nil then return nil end
    return vim.loop.fs_realpath(path) or path
  end

  return realpath(vim.loop.cwd()) or ''
end

---Create a function that returns a prettified directory path for the current file
---Truncates long paths and removes the current working directory prefix
---@return fun():string Function that returns the formatted directory path
local function pretty_dirpath()
  return function()
    local path = vim.fn.expand('%:p') --[[@as string]]

    if path == '' then return '' end
    local cwd = get_cwd()

    if path:find(cwd, 1, true) == 1 then path = path:sub(#cwd + 2) end

    local sep = package.config:sub(1, 1)
    local parts = vim.split(path, '[\\/]')
    table.remove(parts)
    if #parts > 3 then parts = { parts[1], '…', parts[#parts - 1], parts[#parts] } end

    return #parts > 0 and (table.concat(parts, sep)) or ''
  end
end

---Generate padding spaces
---@param nr? number Number of spaces to generate (defaults to 1)
---@return string String of spaces
function M.padding(nr)
  nr = nr or 1
  return string.rep(' ', nr)
end

---Generate file information for the statusline (directory, filename, modified status)
---@return string Formatted file information string
function M.fileinfo()
  local dir = pretty_dirpath()()
  local pretty_dir = '╼ ' .. dir
  local path = vim.fn.expand('%:t')
  local name = (path == '' and 'Empty ') or path:match('([^/\\]+)[/\\]*$')
  local modified = hl_str('DiagnosticError', ' %m') or ''
  return ' ' .. (dir ~= '' and pretty_dir .. '  ' or '') .. name .. modified .. ' %r%h%w '
end

---Get cursor position formatted for statusline
---@return string Formatted position string (line:column)
function M.get_position() return ' %3l:%-2c ' end

---@param opts? {show_count?: boolean} Options table with show_count defaulting to false
---@return string
function M.lsp_diagnostics(opts)
  opts = opts or {}
  local show_count = opts.show_count or false

  local function get_severity(s) return #vim.diagnostic.get(0, { severity = s }) end

  local result = {
    errors = get_severity(vim.diagnostic.severity.ERROR),
    warnings = get_severity(vim.diagnostic.severity.WARN),
    info = get_severity(vim.diagnostic.severity.INFO),
    hints = get_severity(vim.diagnostic.severity.HINT),
  }

  local total = result.errors + result.warnings + result.hints + result.info
  local errors = ''
  local warnings = ''
  local info = ''
  local hints = ''

  local icon = '▫'

  if result.errors > 0 then
    errors = M.get_or_create_hl('DiagnosticError', 'StatusLine') .. icon
    if show_count then errors = errors .. result.errors end
  end
  if result.warnings > 0 then
    warnings = M.get_or_create_hl('DiagnosticWarn', 'StatusLine') .. icon
    if show_count then warnings = warnings .. result.warnings end
  end
  if result.info > 0 then
    info = M.get_or_create_hl('DiagnosticInfo', 'StatusLine') .. icon
    if show_count then info = info .. result.info end
  end
  if result.hints > 0 then
    hints = M.get_or_create_hl('DiagnosticHint', 'StatusLine') .. icon
    if show_count then hints = hints .. result.hints end
  end

  if vim.bo.modifiable and total > 0 then return (warnings .. errors .. info .. hints .. ' ') or '' end

  return ''
end

---@return string
function M.git_status_simple()
  local gitsigns = vim.b.minidiff_summary

  if not gitsigns then return '' end

  local diff_icon = '▪'
  local total_changes = 0

  total_changes = (gitsigns.add or 0) + (gitsigns.change or 0) + (gitsigns.delete or 0)
  local added = ''
  local changed = ''
  local removed = ''

  if gitsigns.add and gitsigns.add > 0 then
    added = M.get_or_create_hl('MiniDiffSignAdd', 'StatusLine') .. diff_icon .. gitsigns.add
  end

  if gitsigns.change and gitsigns.change > 0 then
    changed = M.get_or_create_hl('MiniDiffSignChange', 'StatusLine') .. diff_icon .. gitsigns.change
  end

  if gitsigns.delete and gitsigns.delete > 0 then
    removed = M.get_or_create_hl('MiniDiffSignDelete', 'StatusLine') .. diff_icon .. gitsigns.delete
  end

  return total_changes > 0 and added .. changed .. removed .. ' ' or ''
end

---Generate the complete statusline string
---@return string The formatted statusline
function M.StatusLine()
  local components = {
    M.fileinfo(),
    '%=',
    M.get_position(),
    M.lsp_diagnostics({ show_count = true }),
    M.git_status_simple(),
  }

  return table.concat(components)
end

return M
