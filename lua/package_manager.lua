---@class PackageManager
local M = {}

M.plugins = {}
M.loaded_plugins = {}

---@class PluginSpec
---@field src string GitHub shortcut (user/plugin) or full URL
---@field name? string Plugin name (derived from src if not provided)
---@field enabled? boolean Default true, set false to disable
---@field version? string Git tag, branch, or commit hash
---@field build? string|function String command or function to run after install/update
---@field event? string|string[] Event name or table of events for lazy loading
---@field ft? string|string[] Filetype or table of filetypes for lazy loading
---@field keys? string|string[]|table[] Key mapping(s) for lazy loading (string, array, or LazyVim format)
---@field cmd? string|string[] Command name or table of commands for lazy loading
---@field config? function Setup function (runs only once after loading)
---@field dependencies? string|string[] Dependency plugin source(s)
---@field lazy? boolean Default true, set false to load immediately

---@param spec PluginSpec
function M.add(spec)
  spec = M.create_spec(spec)
  M.plugins[spec.name] = spec

  -- Only setup if enabled
  if not spec.enabled then return end

  -- If not lazy, load immediately
  if spec.lazy == false then
    M.load_plugin(spec)
    return
  end

  -- Setup lazy loading
  M.setup_lazy_loading(spec)
end

-- Normalize src URL (convert GitHub shortcut to full URL)
function M.normalize_src_url(src)
  if not src:match('^https?://') and not src:match('^git@') then
    -- GitHub shortcut format: "user/repo" -> "https://github.com/user/repo"
    src = 'https://github.com/' .. src
    if not src:match('%.git$') then src = src .. '.git' end
  end
  return src
end

-- Create/normalize a plugin spec with defaults
function M.create_spec(input_spec, defaults)
  defaults = defaults or {}

  local spec = vim.tbl_deep_extend('force', {
    enabled = true,
    lazy = true,
  }, defaults, input_spec)

  -- Normalize src URL
  spec.src = M.normalize_src_url(spec.src)

  -- Auto-generate name if not provided
  if not spec.name then spec.name = spec.src:match('([^/]+)$'):gsub('%.git$', '') end

  return spec
end

-- Resolve dependency by name or src
function M.resolve_dependency(dep_spec)
  -- dep_spec can be:
  -- "plugin-name" -> find by name
  -- "user/repo" -> find by GitHub shortcut or name
  -- "https://github.com/user/repo" -> find by full URL

  -- Create spec to get normalized name
  local dep_plugin = M.create_spec({ src = dep_spec })

  -- Check if plugin with that name already exists
  if M.plugins[dep_plugin.name] then return M.plugins[dep_plugin.name] end

  -- If not found, add the created spec to plugins
  M.plugins[dep_plugin.name] = dep_plugin
  return dep_plugin
end

-- Load dependencies for a plugin
function M.load_dependencies(dependencies)
  local deps = type(dependencies) == 'table' and dependencies or { dependencies }

  for _, dep_spec in ipairs(deps) do
    local dep_plugin = M.resolve_dependency(dep_spec)
    if dep_plugin then
      if not M.loaded_plugins[dep_plugin.name] then M.load_plugin(dep_plugin) end
    end
  end
end

function M.load_plugin(spec)
  -- Only load and configure once
  if M.loaded_plugins[spec.name] then
    return -- Already loaded
  end

  -- Load dependencies first
  if spec.dependencies then M.load_dependencies(spec.dependencies) end

  -- Check if plugin is already installed before adding
  local pack_list = vim.pack.get()
  local already_installed = false
  for _, info in ipairs(pack_list) do
    if info.spec.name == spec.name then
      already_installed = true
      break
    end
  end

  local pack_spec = {
    src = spec.src,
    name = spec.name,
    version = spec.version,
  }

  -- If plugin was just installed and has build command, install without loading, build, then load
  if not already_installed and spec.build then
    -- Add without loading to prevent plugin files from executing before build
    vim.pack.add({ pack_spec }, { load = false })
    print('Building ' .. spec.name .. '...')
    local build_success = M.run_build(spec)
    if build_success then
      -- Now load the plugin after successful build
      vim.cmd('packadd ' .. spec.name)
    else
      print('Build failed for ' .. spec.name .. ', plugin not loaded')
      return
    end
  else
    -- Normal add (plugin already built or no build needed)
    vim.pack.add({ pack_spec })
  end

  -- Mark as loaded first to prevent recursion
  M.loaded_plugins[spec.name] = true

  -- Run config only on first load
  if spec.config then spec.config() end
end

