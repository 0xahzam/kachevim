-- Leader key configuration
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.api.nvim_set_keymap('n', '<C-a>', 'ggVG', { noremap = true, silent = true }) -- Select all text

-- Basic editor settings
vim.opt.number = true -- Show line numbers
vim.opt.mouse = 'a' -- Enable mouse support
vim.opt.showmode = false -- Don't show mode in command line
vim.opt.clipboard = 'unnamedplus' -- Use system clipboard
vim.opt.breakindent = true -- Indent wrapped lines
vim.opt.undofile = true -- Persistent undo history
vim.opt.ignorecase = true -- Case insensitive search
vim.opt.smartcase = true -- Smart case sensitivity
vim.opt.signcolumn = 'yes' -- Always show sign column
vim.opt.updatetime = 100 -- Faster updates
vim.opt.timeoutlen = 250 -- Shorter key timeout
vim.opt.splitright = true -- Split windows to the right
vim.opt.splitbelow = true -- Split windows below
vim.opt.list = true -- Show invisible characters
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' } -- Characters for invisibles
vim.opt.inccommand = 'split' -- Preview substitutions
vim.opt.cursorline = true -- Highlight current line
vim.opt.scrolloff = 10 -- Keep 10 lines visible above/below cursor
vim.opt.hlsearch = true -- Highlight search results
vim.opt.lazyredraw = true -- Don't redraw screen during macros
vim.opt.syntax = 'on' -- Enable syntax highlighting
vim.opt.hidden = true -- Allow unsaved buffers in background
vim.opt.wrap = false -- Disable line wrapping




-- Key mappings
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>') -- Clear search highlights
vim.keymap.set('n', '<C-h>', '<C-w><C-h>') -- Move to left window
vim.keymap.set('n', '<C-l>', '<C-w><C-l>') -- Move to right window
vim.keymap.set('n', '<C-j>', '<C-w><C-j>') -- Move to window below
vim.keymap.set('n', '<C-k>', '<C-w><C-k>') -- Move to window above
vim.keymap.set('n', '<leader>n', ':bnext<CR>', { silent = true }) -- Next buffer
vim.keymap.set('n', '<leader>p', ':bprevious<CR>', { silent = true }) -- Previous buffer
vim.keymap.set('n', '<leader>d', ':bdelete<CR>', { silent = true }) -- Delete buffer

-- Highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function() vim.highlight.on_yank({ timeout = 200 }) end,
})

-- Enable faster loading
vim.loader.enable()

