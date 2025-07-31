---@class PackageManager
local M = {}

M.plugins = {}
M.loaded_plugins = {}

-- Plugin specification
function M.add(spec)
  -- spec = {
  --   src = "user/plugin" or "https://github.com/user/plugin", -- GitHub shortcut or full URL
  --   name = "plugin", -- optional, derived from src if not provided
  --   enabled = true, -- default true, set false to disable
  --   version = "v1.2.3", -- git tag, branch, or commit hash
  --   build = "make", -- string command or function
  --   event = "InsertEnter", -- or table of events
  --   ft = "lua", -- or table of filetypes
  --   keys = "<leader>ff", -- string, array of strings, or LazyVim format
  --   cmd = "CommandName", -- or table of commands
  --   config = function() end, -- setup function (runs only once)
  --   dependencies = { "user/dep-plugin" }, -- string or table of dependency plugin sources
  --   lazy = true -- default true
  -- }

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
    if not src:match('%.git$') then
      src = src .. '.git'
    end
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
  if not spec.name then
    spec.name = spec.src:match('([^/]+)$'):gsub('%.git$', '')
  end

  return spec
end

-- Resolve dependency by name or src
function M.resolve_dependency(dep_spec)
  -- dep_spec can be:
  -- "plugin-name" -> find by name
  -- "user/repo" -> find by GitHub shortcut or name  
  -- "https://github.com/user/repo" -> find by full URL

  -- Create spec to get normalized name
  local dep_plugin = M.create_spec({ src = dep_spec }, { lazy = false })

  -- Check if plugin with that name already exists
  if M.plugins[dep_plugin.name] then
    return M.plugins[dep_plugin.name]
  end

  -- If not found, add the created spec to plugins
  print('Creating missing dependency: ' .. dep_spec)
  M.plugins[dep_plugin.name] = dep_plugin
  return dep_plugin
end

-- Load dependencies for a plugin
function M.load_dependencies(dependencies)
  local deps = type(dependencies) == 'table' and dependencies or { dependencies }

  for _, dep_spec in ipairs(deps) do
    local dep_plugin = M.resolve_dependency(dep_spec)
    if dep_plugin then
      if not M.loaded_plugins[dep_plugin.name] then
        M.load_plugin(dep_plugin)
      end
    end
  end
end

function M.load_plugin(spec)
  -- Only load and configure once
  if M.loaded_plugins[spec.name] then
    return -- Already loaded
  end

  -- Load dependencies first
  if spec.dependencies then
    M.load_dependencies(spec.dependencies)
  end

  local pack_spec = {
    src = spec.src,
    name = spec.name,
    version = spec.version,
  }
  vim.pack.add({ pack_spec })

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
  if spec.cmd then
    local commands = type(spec.cmd) == 'table' and spec.cmd or { spec.cmd }
    for _, cmd in ipairs(commands) do
      vim.api.nvim_create_user_command(cmd, function(opts)
        vim.api.nvim_del_user_command(cmd)
        M.load_plugin(spec)
        local full_cmd = cmd
        if opts.args and #opts.args > 0 then
          full_cmd = full_cmd .. ' ' .. opts.args
        end
        vim.cmd(full_cmd)
      end, {
        nargs = '*',
        desc = '[Lazy] ' .. spec.name,
        complete = function(arg_lead, cmd_line, cursor_pos)
          if not M.loaded_plugins[spec.name] then
            M.load_plugin(spec)
          end
        end,
      })
    end
  end
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

-- Execute build command
function M.run_build(spec)
  if not spec.build then return true end

  print('Building ' .. spec.name .. '...')

  -- Get plugin path from vim.pack
  local pack_list = vim.pack.list()
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

  local enabled_specs = {}
  for _, spec in pairs(M.plugins) do
    if spec.enabled then
      table.insert(enabled_specs, {
        src = spec.src,
        name = spec.name,
        version = spec.version,
      })
    end
  end

  if #enabled_specs > 0 then
    vim.pack.add({ enabled_specs })

    -- Run build commands after installation
    for _, spec in pairs(M.plugins) do
      if spec.enabled and spec.build then M.run_build(spec) end
    end
  end

  print('Installation completed!')
end

-- Update enabled plugins using vim.pack.update()
function M.update(opts)
  opts = opts or {}
  local force = opts.force or false

  local enabled_names = M.get_enabled_plugin_names()

  if #enabled_names == 0 then
    print('No enabled plugins to update')
    return
  end

  print('Updating plugins...')

  -- Use vim.pack.update with the new API
  vim.pack.update(enabled_names, { force = force })

  -- Run build commands after update
  vim.schedule(function()
    for _, spec in pairs(M.plugins) do
      if spec.enabled and spec.build then M.run_build(spec) end
    end
    print('Update completed!')
  end)
end

-- Remove disabled plugins using vim.pack.del()
function M.clean()
  local pack_list = vim.pack.list()
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

-- Get plugin info using vim.pack.list()
function M.status()
  local pack_list = vim.pack.list()
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

return M