function M.setup_lazy_loading(spec)
  local group = vim.api.nvim_create_augroup('simple-pack-' .. spec.name, { clear = true })

  -- Event-based lazy loading
  if spec.event then M.lazyload_on_events(spec, group) end

  -- FileType-based lazy loading
  if spec.ft then M.lazyload_on_filetypes(spec, group) end

  -- Enhanced keymap-based lazy loading
  if spec.keys then M.lazyload_on_keys(spec) end

  -- Command-based lazy loading
  if spec.cmd then M.lazyload_on_commands(spec) end
end

-- Lazy load on keymaps
function M.lazyload_on_keys(spec)
  local keys = type(spec.keys) == 'table' and spec.keys or { spec.keys }

  for _, key in ipairs(keys) do
    if type(key) == 'string' then
      -- Simple string format: "keys = '<leader>ff'"
      vim.keymap.set('n', key, function()
        M.load_plugin(spec)
        -- Re-trigger the keymap after loading
        vim.api.nvim_feedkeys(key, 'n', false)
      end, { desc = '[Lazy] Load ' .. spec.name })
    elseif type(key) == 'table' then
      -- Advanced format: { modes, lhs, rhs, opts }
      local modes = key[1] or 'n'
      local lhs = key[2]
      local rhs = key[3]
      local opts = key[4] or {}

      -- Create one-shot lazy loading wrapper
      local lazy_rhs = function()
        M.load_plugin(spec)
        if type(rhs) == 'string' then
          -- Parse string commands
          if rhs:lower():match('^<cmd>.*<cr>$') then
            local cmd = rhs:match('^<[Cc][Mm][Dd]>(.+)<[Cc][Rr]>$')
            vim.cmd(cmd)
          elseif rhs:match('^:.*<cr>?$') then
            local cmd = rhs:match('^:(.+)<cr>?$')
            vim.cmd(cmd)
          else
            vim.api.nvim_feedkeys(rhs, 'n', false)
          end
        elseif type(rhs) == 'function' then
          rhs()
        end
      end

      vim.keymap.set(modes, lhs, lazy_rhs, opts)
    end
  end
end

-- Lazy load on events
function M.lazyload_on_events(spec, group)
  local events = type(spec.event) == 'table' and spec.event or { spec.event }
  vim.api.nvim_create_autocmd(events, {
    group = group,
    callback = function() M.load_plugin(spec) end,
    once = true,
  })
end

-- Lazy load on filetypes
function M.lazyload_on_filetypes(spec, group)
  local filetypes = type(spec.ft) == 'table' and spec.ft or { spec.ft }
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = filetypes,
    callback = function() M.load_plugin(spec) end,
    once = true,
  })
end

-- Lazy load on commands
function M.lazyload_on_commands(spec)
  local commands = type(spec.cmd) == 'table' and spec.cmd or { spec.cmd }
  for _, cmd in ipairs(commands) do
    vim.api.nvim_create_user_command(cmd, function(opts)
      vim.api.nvim_del_user_command(cmd)
      M.load_plugin(spec)
      local full_cmd = cmd
      if opts.args and #opts.args > 0 then full_cmd = full_cmd .. ' ' .. opts.args end
      vim.cmd(full_cmd)
    end, {
      nargs = '*',
      desc = '[Lazy] ' .. spec.name,
      complete = function()
        if not M.loaded_plugins[spec.name] then M.load_plugin(spec) end
      end,
    })
  end
end

-- Execute build command
function M.run_build(spec)
  if not spec.build then return true end

  print('Building ' .. spec.name .. '...')

  -- Get plugin path from vim.pack
  local pack_list = vim.pack.get()
  local plugin_info = nil
  for _, info in ipairs(pack_list) do
    if info.spec.name == spec.name then
      plugin_info = info
      break
    end
  end

  if not plugin_info then
    print('Could not find plugin path for ' .. spec.name)
    return false
  end

  local plugin_path = plugin_info.path

  if type(spec.build) == 'function' then
    -- Execute Lua function
    local success, err = pcall(spec.build, plugin_path)
    if not success then
      print('Build failed for ' .. spec.name .. ': ' .. err)
      return false
    end
  elseif type(spec.build) == 'string' then
    -- Execute shell command in plugin directory
    local cmd = string.format("cd '%s' && %s", plugin_path, spec.build)
    local result = vim.fn.system(cmd)
    local exit_code = vim.v.shell_error

    if exit_code ~= 0 then
      print('Build failed for ' .. spec.name .. ':')
      print(result)
      return false
    end
  end

  print('Build completed for ' .. spec.name)
  return true
end

