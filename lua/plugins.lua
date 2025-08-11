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
      ensure_installed = { 'lua', 'vim', 'vimdoc', 'query', 'go', 'markdown', 'rust', 'python', 'markdown_inline' },
      highlight = { enable = true, additional_vim_regex_highlighting = false },
      indent = { enable = true },
    })
  end,
})

p({
  src = 'nvim-treesitter/nvim-treesitter-textobjects',
  event = 'LspAttach',
  config = function()
    local opts = {
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ['af'] = '@function.outer',
            ['if'] = '@function.inner',
            ['ac'] = '@conditional.outer',
            ['ic'] = '@conditional.inner',
            ['al'] = '@loop.outer',
            ['il'] = '@loop.inner',
          },
        },
        lsp_interop = {
          enable = true,
          border = 'rounded',
          peek_definition_code = {
            ['<leader>dp'] = '@function.outer',
          },
        },
      },
    }
    require('nvim-treesitter.configs').setup(opts)
  end,
})
--: }}}

--: Lazy load conform {{{
p({
  src = 'stevearc/conform.nvim',
  event = { 'BufReadPost', 'BufNewFile', 'BufWritePre' },
  keys = {
    {
      'n',
      '<leader>cf',
      function() require('conform').format({ async = true, lsp_fallback = true }) end,
      { desc = 'Code format' },
    },
  },
  config = function()
    local opts = {
      lsp_fallback = true,
      formatters_by_ft = {
        lua = { 'stylua' },
        javascript = { 'prettier' },
        typescript = { 'prettier' },
        javascriptreact = { 'prettier' },
        typescriptreact = { 'prettier' },
        css = { 'prettier' },
        html = { 'prettier' },
        sh = { 'shfmt' },
        go = { 'goimports', 'gofumpt' },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_format = 'fallback',
      },
    }
    require('conform').setup(opts)
  end,
})
--}}}

