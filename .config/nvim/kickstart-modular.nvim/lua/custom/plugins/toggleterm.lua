-- toggleterm
-- https://github.com/akinsho/toggleterm.nvim

return {
  {
    'akinsho/toggleterm.nvim',
    version = '*',
    cmd = { 'ToggleTerm' },
    keys = {
      { [[<c-\>]] },
      {
        '<leader>tf',
        '<cmd>ToggleTerm size=40 direction=float<cr>',
        desc = 'ToggleTerm float',
        silent = true,
      },
      {
        '<leader>tt',
        '<cmd>ToggleTerm size=40 direction=tab<cr>',
        desc = 'ToggleTerm tab',
        silent = true,
      },
      {
        '<leader>tv',
        '<cmd>ToggleTerm size=40 direction=vertical<cr>',
        desc = 'ToggleTerm vertical',
        silent = true,
      },
      {
        '<leader>th',
        '<cmd>ToggleTerm size=20 direction=horizontal<cr>',
        desc = 'ToggleTerm horizontal',
        silent = true,
      },
    },
    config = function()
      require('toggleterm').setup {
        -- size = function(term)
        --   if term.direction == 'horizontal' then
        --     return 15
        --   elseif term.direction == 'vertical' then
        --     return vim.o.columns * 0.4
        --   end
        -- end,
        size = 20,
        open_mapping = [[<c-\>]],
        -- auto_scroll = true, -- automatically scroll to the bottom on terminal output
        direction = 'horizontal', -- horizontal, vertical, float, tab
      }
    end,
  },
}