-- Plugin manager setup
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', 'https://github.com/folke/lazy.nvim.git', lazypath }
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  'tpope/vim-sleuth', -- Detect indentation
  { 'numToStr/Comment.nvim', opts = {} }, -- Easy code commenting

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      require("nvim-tree").setup({
        renderer = {
          icons = {
            webdev_colors = true,
            show = {
              file = false,
              folder = false,
              folder_arrow = true,
              git = false,
            },
            glyphs = {
              folder = {
                arrow_closed = "▸",
                arrow_open = "▾",
              },
            },
          },
        },
        view = {
          signcolumn = "no",
        },
      })
      vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = 'Toggle file explorer' })
    end
  },

  -- Fuzzy finder
  {
    'nvim-telescope/telescope.nvim',
    event = 'VeryLazy', -- Load when needed
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim', -- Required dependency
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' }, -- Faster fuzzy finding
    },
    config = function()
      require('telescope').setup {
        defaults = {
          path_display = { 'truncate' }, -- Truncate path display
          cache_picker = {
            num_pickers = 5, -- Cache recent pickers
          },
        },
        pickers = {
          find_files = {
            theme = "dropdown", -- Use dropdown style
            previewer = false, -- Disable previewer for speed
          },
        },
      }

      pcall(require('telescope').load_extension, 'fzf')

      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          previewer = false,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })
    end,
  },

  -- LSP support
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' }, -- Load only when opening files
    dependencies = {
      { 'williamboman/mason.nvim' }, -- Package manager for LSP
      { 'williamboman/mason-lspconfig.nvim' }, -- Bridge between Mason and LSP
    },
    config = function()
      require('mason').setup({
        ui = {
          border = "rounded", -- Rounded borders
        },
      })
      
      -- LSP key mappings when server attaches
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          local buf = event.buf
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = buf })
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, { buffer = buf })
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = buf })
          vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { buffer = buf })
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { buffer = buf })
        end,
      })

      local capabilities = vim.lsp.protocol.make_client_capabilities()

      -- Configure language servers
      local servers = {
        lua_ls = {
          settings = {
            Lua = {
              telemetry = { enable = false },
              workspace = { checkThirdParty = false },
            },
          },
        },
        tsserver = {},
      }

      -- Setup automatic installations
      require('mason-lspconfig').setup({
        ensure_installed = vim.tbl_keys(servers),
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            server.capabilities = capabilities
            require('lspconfig')[server_name].setup(server)
          end,
        },
      })
    end,
  },

  -- Auto-completion
  {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter', -- Load only when entering insert mode
    dependencies = {
      { 'L3MON4D3/LuaSnip' }, -- Snippet engine
      'saadparwaiz1/cmp_luasnip', -- Snippet source
      'hrsh7th/cmp-nvim-lsp', -- LSP source
      'hrsh7th/cmp-path', -- Path source
    },
    config = function()
      local cmp = require 'cmp'
      local luasnip = require 'luasnip'
      luasnip.config.setup {}

      cmp.setup {
        performance = {
          max_view_entries = 25, -- Limit displayed items
          debounce = 60, -- Debounce completion
        },
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = { completeopt = 'menu,menuone,noinsert' }, -- Completion options
        mapping = cmp.mapping.preset.insert {
          ['<C-n>'] = cmp.mapping.select_next_item(), -- Next item
          ['<C-p>'] = cmp.mapping.select_prev_item(), -- Previous item
          ['<C-y>'] = cmp.mapping.confirm { select = true }, -- Confirm selection
          ['<C-Space>'] = cmp.mapping.complete {}, -- Show completion
        },
        sources = {
          { name = 'nvim_lsp', priority = 1000 }, -- LSP completions (highest priority)
          { name = 'luasnip', priority = 750 }, -- Snippets
          { name = 'path', priority = 500 }, -- File paths
        },
      }
    end,
  },

  -- Theme
  {
    'navarasu/onedark.nvim',
    priority = 1000, -- Load early
    config = function()
      require('onedark').setup({
        style = 'dark', -- Dark theme style
        transparent = true, -- Use transparent background
        term_colors = true, -- Set terminal colors
        code_style = {
          comments = 'italic', -- Italic comments
          keywords = 'bold', -- Bold keywords
          functions = 'none', -- Default style for functions
          strings = 'none', -- Default style for strings
          variables = 'none', -- Default style for variables
        },
        diagnostics = {
          darker = true, -- Darker background for diagnostics
          background = false, -- No diagnostic background
        },
      })
      require('onedark').load() -- Apply the theme
    end,
  },
 
  -- Status line
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy', -- Load when needed
    opts = {
      options = {
        theme = 'onedark', -- Match theme
        component_separators = '|', -- Separator character
        section_separators = '', -- No section separators
        globalstatus = true, -- One statusline for all windows
        refresh = {
          statusline = 250, -- Update frequency
          tabline = 500,
          winbar = 500,
        },
      },
      sections = {
        lualine_a = {'mode'}, -- Show mode
        lualine_b = {'branch'}, -- Keep git branch display as requested
        lualine_c = {'filename'}, -- Show filename
        lualine_x = {'filetype'}, -- Show filetype
        lualine_y = {'progress'}, -- Show progress
        lualine_z = {'location'}, -- Show location
      },
    },
  },

  -- Syntax highlighting with Treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate', -- Update parsers when updated
    event = { 'BufReadPost', 'BufNewFile' }, -- Load when needed
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = { 'lua', 'vim', 'javascript', 'typescript' },
        auto_install = true, -- Auto install missing parsers
        highlight = { 
          enable = true, -- Enable highlighting
          additional_vim_regex_highlighting = false, -- Disable legacy highlighting
        },
        indent = { enable = true }, -- Enable indentation
        sync_install = false, -- Async installation
      })
      
      require('nvim-treesitter.install').prefer_git = true -- Use git for installation
    end,
  },
})
