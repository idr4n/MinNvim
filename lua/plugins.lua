-- vim: foldmethod=marker foldlevel=0

local manager = require('package_manager')
local p = manager.add

--: Lazy load treesitter {{{
p({
  src = 'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  event = { 'BufReadPost', 'BufNewFile', 'BufWritePre' },
  dependencies = { 'JoosepAlviste/nvim-ts-context-commentstring' },
  config = function()
    require('nvim-treesitter.configs').setup({
      ensure_installed = {
        'bash',
        'cpp',
        'css',
        'go',
        'html',
        'json',
        'latex',
        'lua',
        'markdown',
        'markdown_inline',
        'python',
        'query',
        'rust',
        'scss',
        'tsx',
        'typescript',
        'typst',
        'vim',
        'vimdoc',
      },
      highlight = { enable = true, additional_vim_regex_highlighting = false },
      indent = { enable = true },
    })
    require('ts_context_commentstring').setup({})
    vim.g.skip_ts_context_commentstring_module = true
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
      view = {
        signs = { add = ' ┃', change = ' ┋', delete = ' _' },
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
  end,
  keys = {
    { 'n', ',c', '<cmd>HighlightColors Toggle<cr>', { silent = true, desc = 'Toggle colorizer' } },
  },
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

--: Lazy load Telescope {{{
-- Telescope dependencies
p({ src = 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' })
p({ src = 'nvim-lua/popup.nvim' })
p({ src = 'nvim-telescope/telescope-ui-select.nvim' })

p({
  src = 'nvim-telescope/telescope.nvim',
  cmd = 'Telescope',
  dependencies = {
    'nvim-lua/popup.nvim',
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope-ui-select.nvim',
    'nvim-telescope/telescope-fzf-native.nvim',
  },
  keys = {
    {
      'n',
      '<leader>ff',
      function() require('telescope.builtin').find_files() end,
      { noremap = true, silent = true, desc = 'Telescope-find_files' },
    },
    {
      'n',
      '<leader>ot',
      '<cmd>Telescope resume<cr>',
      { noremap = true, silent = true, desc = 'Telescope Resume' },
    },
    { 'n', '<leader>sh', '<cmd>Telescope highlights<cr>', { noremap = true, silent = true, desc = 'Highlights' } },
    { 'n', '<leader>sk', '<cmd>Telescope keymaps<cr>', { noremap = true, silent = true, desc = 'Keymaps' } },
    {
      'n',
      '<leader>gs',
      '<cmd>Telescope git_status initial_mode=normal<cr>',
      { noremap = true, silent = true, desc = 'Git Status' },
    },
    { 'n', '<leader>gb', '<cmd>Telescope git_bcommits<cr>', { noremap = true, silent = true, desc = 'Git BCommits' } },
    { 'n', '<leader>ot', '<cmd>Telescope live_grep<cr>', { noremap = true, silent = true, desc = 'Telescope Resume' } },
    { 'n', '<leader>r', '<cmd>Telescope live_grep<cr>', { noremap = true, silent = true, desc = 'Live Grep' } },
    {
      'v',
      '<leader>r',
      function()
        local text = vim.getVisualSelection()
        require('telescope.builtin').live_grep({ default_text = text })
      end,
      { noremap = true, silent = true, desc = 'Live Grep' },
    },
    {
      'n',
      's',
      function()
        require('telescope.builtin').buffers(
          dropdown_theme({ initial_mode = 'normal', sort_lastused = false, select_current = true })
        )
      end,
      { noremap = true, silent = true, desc = 'Switch buffers' },
    },
    { 'n', '<leader>sh', '<cmd>Telescope help_tags<cr>', { noremap = true, silent = true, desc = 'Help pages' } },
    {
      'v',
      '<leader>sh',
      function()
        local text = vim.getVisualSelection()
        require('telescope.builtin').help_tags({ default_text = text })
      end,
      { noremap = true, silent = true, desc = 'Help pages with selection' },
    },
  },
  config = function()
    _G.dropdown_theme = function(opts)
      opts = vim.tbl_deep_extend('force', {
        disable_devicons = false,
        previewer = false,
        layout_config = {
          width = function(_, max_columns, _) return math.min(math.floor(max_columns * 0.8), 92) end,
          height = function(_, _, max_lines) return math.min(math.floor(max_lines * 0.8), 17) end,
        },
      }, opts or {})
      return require('telescope.themes').get_dropdown(opts)
    end

    local opts = function()
      local actions = require('telescope.actions')
      return {
        defaults = {
          file_ignore_patterns = {
            'node_modules',
            '.DS_Store',
          },
          path_display = { 'filename_first' },
          prompt_prefix = '  ',
          selection_caret = '• ',
          results_title = false,
          preview = {
            hide_on_startup = false,
          },
          winblend = 0,
          sorting_strategy = 'descending',
          layout_strategy = 'flex',
          layout_config = {
            preview_cutoff = 120,
            width = 0.87,
            height = 0.80,
            flex = {
              flip_columns = 120,
            },
            vertical = {
              preview_cutoff = 40,
              prompt_position = 'bottom',
              preview_height = 0.4,
            },
            horizontal = {
              prompt_position = 'bottom',
              preview_width = 0.50,
            },
          },
          mappings = {
            i = {
              ['jk'] = { '<esc>', type = 'command' },
              ['<C-j>'] = actions.move_selection_next,
              ['<C-k>'] = actions.move_selection_previous,
              ['<C-c>'] = actions.close,
              ['<C-l>'] = require('telescope.actions.layout').toggle_preview,
            },
            n = {
              ['<esc>'] = actions.close,
              ['<C-c>'] = actions.close,
              ['s'] = actions.close,
              ['l'] = actions.select_default,
              ['<C-q>'] = actions.send_to_qflist + actions.open_qflist,
              ['<C-l>'] = require('telescope.actions.layout').toggle_preview,
            },
          },
        },
        pickers = {
          find_files = {
            find_command = {
              'rg',
              '--files',
              '--hidden',
              '--follow',
              '--no-ignore',
              '-g',
              '!{node_modules,.git,**/_build,deps,.elixir_ls,**/target,**/assets/node_modules,**/assets/vendor,**/.next,**/.vercel,**/build,**/out}',
            },
          },
          live_grep = {
            additional_args = function()
              return {
                '--hidden',
                '--follow',
                '--no-ignore',
                '-g',
                '!{node_modules,.git,**/_build,deps,.elixir_ls,**/target,**/assets/node_modules,**/assets/vendor,**/.next,**/.vercel,**/build,**/out}',
              }
            end,
          },
        },
        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown({
              layout_config = {
                height = function(_, _, max_lines) return math.min(max_lines, 12) end,
              },
            }),
          },
        },
      }
    end
    local telescope = require('telescope')
    telescope.setup(opts())
    telescope.load_extension('fzf')
    telescope.load_extension('ui-select')
  end,
})
--:}}}

--: Lazy load NvimTree {{{
p({
  src = 'nvim-tree/nvim-tree.lua',
  event = { 'BufReadPost', 'BufNewFile', 'BufWritePre' },
  cmd = { 'NvimTreeToggle', 'NvimTreeFocus' },
  keys = {
    {
      'n',
      '<leader><Space>',
      "<cmd>lua require('nvim-tree.api').tree.toggle({ focus = false })<CR>",
      { silent = true, desc = 'Nvimtree Toggle' },
    },
    {
      'n',
      '<leader>e',
      "<cmd>lua require('nvim-tree.api').tree.open()<CR>",
      { silent = false, desc = 'Nvimtree Focus window' },
    },
    {
      'n',
      '<leader>na',
      "<cmd>lua require('nvim-tree.api').tree.collapse_all()<CR>",
      { silent = true, desc = 'NvimTree Collapse All' },
    },
    {
      'n',
      '<leader>nc',
      function()
        require('nvim-tree.api').tree.collapse_all({ focus = false })
        require('nvim-tree.api').tree.find_file()
      end,
      { silent = true, desc = 'NvimTree Collapse' },
    },
  },
  config = function()
    local opts = {
      on_attach = function(bufnr)
        local api = require('nvim-tree.api')

        local function opts(desc)
          return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
        end

        -- default mappings
        api.config.mappings.default_on_attach(bufnr)

        -- remove a default mapping
        vim.keymap.del('n', '<C-t>', { buffer = bufnr })

        vim.keymap.set('n', 'l', api.node.open.edit, opts('Edit Or Open'))

        vim.keymap.set('n', 'h', function()
          local node = api.tree.get_node_under_cursor()
          if node.nodes ~= nil then
            api.node.navigate.parent_close()
          else
            api.node.navigate.parent()
          end
        end, opts('Go to parent or close'))

        vim.keymap.set('n', '<CR>', function()
          api.node.open.edit()
          api.tree.close_in_this_tab()
        end, opts('Open and close tree'))
      end,

      filters = {
        dotfiles = false,
        git_ignored = false,
      },

      disable_netrw = false,
      hijack_netrw = false,
      hijack_cursor = true,
      sync_root_with_cwd = true,

      update_focused_file = {
        enable = true,
        update_root = false,
      },
      view = {
        adaptive_size = false,
        side = 'right',
        width = 29,
        preserve_window_proportions = true,
        signcolumn = 'no',
      },
      git = { enable = true, ignore = true },
      filesystem_watchers = { enable = true },
      actions = { expand_all = { max_folder_discovery = 300, exclude = { '.git' } } },
      diagnostics = {
        enable = true,
        show_on_dirs = true,
        show_on_open_dirs = true,
        icons = {
          hint = '',
          info = '',
          warning = '',
          error = '',
        },
      },
      renderer = {
        root_folder_label = false,
        highlight_git = true,
        highlight_opened_files = 'none',

        indent_markers = {
          enable = true,
        },

        icons = {
          show = {
            file = true,
            folder = true,
            folder_arrow = true,
            git = true,
            diagnostics = true,
          },
          glyphs = {
            default = '󰈚',
            symlink = '',
            folder = {
              default = '',
              empty = '',
              empty_open = '',
              open = '',
              symlink = '',
              symlink_open = '',
              arrow_open = '',
              arrow_closed = '',
            },
            git = {
              unstaged = '✗',
              staged = '✓',
              unmerged = '',
              renamed = '➜',
              untracked = '★',
              deleted = '',
              ignored = '◌',
            },
          },
        },
      },
    }
    require('nvim-tree').setup(opts)
  end,
})
--}}}

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
    { 'n', '-', function() require('oil').open() end, { desc = 'Oil - Parent Dir' } },
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
        ['.'] = {
          'actions.open_cmdline',
          opts = { shorten_path = true },
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
    'saghen/blink.cmp',
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

p({
  src = 'lukas-reineke/virt-column.nvim',
  event = 'BufReadPost',
  config = function()
    local opts = {
      char = { '│' },
      virtcolumn = '80',
      exclude = { filetypes = { 'markdown', 'oil' } },
    }
    require('virt-column').setup(opts)
  end,
})

p({
  src = 'nvim-treesitter/nvim-treesitter-context',
  event = { 'BufReadPost', 'BufNewFile', 'BufWritePre' },
  config = function()
    local opts = {
      max_lines = 3,
      multiline_threshold = 1,
    }
    require('treesitter-context').setup(opts)
  end,
  keys = {
    {
      'n',
      '<leader>lc',
      function()
        vim.schedule(function() require('treesitter-context').go_to_context() end)
        return '<Ignore>'
      end,
      { desc = 'Jump to upper context', expr = true },
    },
  },
})

p({ src = 'JoosepAlviste/nvim-ts-context-commentstring' })
p({
  src = 'numToStr/Comment.nvim',
  event = { 'BufReadPost', 'BufNewFile' },
  dependencies = {
    'JoosepAlviste/nvim-ts-context-commentstring',
  },
  config = function()
    local opts = {
      pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
    }
    require('Comment').setup(opts)
  end,
})

p({
  src = 'RRethy/vim-illuminate',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    local opts = {
      delay = 200,
      large_file_cutoff = 2000,
      large_file_overrides = {
        providers = { 'lsp' },
      },
    }
    require('illuminate').configure(opts)

    local function map(key, dir, buffer)
      vim.keymap.set(
        'n',
        key,
        function() require('illuminate')['goto_' .. dir .. '_reference'](false) end,
        { desc = dir:sub(1, 1):upper() .. dir:sub(2) .. ' Reference', buffer = buffer }
      )
    end

    map(']]', 'next')
    map('[[', 'prev')

    -- also set it after loading ftplugins, since a lot overwrite [[ and ]]
    vim.api.nvim_create_autocmd('FileType', {
      callback = function()
        local buffer = vim.api.nvim_get_current_buf()
        map(']]', 'next', buffer)
        map('[[', 'prev', buffer)
      end,
    })
  end,
  keys = {
    { 'n', ']]', { desc = 'Next Reference' } },
    { 'n', '[[', { desc = 'Prev Reference' } },
  },
})

p({
  src = 'Wansmer/treesj',
  keys = {
    { 'n', '<leader>cj', '<cmd>TSJToggle<cr>', { desc = 'Join/split code block' } },
  },
  config = function()
    local opts = { use_default_keymaps = false, max_join_length = 999 }
    require('treesj').setup(opts)
  end,
})

p({
  src = 'abecodes/tabout.nvim',
  event = 'InsertEnter',
  dependencies = { 'nvim-treesitter' },
  config = function()
    local opts = {
      tabkey = [[<C-\>]], -- key to trigger tabout, set to an empty string to disable
      backwards_tabkey = [[<C-S-\>]], -- key to trigger backwards tabout, set to an empty string to disable
      act_as_tab = false, -- shift content if tab out is not possible
      act_as_shift_tab = false, -- reverse shift content if tab out is not possible (if your keyboard/terminal supports <S-Tab>)
      enable_backwards = true, -- well ...
      completion = true, -- if the tabkey is used in a completion pum
      tabouts = {
        { open = "'", close = "'" },
        { open = '"', close = '"' },
        { open = '`', close = '`' },
        { open = '(', close = ')' },
        { open = '[', close = ']' },
        { open = '{', close = '}' },
      },
      ignore_beginning = true, --[[ if the cursor is at the beginning of a filled element it will rather tab out than shift the content ]]
      exclude = {}, -- tabout will ignore these filetypes
    }
    require('tabout').setup(opts)
  end,
})
--}}}
