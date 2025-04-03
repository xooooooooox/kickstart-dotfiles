-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- [[ Custom Keymaps ]]
--  My custom keymap
vim.keymap.set('n', '<leader>j', ':bnext<CR>', { desc = 'Switch to Next buffer', silent = true })
vim.keymap.set('n', '<leader>k', ':bprevious<CR>', { desc = 'Switch to Previous buffer', silent = true })
-- vim.keymap.set('n', '<leader>Cb', ':bd<CR>', { desc = 'Delete Current Buffer', silent = true })
-- vim.keymap.set('n', '<leader>C!', ':bd!<CR>', { desc = 'Force Delete Current Buffer', silent = true })

-- 命令行模式下，将 h/j/k/l 映射为左/下/上/右移动
vim.keymap.set('c', '<C-h>', '<left>', { desc = 'Move cursor left in command line', silent = false })
vim.keymap.set('c', '<C-j>', '<down>', { desc = 'Move cursor Down in command line', silent = false })
vim.keymap.set('c', '<C-k>', '<up>', { desc = 'Move cursor Up in command line', silent = false })
vim.keymap.set('c', '<C-l>', '<right>', { desc = 'Move cursor Right in command line', silent = false })

-- Yanking into clipboard
vim.keymap.set('v', '<leader>y', [["+y]], { desc = 'Yanking into Clipboard', silent = true })

-- Exiting insert mode
vim.keymap.set('i', 'jk', '<Esc>', { desc = 'Exiting insert mode', silent = true })

-- vim: ts=2 sts=2 sw=2 et