-- Get enabled plugin names
function M.get_enabled_plugin_names()
  local enabled = {}
  for plugin_name, spec in pairs(M.plugins) do
    if spec.enabled then table.insert(enabled, plugin_name) end
  end
  return enabled
end

-- Install missing plugins (only enabled ones)
function M.install()
  print('Installing plugins...')

  -- Check which plugins are already installed
  local pack_list = vim.pack.get()
  local installed_map = {}
  for _, info in ipairs(pack_list) do
    installed_map[info.spec.name] = true
  end

  local to_install = {}
  for _, spec in pairs(M.plugins) do
    if spec.enabled and not installed_map[spec.name] then
      table.insert(to_install, {
        src = spec.src,
        name = spec.name,
        version = spec.version,
      })
    end
  end

  if #to_install > 0 then
    vim.pack.add(to_install)

    -- Run build commands for newly installed plugins
    for _, spec in pairs(M.plugins) do
      if spec.enabled and not installed_map[spec.name] and spec.build then
        print('Running build for installed plugin: ' .. spec.name)
        M.run_build(spec)
      end
    end
  else
    print('All enabled plugins are already installed')
  end

  print('Installation completed!')
end

-- Helper function to append lines to a buffer
local function append_to_buffer(buf, lines)
  vim.schedule(function()
    local line_count = vim.api.nvim_buf_line_count(buf)
    local lines_to_add = type(lines) == 'string' and { lines } or lines
    vim.api.nvim_buf_set_lines(buf, line_count, line_count, false, lines_to_add)
  end)
end

-- Async using vim.loop
local function get_remote_latest_hash_async(repo_url, callback)
  local uv = vim.loop
  local stdout = uv.new_pipe()
  local stderr = uv.new_pipe()
  local stdout_data = ''
  local stderr_data = ''

  local handle = uv.spawn('git', {
    args = { 'ls-remote', repo_url, 'HEAD' },
    stdio = { nil, stdout, stderr },
  }, function(code, _)
    if stdout then stdout:close() end
    if stderr then stderr:close() end

    if code == 0 then
      local hash = stdout_data:match('(%w+)')
      callback(hash, nil)
    else
      callback(nil, 'Failed to fetch remote info: ' .. stderr_data)
    end
  end)

  if not handle then
    callback(nil, 'Failed to spawn git process')
    return
  end

  if stdout then
    uv.read_start(stdout, function(_, data)
      if data then stdout_data = stdout_data .. data end
    end)
  end

  if stderr then
    uv.read_start(stderr, function(_, data)
      if data then stderr_data = stderr_data .. data end
    end)
  end
end

-- Get current plugin hash
local function get_local_hash(plugin_path)
  if vim.fn.isdirectory(plugin_path) == 0 then return nil, 'Plugin directory does not exist' end

  local cmd = string.format('git -C "%s" rev-parse HEAD', plugin_path)
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error

  if exit_code ~= 0 then return nil, 'Not a git repository or git error' end

  return result:gsub('\n', '')
end

-- Helper function to create plugin result and update progress
local function create_result_and_update_progress(
  spec,
  plugin_info,
  local_hash,
  remote_hash,
  error,
  completed,
  total,
  debug_buf,
  suffix
)
  local result = {
    spec = spec,
    plugin_info = plugin_info,
    local_hash = local_hash,
    remote_hash = remote_hash,
    needs_update = local_hash ~= remote_hash and remote_hash ~= nil,
    error = error,
  }

  completed = completed + 1
  local status_text = suffix and (spec.name .. ' ' .. suffix) or (spec.name .. ' checked')
  append_to_buffer(debug_buf, string.format('  Progress: %d/%d %s', completed, total, status_text))

  return result, completed
end

-- Collect update info for all plugins in parallel
local function collect_update_info_async(plugins, pack_list, debug_buf, callback)
  local results = {}
  local pending = 0
  local completed = 0
  local total = #plugins -- Total is always the number of plugins we're checking

  -- First, prepare all plugins that can be checked
  for _, spec in ipairs(plugins) do
    local plugin_info = nil
    for _, info in ipairs(pack_list) do
      if info.spec.name == spec.name then
        plugin_info = info
        break
      end
    end

    if plugin_info then
      pending = pending + 1

      -- Get local hash (fast, synchronous)
      local local_hash = get_local_hash(plugin_info.path)

      if not local_hash then
        results[spec.name], completed = create_result_and_update_progress(
          spec,
          plugin_info,
          nil,
          nil,
          'Failed to get local hash',
          completed,
          total,
          debug_buf
        )
        pending = pending - 1
        if pending == 0 then callback(results) end
      else
        -- Start async remote hash collection
        get_remote_latest_hash_async(spec.src, function(remote_hash, error)
          results[spec.name], completed = create_result_and_update_progress(
            spec,
            plugin_info,
            local_hash,
            remote_hash,
            error,
            completed,
            total,
            debug_buf
          )
          pending = pending - 1
          if pending == 0 then callback(results) end
        end)
      end
    else
      -- Plugin not installed - still count as completed
      results[spec.name], completed = create_result_and_update_progress(
        spec,
        nil,
        nil,
        nil,
        'Plugin not installed',
        completed,
        total,
        debug_buf,
        'checked (not installed)'
      )
    end
  end

  if total == 0 then callback(results) end
