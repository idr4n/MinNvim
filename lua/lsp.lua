-- vim: foldmethod=marker foldlevel=0

--: Enabled LSP's {{{
vim.lsp.enable({
  "lua_ls",
  "pyright",
  "ruff",
  "tailwindcss",
  "vtsls",
})
--: }}}

--: Diagnostics {{{
-- Disabled by default
vim.diagnostic.enable(false)

vim.diagnostic.config({
  update_in_insert = false,
  virtual_text = false,
  signs = true,
})

local function toggle_diagnostics()
  if vim.diagnostic.is_enabled() then
    vim.diagnostic.enable(false)
  else
    vim.diagnostic.enable(true)
  end
end
--: }}}

--: On attach autocmd {{{
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("idr4n/LspConfig", { clear = true }),
  desc = "Configure LSP keymaps",
  --stylua: ignore
  callback = function(args)
    vim.keymap.set({ "n", "v" }, "<leader>ff", vim.lsp.buf.format, { buffer = args.buf, desc = "Format buffer" })
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = args.buf, desc = "Go to definition" })
    vim.keymap.set("n", '[e', function() vim.diagnostic.jump { count = -1, severity = vim.diagnostic.severity.ERROR } end, { buffer = args.buf, desc = "Previous Error" })
    vim.keymap.set("n", ']e', function() vim.diagnostic.jump { count = -1, severity = vim.diagnostic.severity.ERROR } end, { buffer = args.buf, desc = "Next Error" })
  end,
})
--: }}}

--: Other LSP mappings {{{
vim.keymap.set("n", "<leader>td", toggle_diagnostics, { desc = "Toggle diagnostics" })
vim.keymap.set('n', '<leader>zd', vim.diagnostic.setloclist, { desc = "Buffer Diagnostics to loclist" })
vim.keymap.set('n', '<leader>zD', vim.diagnostic.setqflist, { desc = "Diagnostics to quickfix" })
--: }}}

--: LSP Custom Commands {{{
-- Custom LspInfo command
vim.api.nvim_create_user_command('LspInfo', function() vim.cmd('checkhealth vim.lsp') end, {})

-- Custom LspRestart command
vim.api.nvim_create_user_command('LspRestart', function(opts)
  local client_name = opts.args ~= "" and opts.args or nil

  if client_name then
    -- Restart specific client
    local clients = vim.lsp.get_clients({ name = client_name })
    for _, client in ipairs(clients) do
      vim.lsp.stop_client(client.id)
    end
    vim.defer_fn(function()
      vim.lsp.enable(client_name)
    end, 500)
  else
    -- Restart all clients for current buffer
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    local client_names = {}

    for _, client in ipairs(clients) do
      table.insert(client_names, client.name)
      vim.lsp.stop_client(client.id)
    end

    vim.defer_fn(function()
      for _, name in ipairs(client_names) do
        vim.lsp.enable(name)
      end
    end, 500)
  end
end, { nargs = '?', complete = function()
  local clients = vim.lsp.get_clients()
  return vim.tbl_map(function(client) return client.name end, clients)
end })

-- Custom LspStop command
vim.api.nvim_create_user_command('LspStop', function(opts)
  local client_name = opts.args ~= "" and opts.args or nil

  if client_name then
    local clients = vim.lsp.get_clients({ name = client_name })
    for _, client in ipairs(clients) do
      vim.lsp.stop_client(client.id)
    end
  else
    -- Stop all clients for current buffer
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    for _, client in ipairs(clients) do
      vim.lsp.stop_client(client.id)
    end
  end
end, { nargs = '?', complete = function()
  local clients = vim.lsp.get_clients()
  return vim.tbl_map(function(client) return client.name end, clients)
end })
--: }}}
