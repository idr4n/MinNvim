-- vim: foldmethod=marker foldlevel=0

local manager = require('package_manager')
local p = manager.add

--: Lazy load treesitter {{{
p({
  src = 'nvim-treesitter/nvim-treesitter',
  event = { 'BufReadPost', 'BufNewFile', 'BufWritePre' },
  config = function()
    vim.pack.add({ 'nvim-treesitter/nvim-treesitter' })
    require('nvim-treesitter.configs').setup({
      ensure_installed = { 'lua', 'vim', 'vimdoc', 'query', 'go', 'markdown', 'markdown_inline' },
      highlight = { enable = true, additional_vim_regex_highlighting = false },
      indent = { enable = true },
    })
  end,
})
--: }}}

--: Lazy load mini.diff {{{
p({
  src = 'echasnovski/mini.diff',
  event = { 'BufReadPost', 'BufNewFile', 'BufWritePre' },
  config = function()
    local minidiff = require('mini.diff')
    minidiff.setup({
      view = { signs = { add = ' +', change = ' ~', delete = ' -' } },
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
    vim.keymap.set('n', '<leader>gt', minidiff.toggle, { desc = 'Toggle Mini Diff' })
    vim.keymap.set('n', '<leader>go', minidiff.toggle_overlay, { desc = 'Toggle Mini Diff' })
  end,
})
--: }}}

--: Lazy load mini.surround {{{
p({
  src = 'echasnovski/mini.surround',
  event = { 'BufReadPost', 'BufNewFile', 'BufWritePre' },
  config = function()
    require('mini.surround').setup({
      mappings = {
        add = 'S',
        delete = 'ds',
        replace = 'cs',
        find = 'fsr',
        find_left = 'fsl',
        highlight = '',
        update_n_lines = '',
      },
    })
  end,
})
--: }}}

--: Lazy load nvim-autopairs {{{
p({
  src = 'windwp/nvim-autopairs',
  event = { 'BufReadPost', 'BufNewFile' },
  config = function()
    local npairs = require('nvim-autopairs')
    local Rule = require('nvim-autopairs.rule')
    local cond = require('nvim-autopairs.conds')
    npairs.setup()
    local brackets = { { '(', ')' }, { '[', ']' }, { '{', '}' } }
    npairs.add_rules({
      Rule(' ', ' ')
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
            brackets[1][1] .. '  ' .. brackets[1][2],
            brackets[2][1] .. '  ' .. brackets[2][2],
            brackets[3][1] .. '  ' .. brackets[3][2],
          }, context)
        end),
    })
    for _, bracket in pairs(brackets) do
      npairs.add_rules({
        Rule(bracket[1] .. ' ', ' ' .. bracket[2])
          :with_pair(cond.none())
          :with_move(function(opts) return opts.char == bracket[2] end)
          :with_del(cond.none())
          :use_key(bracket[2])
          :replace_map_cr(function(_) return '<C-c>2xi<CR><C-c>O' end),
      })
    end
  end,
})
--: }}}

--: Lazy load fzf-lua {{{
p({
  src = 'ibhagwan/fzf-lua',
  cmd = 'FzfLua',
  config = function()
    require('fzf-lua').setup({
      winopts = {
        -- Open in a split at the bottom instead of floating window
        -- split = "belowright 13new",
        row = 0.5,
        height = 0.7,
        width = 89,
        backdrop = 100,
        preview = {
          hidden = true,
          layout = 'vertical',
          -- layout = "horizontal",
          vertical = 'down:50%',
          horizontal = 'right:50%',
        },
      },
      keymap = {
        builtin = {
          ['<C-l>'] = 'toggle-preview',
          ['<C-d>'] = 'preview-page-down',
          ['<C-u>'] = 'preview-page-up',
        },
        fzf = {
          ['ctrl-l'] = 'toggle-preview',
          ['ctrl-q'] = 'select-all+accept',
        },
      },
    })
  end,
  keys = {
    { 'n', '<C-Space>', '<cmd>FzfLua files<cr>', { desc = 'FzfLua Files' } },
    { 'n', '<leader>sk', '<cmd>FzfLua keymaps<cr>', { desc = 'FzfLua Keymaps' } },
  },
})
--: }}}

--: Lazy load nvim-highlight-colors {{{
p({
  src = 'brenoprata10/nvim-highlight-colors',
  ft = { 'cfg', 'css', 'html', 'conf', 'lua', 'scss', 'toml', 'markdown', 'typescript', 'typescriptreact' },
  config = function()
    require('nvim-highlight-colors').setup({
      render = 'virtual',
      virtual_symbol = '󱓻',
      exclude_filetypes = {},
      exclude_buftypes = {},
    })
    vim.keymap.set('n', ',c', '<cmd>HighlightColors Toggle<cr>', { silent = true, desc = 'Toggle colorizer' })
  end,
})
--: }}}

