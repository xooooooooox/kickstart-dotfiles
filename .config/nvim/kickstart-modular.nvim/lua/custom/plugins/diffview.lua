-- diffview
-- https://github.com/sindrets/diffview.nvim

return {
  {
    'sindrets/diffview.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('diffview').setup {}
    end,
  },
}
