-- lazygit
--   https://github.com/kdheepak/lazygit.nvim#install
-- tips: 这个 nvim plugin 使用的前提是需要再本地安装 lazygit 软件,具体操作参考
-- (https://github.com/jesseduffield/lazygit?tab=readme-ov-file#homebrew)

return {
  {
    'kdheepak/lazygit.nvim',
    cmd = {
      'LazyGit',
      'LazyGitConfig',
      'LazyGitCurrentFile',
      'LazyGitFilter',
      'LazyGitFilterCurrentFile',
    },
    -- optional for floating window border decoration
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    -- setting the keybinding for LazyGit with 'keys' is recommended in
    -- order to load the plugin when the command is run for the first time
    keys = {
      { '<leader>lg', '<cmd>LazyGit<cr>', desc = 'LazyGit' },
    },
  },
}