--: Lazy load mini.diff {{{
p({
  src = 'echasnovski/mini.diff',
  event = { 'BufReadPost', 'BufNewFile', 'BufWritePre' },
  config = function()
    local minidiff = require('mini.diff')
    minidiff.setup({
      view = { signs = { add = ' ┃', change = ' ┃', delete = ' _' } },
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

--: Lazy load blink-cmp {{{
p({
  src = 'saghen/blink.cmp',
  event = { 'InsertEnter', 'CmdlineEnter' },
  -- version = 'v1.6.0',
  build = 'cargo build --release',
  config = function()
    require('blink.cmp').setup({
      cmdline = {
        enabled = true,
        completion = {
          menu = { auto_show = true },
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

--: Lazy load fff.nvim {{{
p({
  src = 'dmtrKovalenko/fff.nvim',
  dependencies = { 'echasnovski/mini.icons' },
  build = 'cargo build --release',
  config = function()
    require('fff').setup({
      preview = { enabled = true },
      -- debug = { show_scores = true, }, -- Toggle with F2 or :FFFDebug
      -- icons = { enabled = false },
      keymaps = {
        move_up = { '<Up>', '<C-p>', '<C-k>' },
        move_down = { '<Down>', '<C-n>', '<C-j>' },
        close = { '<Esc>', '<C-c>' },
        select = { '<CR>', '<C-l>' },
      },
    })
  end,
  keys = {
    { 'n', '<C-Space>', function() require('fff').find_files() end, { desc = 'FFF Files' } },
  },
})
--}}}

--: Lazy load mini.icons {{{
p({
  src = 'echasnovski/mini.icons',
  init = function()
    package.preload['nvim-web-devicons'] = function()
      require('mini.icons').mock_nvim_web_devicons()
      return package.loaded['nvim-web-devicons']
    end
  end,
  config = function()
    local opts = function()
      vim.api.nvim_set_hl(0, 'MiniIconsAzure', { fg = '#28A2D4' })
      return {
        file = {
          ['.keep'] = { glyph = '󰊢', hl = 'MiniIconsGrey' },
          ['devcontainer.json'] = { glyph = '', hl = 'MiniIconsAzure' },
          README = { glyph = '', hl = 'MiniIconsYellow' },
          ['README.md'] = { glyph = '', hl = 'MiniIconsYellow' },
          ['README.txt'] = { glyph = '', hl = 'MiniIconsYellow' },
        },
        filetype = {
          dotenv = { glyph = '', hl = 'MiniIconsYellow' },
          rust = { glyph = '🦀', hl = 'MiniIconsOrange' },
        },
      }
    end
    require('mini.icons').setup(opts())
  end,
})
--: }}}

--: Lazy load Oil.nvim {{{
p({
  src = 'stevearc/oil.nvim',
  cmd = 'Oil',
  dependencies = { 'echasnovski/mini.icons' },
  init = function()
    if vim.fn.argc(-1) == 1 then
      local stat = vim.loop.fs_stat(vim.fn.argv(0))
      if stat and stat.type == 'directory' then
        load_request('mini.icons')
        load_request('oil.nvim')
        require('oil')
      end
    end
  end,
  keys = {
    { 'n', '-', '<cmd>Oil<cr>', { desc = 'Oil - Parent Dir' } },
    { 'n', '<leader>oo', '<cmd>Oil --float<cr>', { desc = 'Oil Float - Parent Dir' } },
  },
  config = function()
    local opts = {
      default_file_explorer = true,
      view_options = {
        show_hidden = true,
      },
      float = {
        padding = 2,
        max_width = 90,
        max_height = 0,
      },
      win_options = {
        wrap = true,
        winblend = 0,
        signcolumn = 'yes',
      },
      keymaps = {
        ['<C-s>'] = false,
        ['q'] = 'actions.close',
        ['h'] = 'actions.parent',
        ['l'] = 'actions.select',
        ['s'] = 'actions.close',
        ['Y'] = 'actions.yank_entry',
        ['<C-p>'] = {
          callback = function()
            local oil = require('oil')
            -- Function to find if preview window is open
            local function find_preview_window()
              for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                if vim.api.nvim_win_is_valid(winid) and vim.wo[winid].previewwindow and vim.w[winid]['oil_preview'] then
                  return winid
                end
              end
              return nil
            end

            local preview_winid = find_preview_window()
            if preview_winid then
              -- Close the preview window if it's open
              vim.api.nvim_win_close(preview_winid, true)
            else
              -- Open preview if it's not open
              oil.open_preview({ vertical = true, split = 'botright' }, function(err)
                if not err then vim.cmd('vertical resize 40') end
              end)
            end
          end,
          desc = 'Toggle Oil preview',
        },
        ['gw'] = {
          desc = 'Go to working directory',
          callback = function() require('oil').open(vim.fn.getcwd()) end,
        },
        ['gd'] = {
          desc = 'Toggle file detail view',
          callback = function()
            detail = not detail
            if detail then
              require('oil').set_columns({ 'icon', 'permissions', 'size', 'mtime' })
            else
              require('oil').set_columns({ 'icon' })
            end
          end,
        },
        ['gf'] = {
          function()
            require('telescope.builtin').find_files({
              cwd = require('oil').get_current_dir(),
            })
          end,
          mode = 'n',
          nowait = true,
          desc = 'Find files in the current directory with Telescope',
        },
        ['.'] = {
          'actions.open_cmdline',
          opts = {
            shorten_path = true,
            -- modify = ":h",
          },
          desc = 'Open the command line with the current directory as an argument',
        },
      },
    }
    require('oil').setup(opts)
  end,
})
--: }}}

--: Lazy load Codecompanion {{{
p({
  src = 'olimorris/codecompanion.nvim',
  cmd = { 'CodeCompanion', 'CodeCompanionChat', 'CodeCompanionActions' },
  keys = {
    { { 'n', 'v' }, 'go', '<cmd>CodeCompanionChat Toggle<cr>', { desc = 'CodeCompanion Toggle' } },
    { { 'n', 'v' }, '<leader>jc', '<cmd>CodeCompanionChat Toggle<cr>', { desc = 'CodeCompanion Toggle' } },
    { { 'n', 'v' }, '<leader>jl', '<cmd>CodeCompanion<cr>', { desc = 'CodeCompanion Inline Assistant' } },
    { { 'n', 'v' }, '<leader>jA', '<cmd>CodeCompanionActions<cr>', { desc = 'CodeCompanion Actions' } },
    { 'v', '<leader>js', '<cmd>CodeCompanionChat Add<cr>', { desc = 'CodeCompanion Add Selection' } },
  },
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    local opts = {
      display = {
        chat = {
          window = {
            layout = 'vertical', -- use 'buffer' for full buffer
            height = 0.6,
            width = 0.45,
            position = nil, -- left|right|top|bottom
          },
        },
      },
      strategies = {
        chat = {
          adapter = 'copilot',
          keymaps = { change_adapter = { modes = { n = 'gA' } } },
        },
        inline = { adapter = 'copilot' },
      },
      adapters = {
        copilot = function()
          return require('codecompanion.adapters').extend('copilot', {
            schema = { model = { default = 'claude-sonnet-4' } },
          })
        end,
      },
    }
    require('codecompanion').setup(opts)
  end,
})
--}}}

--: Lazy load nvim-snippy {{{
p({
  src = 'dcampos/nvim-snippy',
  event = 'InsertEnter',
  keys = {
    {
      { 'i', 's' },
      '<C-J>',
      function() return require('snippy').can_expand_or_advance() and '<plug>(snippy-expand-or-advance)' or '<tab>' end,
      { expr = true, desc = 'Snippy - Next' },
    },
    {
      { 'i', 's' },
      '<C-K>',
      function() return require('snippy').can_jump(-1) and '<plug>(snippy-previous)' or '<s-tab>' end,
      { expr = true, desc = 'Snippy - Previous' },
    },
    { 'x', '<Tab>', '<plug>(snippy-cut-text)' },
    { 'n', 'g<Tab>', '<plug>(snippy-cut-text)' },
  },
})
--: }}}

--: Lazy load misc plugins {{{
p({ src = 'nvim-lua/plenary.nvim' })

p({
  src = 'michaeljsmith/vim-indent-object',
  event = { 'BufReadPost', 'BufNewFile' },
})

p({
  src = 'junegunn/vim-easy-align',
  cmd = 'EasyAlign',
  keys = {
    { 'x', 'ga', '<Plug>(EasyAlign)', { desc = 'EasyAlign' } },
    { 'x', '<leader>pt', ':EasyAlign *|<cr>', { desc = 'Align Markdown Table' } },
    { 'v', '<leader>pa', ':EasyAlign = l5', { desc = 'EasyAlign' } },
  },
})
--}}}
