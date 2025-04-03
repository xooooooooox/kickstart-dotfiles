-- nvim-window-picker
-- https://github.com/s1n7ax/nvim-window-picker

return {
  {
    's1n7ax/nvim-window-picker',
    name = 'window-picker',
    event = 'VeryLazy',
    version = '2.*',
    config = function()
      require('window-picker').setup {
        hint = 'floating-big-letter', -- statusline-winbar | floating-big-letter
        filter_rules = {
          autoselect_one = true,
          include_current_win = false,
          -- filter using buffer options
          bo = {
            -- if the file type is one of following, the window will be ignored
            filetype = { 'NvimTree', 'neo-tree', 'notify' },
            -- if the buffer type is one of the following, the window will be ignored
            buftype = { 'terminal', 'quickfix' },
          },
        },
      }
    end,
  },
}