end

-- Helper function to handle post-update actions (build or completion message)
local function handle_plugin_completion(spec, debug_buf, next_action)
  if spec.build then
    append_to_buffer(debug_buf, '  Building ' .. spec.name .. '...')
    local build_success = M.run_build(spec)
    if build_success then
      append_to_buffer(debug_buf, '  Build completed for ' .. spec.name)
    else
      append_to_buffer(debug_buf, '  Build failed for ' .. spec.name)
    end
  else
    append_to_buffer(debug_buf, '  Updated: ' .. spec.name)
  end

  -- Move to next action
  if next_action then vim.defer_fn(next_action, 50) end
end

-- Process plugins that need updates sequentially
local function process_plugin_updates_sequential(plugins_to_update, debug_buf)
  local function process_plugin(index)
    if index > #plugins_to_update then
      append_to_buffer(debug_buf, { '', 'Update completed!' })
      print('Update completed!')
      return
    end

    local info = plugins_to_update[index]
    local spec = info.spec
    append_to_buffer(debug_buf, '  Updating ' .. spec.name .. '...')

    vim.schedule(function() vim.pack.update({ spec.name }, { force = true }) end)

    -- Monitor until update completes (hash matches expected)
    local function wait_for_update_completion()
      local current_hash = get_local_hash(info.plugin_info.path)
      if current_hash == info.remote_hash then
        -- Update completed successfully - now build if needed
        handle_plugin_completion(spec, debug_buf, function() process_plugin(index + 1) end)
      else
        -- Still updating, check again in 200ms
        vim.defer_fn(wait_for_update_completion, 200)
      end
    end

    -- Start monitoring after brief delay
    vim.defer_fn(wait_for_update_completion, 500)
  end

  if #plugins_to_update > 0 then
    process_plugin(1)
  else
    append_to_buffer(debug_buf, { '', 'No plugins need updating.' })
    print('No plugins need updating.')
  end
end

