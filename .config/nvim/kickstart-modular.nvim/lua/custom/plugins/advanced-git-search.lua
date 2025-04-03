-- advanced-git-search
-- https://github.com/aaronhallaert/advanced-git-search.nvim#%EF%B8%8F-installation

return {
  {
    'aaronhallaert/advanced-git-search.nvim',
    -- cmd = { 'Telescope advanced_git_search' },
    dependencies = {
      'nvim-telescope/telescope.nvim',
      -- to show diff splits and open commits in browser
      'tpope/vim-fugitive',
      -- to open commits in browser with fugitive
      'tpope/vim-rhubarb',
      -- optional: to replace the diff from fugitive with diffview.nvim
      -- (fugitive is still needed to open in browser)
      'sindrets/diffview.nvim',
    },
    config = function()
      require('telescope').setup {
        extensions = {
          advanced_git_search = {
            diff_plugin = 'diffview',
          },
        },
      }
      require('telescope').load_extension 'advanced_git_search'
      -- require('advanced_git_search.fzf').setup {}
    end,
  },
}
