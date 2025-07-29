-- vim: foldmethod=marker foldlevel=0

--: Lazy load treesitter {{{
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufWritePre" }, {
  group = vim.api.nvim_create_augroup("idr4n/lazy/treesitter", { clear = true }),
  callback = function ()
    vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter" })
    require('nvim-treesitter.configs').setup({
      ensure_installed = { "lua", "vim", "vimdoc", "query", "go", "markdown", "markdown_inline" },
      highlight = { enable = true, additional_vim_regex_highlighting = false },
      indent = { enable = true },
    })
  end
})
--: }}}

--: Lazy load mini.diff {{{
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufWritePre" }, {
  group = vim.api.nvim_create_augroup("idr4n/lazy/minidiff", { clear = true }),
  callback = function ()
    vim.pack.add({ "https://github.com/echasnovski/mini.diff" })
    local minidiff = require('mini.diff')
    minidiff.setup({
      view = { signs = { add = ' +', change = ' ~', delete = ' -' }, },
      mappings = {
        apply = '<leader>hs',
        reset = '<leader>hS',
        textobject = '<leader>hs',
        goto_first = '[C',
        goto_prev = '[c',
        goto_next = ']c',
        goto_last = ']C',
      },
    })
    vim.keymap.set("n", "<leader>gt", minidiff.toggle, { desc = "Toggle Mini Diff" })
    vim.keymap.set("n", "<leader>go", minidiff.toggle_overlay, { desc = "Toggle Mini Diff" })
  end
})
--: }}}

--: Lazy load mini.surround {{{
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufWritePre" }, {
  group = vim.api.nvim_create_augroup("idr4n/lazy/minisurround", { clear = true }),
  callback = function ()
    vim.pack.add({ "https://github.com/echasnovski/mini.surround" })
    require("mini.surround").setup({
      mappings = {
        add = "S",
        delete = "ds",
        replace = "cs",
        find = "fsr",
        find_left = "fsl",
        highlight = "",
        update_n_lines = "",
      },
    })
  end
})
--: }}}

--: Lazy load nvim-autopairs {{{
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("idr4n/lazy/nvimautopairs", { clear = true }),
  callback = function ()
    vim.pack.add({ "https://github.com/windwp/nvim-autopairs" })
    local npairs = require("nvim-autopairs")
    local Rule = require("nvim-autopairs.rule")
    local cond = require("nvim-autopairs.conds")
    npairs.setup()
    local brackets = { { "(", ")" }, { "[", "]" }, { "{", "}" } }
    npairs.add_rules({
      Rule(" ", " ")
        :with_pair(function(opts)
          local pair = opts.line:sub(opts.col - 1, opts.col)
          return vim.tbl_contains({
            brackets[1][1] .. brackets[1][2],
            brackets[2][1] .. brackets[2][2],
            brackets[3][1] .. brackets[3][2],
          }, pair)
        end)
        :with_move(cond.none())
        :with_cr(cond.none())
        :with_del(function(opts)
          local col = vim.api.nvim_win_get_cursor(0)[2]
          local context = opts.line:sub(col - 1, col + 2)
          return vim.tbl_contains({
            brackets[1][1] .. "  " .. brackets[1][2],
            brackets[2][1] .. "  " .. brackets[2][2],
            brackets[3][1] .. "  " .. brackets[3][2],
          }, context)
        end),
    })
    for _, bracket in pairs(brackets) do
      npairs.add_rules({
        Rule(bracket[1] .. " ", " " .. bracket[2])
          :with_pair(cond.none())
          :with_move(function(opts)
            return opts.char == bracket[2]
          end)
          :with_del(cond.none())
          :use_key(bracket[2])
          :replace_map_cr(function(_)
            return "<C-c>2xi<CR><C-c>O"
          end),
      })
    end
  end
})
--: }}}