--: Lazy load netrw-preview {{{
p({
  src = 'idr4n/netrw-preview.nvim',
  config = function()
    require('netrw-preview').setup({
      preview_width = 65,
      mappings = {
        close_netrw = { 'q', 'gq', '<c-q>' },
        toggle_preview = { 'p', '<Tab>' },
        directory_mappings = {
          { key = '~', path = '~', desc = 'Home directory' },
          { key = 'gd', path = '~/Downloads', desc = 'Downloads directory' },
          { key = 'gw', path = function() return vim.fn.getcwd() end, desc = 'Current working directory' },
        },
      },
    })
  end,
  keys = {
    { 'n', ',,', '<cmd>NetrwRevealToggle<cr>', { desc = 'Toggle Netrw - Reveal' } },
    { 'n', ',l', '<cmd>NetrwRevealLexToggle<cr>', { desc = 'Toggle Netrw (Lex) - Reveal' } },
  },
})
--: }}}

--: Lazy load blink-cmp {{{
p({
  src = 'saghen/blink.cmp',
  event = 'InsertEnter',
  -- version = 'v1.6.0',
  build = "cargo build --release",
  config = function()
    require('blink.cmp').setup({
      cmdline = {
        enabled = false,
        completion = {
          menu = { auto_show = false },
          list = { selection = { preselect = false, auto_insert = true } },
        },
      },

      sources = {
        default = { 'lsp', 'path', 'buffer', 'snippets' },
        providers = {
          lsp = { opts = { tailwind_color_icon = '󱓻' } },
        },
      },

      completion = {
        accept = { auto_brackets = { enabled = true } },
        list = { selection = { preselect = false, auto_insert = true } },
        menu = {
          auto_show = true,
          draw = {
            gap = 2,
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
      },

      keymap = {
        preset = 'enter',
        ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<Tab>'] = { 'select_next', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'fallback' },
        ['<Up>'] = { 'select_prev', 'fallback' },
        ['<Down>'] = { 'select_next', 'fallback' },
        ['<C-e>'] = { 'hide', 'fallback' },
        ['<C-y>'] = { 'select_and_accept' },
        ['<C-j>'] = { 'snippet_forward', 'fallback' },
        ['<C-k>'] = { 'snippet_backward', 'fallback' },
        ['<C-p>'] = { 'select_prev', 'fallback' },
        ['<C-n>'] = { 'select_next', 'fallback' },
        ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
        ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
      },
    })
  end,
})
--: }}}

--: zk-nvim {{{
p({
  src = 'zk-org/zk-nvim',
  dependencies = { 'ibhagwan/fzf-lua' },
  ft = 'markdown',
  cmd = { 'ZkNotes', 'ZkTags', 'ZkBacklinks' },
  keys = {
    { 'n', '<leader>nf', "<cmd>ZkNotes { sort = { 'modified' } }<cr>", { silent = true, desc = 'ZK Find Notes' } },
    {
      'n',
      '<leader>nn',
      "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>",
      { silent = true, desc = 'ZK New Note' },
    },
    { 'n', '<leader>nd', "<cmd>ZkNew { dir = 'journal/daily' }<cr>", { silent = true, desc = 'ZK Daily Note' } },
    { 'n', '<leader>nw', "<Cmd>ZkNew { dir = 'journal/weekly' }<CR>", { silent = true, desc = 'ZK Weekly Note' } },
    { 'n', '<leader>nt', '<Cmd>ZkTag<CR>', { silent = true, desc = 'ZK Tags' } },
    { 'n', '<leader>nb', '<Cmd>ZkBacklinks<CR>', { silent = true, desc = 'ZK Backlinks' } },
    {
      'n',
      '<leader>nss',
      "<Cmd>ZkNotes { sort = { 'modified' }, match = { vim.fn.input('Search: ') } }<CR>",
      { silent = true, desc = 'ZK Search query' },
    },
    { 'n', '<leader>nsd', '<Cmd>ZkNotesDaily<CR>', { silent = true, desc = 'ZK Search Daily Notes' } },
    { 'n', '<leader>nsw', '<Cmd>ZkNotesWeekly<CR>', { silent = true, desc = 'ZK Search Weekly Notes' } },
  },
  config = function()
    local zk = require('zk')
    local commands = require('zk.commands')

    local function make_edit_fn(defaults, picker_options)
      return function(options)
        options = vim.tbl_extend('force', defaults, options or {})
        zk.edit(options, picker_options)
      end
    end

    commands.add(
      'ZkNotesDaily',
      make_edit_fn({ hrefs = { 'journal/daily' }, sort = { 'modified' } }, { title = 'Zk Daily Notes' })
    )
    commands.add(
      'ZkNotesWeekly',
      make_edit_fn({ hrefs = { 'journal/weekly' }, sort = { 'modified' } }, { title = 'Zk Weekly Notes' })
    )

    require('zk').setup({
      picker = 'fzf_lua',
    })
  end,
})
--: }}}
