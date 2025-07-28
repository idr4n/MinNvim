-- vim: foldmethod=marker foldlevel=0

vim.pack.add({
  "https://github.com/nvim-treesitter/nvim-treesitter",
  "https://github.com/echasnovski/mini.diff",
  "https://github.com/echasnovski/mini.surround",
  "https://github.com/windwp/nvim-autopairs",
  "https://github.com/ibhagwan/fzf-lua",
  "https://github.com/brenoprata10/nvim-highlight-colors",
  "https://github.com/idr4n/netrw-preview.nvim",
  { src = 'https://github.com/saghen/blink.cmp', version = 'v1.6.0' },
})

--: Treesitter {{{
require('nvim-treesitter.configs').setup({
  ensure_installed = { "lua", "vim", "vimdoc", "query", "go", "markdown", "markdown_inline" },
  highlight = { enable = true, additional_vim_regex_highlighting = false },
  -- highlight = { enable = true },
  indent = { enable = true },
})
--: }}}

--: mini.diff {{{
local minidiff = require('mini.diff')
minidiff.setup({
  view = {
    signs = { add = ' +', change = ' ~', delete = ' -' },
  },
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
--: }}}

--: mini.surround {{{
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
--: }}}

--: nvim-autopairs {{{
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
      -- Removes the trailing whitespace that can occur without this
      :replace_map_cr(function(_)
        return "<C-c>2xi<CR><C-c>O"
      end),
  })
end
--: }}}

--: fzf-lua {{{
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
vim.keymap.set("n", "<C-Space>", ":FzfLua files<cr>", { desc = "FzfLua Files" })
vim.keymap.set("n", "<leader>sk", ":FzfLua keymaps<cr>", { desc = "FzfLua Keymaps" })
--: }}}

--: blink.cmp {{{
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
  },

  completion = {
    accept = { auto_brackets = { enabled = true } },
    list = { selection = { preselect = false, auto_insert = true } },
    menu = {
      auto_show = false,
      draw = {
        gap =  2,
        -- no icons: remove { "kind_icon", "kind" } from column list, like this:
        -- columns = { { "label", "label_description", gap = 1 } },
        components = {
          kind_icon = {
            text = function(ctx)
              if require("blink.cmp.sources.lsp.hacks.tailwind").get_hex_color(ctx.item) then
                return "󱓻"
              end
              return ctx.kind_icon .. ctx.icon_gap
            end,
          },
        },
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
--: }}}

--: nvim-highlight-colors {{{
require("nvim-highlight-colors").setup({
  render = "virtual",
  virtual_symbol = "󱓻",
  -- Exclude filetypes or buftypes from highlighting e.g. 'exclude_buftypes = {'text'}'
  exclude_filetypes = {},
  exclude_buftypes = {},
})
vim.keymap.set("n", ",c", "<cmd>HighlightColors Toggle<cr>", { silent = true, desc = "Toggle colorizer" })
--: }}}

--: netrw-preview {{{
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
vim.keymap.set("n", ",,", "<cmd>NetrwRevealToggle<cr>", { desc = "Toggle Netrw - Reveal" })
vim.keymap.set("n", ",l", "<cmd>NetrwRevealLexToggle<cr>", { desc = "Toggle Netrw (Lex) - Reveal" })
vim.keymap.set("n", "ga", "<cmd>NetrwLastBuffer<cr>", { desc = "Go to alternate buffer (with netrw reveal)" })
--:}}}
