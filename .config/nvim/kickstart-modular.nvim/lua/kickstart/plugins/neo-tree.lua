-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  keys = {
    { '\\', ':Neotree toggle<CR>', mode = 'n', desc = 'NeoTree toggle', silent = true },
    { '<leader>\\\\', ':Neotree focus<CR>', mode = 'n', desc = 'NeoTree focus', silent = true },
    { '<leader>\\.', ':Neotree reveal<CR>', mode = 'n', desc = 'NeoTree reveal', silent = true },
    { '<leader>h\\', ':Neotree focus right git_status<CR>', mode = 'n', desc = 'NeoTree git_status', silent = true },
  },
  opts = {
    source_selector = {
      winbar = true,
      statusline = false,
    },
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
      filtered_items = {
        find_args = {
          fd = {
            '--exclude',
            '.git',
            '--exclude',
            'node_modules',
          },
        },
        visible = true, -- then true, they will jest be displayed differently than normal items
        hide_dotfiles = false,
        hide_gitignored = true,
        hide_by_name = {
          '.git',
          'node_modules',
        },
        hide_by_pattern = { -- uses glob style patterns
          '*.meta',
        },
        always_show = { -- remains visible even if other settings would normally hide it
          '.gitignored',
        },
        always_show_by_pattern = { -- uses glob style patterns
          '.env*',
        },
        never_show = { -- remains hidden enven if visible is toggled to true, this overrides always_show
          '.DS_Store',
          '.thumbs.db',
          '.Trash',
        },
        never_show_pattern = { -- uses glob style pattern
          '.null-ls_*',
        },
      },
    },
  },
}