-- Main update process using two-phase approach
local function process_plugins_updates(plugins, debug_buf)
  -- Get plugin info from pack system once
  local pack_list = vim.pack.get()

  -- Phase 1: Collect all update info in parallel
  append_to_buffer(debug_buf, 'Collecting update info for ' .. #plugins .. ' plugins...')

  collect_update_info_async(plugins, pack_list, debug_buf, function(results)
    -- Phase 2: Show summary and process updates sequentially
    local plugins_to_update = {}
    local up_to_date = {}
    local errors = {}

    for name, info in pairs(results) do
      if info.error then
        table.insert(errors, name .. ': ' .. info.error)
      elseif info.needs_update then
        table.insert(plugins_to_update, info)
      else
        table.insert(up_to_date, name)
      end
    end

    -- Show summary
    append_to_buffer(debug_buf, { '', 'Summary:' })
    if #plugins_to_update > 0 then
      local update_names = {}
      for _, info in ipairs(plugins_to_update) do
        table.insert(update_names, info.spec.name)
      end
      append_to_buffer(
        debug_buf,
        '  ' .. #plugins_to_update .. ' plugins need updating: ' .. table.concat(update_names, ', ')
      )
    end
    if #up_to_date > 0 then
      append_to_buffer(debug_buf, '  ' .. #up_to_date .. ' plugins up to date:')
      for _, name in ipairs(up_to_date) do
        append_to_buffer(debug_buf, '    • ' .. name)
      end
    end
    if #errors > 0 then
      append_to_buffer(debug_buf, '  Errors:')
      for _, error in ipairs(errors) do
        append_to_buffer(debug_buf, '    ' .. error)
      end
    end

    -- Start sequential updates
    if #plugins_to_update > 0 then
      append_to_buffer(debug_buf, { '', 'Starting updates...' })
      process_plugin_updates_sequential(plugins_to_update, debug_buf)
    else
      append_to_buffer(debug_buf, { '', 'All plugins are up to date!' })
      print('All plugins are up to date!')
    end
  end)
end

-- Update enabled plugins using commit hash comparison
function M.update(opts)
  opts = opts or {}

  -- Collect enabled plugins
  local enabled_plugins = {}
  for _, spec in pairs(M.plugins) do
    if spec.enabled then table.insert(enabled_plugins, spec) end
  end

  if #enabled_plugins == 0 then
    print('No enabled plugins to update')
    return
  end

  print('Starting plugin update process...')

  -- Create debug scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, 'Pack Update Debug')
  vim.api.nvim_open_win(buf, true, {
    split = 'right',
    width = 60,
  })
  append_to_buffer(buf, {
    'Pack Update Debug Log',
    '=====================',
    'Checking ' .. #enabled_plugins .. ' plugins for updates...',
    '',
  })

  -- Start sequential processing
  vim.schedule(function() process_plugins_updates(enabled_plugins, buf) end)
end

-- Remove disabled plugins using vim.pack.del()
function M.clean()
  local pack_list = vim.pack.get()
  local to_delete = {}

  for _, info in ipairs(pack_list) do
    local name = info.spec.name
    local spec = M.plugins[name]
    if not spec or not spec.enabled then
      table.insert(to_delete, name)
      print('Marking ' .. name .. ' for removal...')
    end
  end

  if #to_delete > 0 then
    vim.pack.del(to_delete)
    print('Cleanup completed!')
  else
    print('No plugins to clean')
  end
end

-- Sync: Install enabled, update enabled, remove disabled
function M.sync(opts)
  opts = opts or {}

  print('Starting sync...')

  -- Install missing enabled plugins
  M.install()

  -- Update existing enabled plugins
  M.update({ force = opts.force })

  -- Remove disabled plugins
  M.clean()

  print('Sync completed!')
end

-- Get plugin info using vim.pack.get()
function M.status()
  local pack_list = vim.pack.get()
  local installed_map = {}

  for _, info in ipairs(pack_list) do
    installed_map[info.spec.name] = info
  end

  print('Plugin Status:')
  print('==============')

  for name, spec in pairs(M.plugins) do
    local status_icon = spec.enabled and '✓' or '✗'
    local loaded_icon = M.loaded_plugins[name] and ' [L]' or ''
    local info = installed_map[name]

    if info then
      local version_info = info.spec.version or 'default branch'
      local active_status = info.active and '(loaded)' or '(not loaded)'
      print(string.format('%s %s%s: %s %s', status_icon, name, loaded_icon, version_info, active_status))
    else
      local install_status = spec.enabled and 'not installed' or 'disabled'
      print(string.format('%s %s%s: %s', status_icon, name, loaded_icon, install_status))
    end
  end

  -- Show orphaned plugins (installed but not in config)
  local orphans = {}
  for _, info in ipairs(pack_list) do
    if not M.plugins[info.spec.name] then table.insert(orphans, info.spec.name) end
  end

  if #orphans > 0 then
    print('\nOrphaned plugins (not in config):')
    for _, plugin in ipairs(orphans) do
      print('⚠ ' .. plugin)
    end
  end
end

-- Create user commands for package management
vim.api.nvim_create_user_command('PackStatus', function() M.status() end, { desc = 'Show plugin status' })

vim.api.nvim_create_user_command('PackInstall', function() M.install() end, { desc = 'Install missing plugins' })

vim.api.nvim_create_user_command('PackUpdate', function(opts)
  local force = opts.bang
  M.update({ force = force })
end, { desc = 'Update plugins (use ! to force)', bang = true })

vim.api.nvim_create_user_command('PackClean', function() M.clean() end, { desc = 'Remove disabled plugins' })

vim.api.nvim_create_user_command('PackSync', function(opts)
  local force = opts.bang
  M.sync({ force = force })
end, { desc = 'Sync plugins: install, update, clean (use ! to force)', bang = true })

vim.api.nvim_create_user_command('PackBuild', function(opts)
  if opts.args and opts.args ~= '' then
    -- Build specific plugin
    local plugin_name = opts.args
    local spec = M.plugins[plugin_name]
    if spec and spec.build then
      M.run_build(spec)
    else
      print('Plugin "' .. plugin_name .. '" not found or has no build command.')
    end
  end
end, {
  nargs = '?',
  desc = 'Build specific plugin or all plugins with pendign builds',
  complete = function()
    -- Tab completion with plugin names that have build commands
    local completions = {}
    for name, spec in pairs(M.plugins) do
      if spec.build then table.insert(completions, name) end
    end
    return completions
  end,
})

return M