--: Lazy load blink-cmp {{{
vim.api.nvim_create_autocmd("InsertEnter", {
  group = vim.api.nvim_create_augroup("idr4n/lazy/blink.cmp", { clear = true }),
  callback = function()
    vim.pack.add({ { src = 'https://github.com/saghen/blink.cmp', version = 'v1.6.0' } })
    require('blink.cmp').setup {
      cmdline = {
        enabled = false,
        completion = {
          menu = { auto_show = false },
          list = { selection = { preselect = false, auto_insert = true } },
        },
      },

      sources = {
        default = { "lsp", "path", "buffer", "snippets", },
        providers = {
          lsp = { opts = { tailwind_color_icon = '󱓻' }, }
        }
      },

      completion = {
        accept = { auto_brackets = { enabled = true } },
        list = { selection = { preselect = false, auto_insert = true } },
        menu = {
          auto_show = true,
          draw = {
            gap =  2,
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
      },

      keymap = {
        preset = "enter",
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<Tab>"] = { "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<C-e>"] = { "hide", "fallback" },
        ["<C-y>"] = { "select_and_accept" },
        ["<C-j>"] = { "snippet_forward", "fallback" },
        ["<C-k>"] = { "snippet_backward", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
      },
    }
  end,
  once = true,
})
--: }}}

--: Lazy load fzf-lua {{{
vim.g.fzf_lua_loaded = false
local fzf_lua_config = function()
  require("fzf-lua").setup({
    winopts = {
      -- Open in a split at the bottom instead of floating window
      -- split = "belowright 13new",
      row = 0.5,
      height = 0.7,
      width = 89,
      backdrop = 100,
      preview = {
        hidden = true,
        layout = "vertical",
        -- layout = "horizontal",
        vertical = "down:50%",
        horizontal = "right:50%",
      },
    },
    keymap = {
      builtin = {
        ["<C-l>"] = "toggle-preview",
        ["<C-d>"] = "preview-page-down",
        ["<C-u>"] = "preview-page-up",
      },
      fzf = {
        ["ctrl-l"] = "toggle-preview",
        ["ctrl-q"] = "select-all+accept",
      },
    },
  })
end
vim.keymap.set("n", "<C-Space>", function()
  if not vim.g.fzf_lua_loaded then
    vim.pack.add({ "https://github.com/ibhagwan/fzf-lua" })
    fzf_lua_config()
    vim.g.fzf_lua_loaded = true
  end
  vim.cmd("FzfLua files")
end, { desc = "FzfLua Files" })
vim.keymap.set("n", "<leader>sk", function()
  if not vim.g.fzf_lua_loaded then
    vim.pack.add({ "https://github.com/ibhagwan/fzf-lua" })
    fzf_lua_config()
    vim.g.fzf_lua_loaded = true
  end
  vim.cmd("FzfLua keymaps")
end, { desc = "FzfLua Keymaps" })
--: }}}

--: Lazy load nvim-highlight-colors {{{
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("idr4n/lazy/nvim-highlight-colors", { clear = true }),
  pattern = { "cfg", "css", "html", "conf", "lua", "scss", "toml", "markdown", "typescript", "typescriptreact", },
  callback = function ()
    vim.pack.add({ "https://github.com/brenoprata10/nvim-highlight-colors" })
    require("nvim-highlight-colors").setup({
      render = "virtual",
      virtual_symbol = "󱓻",
      exclude_filetypes = {},
      exclude_buftypes = {},
    })
    vim.keymap.set("n", ",c", "<cmd>HighlightColors Toggle<cr>", { silent = true, desc = "Toggle colorizer" })
  end
})
--: }}}

--: Lazy load netrw-preview {{{
vim.g.netrwpreview_loaded = false
local netrwpreview_config = function()
  require('netrw-preview').setup({
    preview_width = 65,
    mappings = {
      close_netrw = { "q", "gq", "<c-q>" },
      toggle_preview = { "p", "<Tab>" },
      directory_mappings = {
        { key = "~", path = "~", desc = "Home directory" },
        { key = "gd", path = "~/Downloads", desc = "Downloads directory" },
        { key = "gw", path = function() return vim.fn.getcwd() end, desc = "Current working directory", },
      },
    },
  })
end
vim.keymap.set("n", ",,", function ()
  if not vim.g.netrwpreview_loaded then
    vim.pack.add({ "https://github.com/idr4n/netrw-preview.nvim" })
    netrwpreview_config()
    vim.g.netrwpreview_loaded = true
  end
  vim.cmd("NetrwRevealToggle")
end, { desc = "Toggle Netrw - Reveal" })
vim.keymap.set("n", ",l", function ()
  if not vim.g.netrwpreview_loaded then
    vim.pack.add({ "https://github.com/idr4n/netrw-preview.nvim" })
    netrwpreview_config()
    vim.g.netrwpreview_loaded = true
  end
  vim.cmd("NetrwRevealLexToggle")
end, { desc = "Toggle Netrw (Lex) - Reveal" })
--: }}}
