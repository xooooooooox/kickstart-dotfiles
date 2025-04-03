-- markdown-preview
--  see https://github.com/iamcco/markdown-preview.nvim

-- Requirements:
-- 需要保证 markdownlint-cli 已经安装了
-- macos) brew install markdownlint-cli
-- *) npm install -g markdownlint-cli

return {
  {
    'iamcco/markdown-preview.nvim',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    ft = { 'markdown' },
    build = function(plugin)
      if vim.fn.executable 'npx' then
        vim.cmd('!cd ' .. plugin.dir .. ' && cd app && npx --yes yarn install')
      else
        vim.cmd [[Lazy load markdown-preview.nvim]]
        vim.fn['mkdp#util#install']()
      end
    end,
    init = function()
      if vim.fn.executable 'npx' then
        vim.g.mkdp_filetypes = { 'markdown' }
      end
    end,
    keys = {
      { '<leader>mp', ':MarkdownPreview<CR>', mode = 'n', desc = 'Markdown Preview', silent = true },
      { '<leader>ms', ':MarkdownPreviewStop<CR>', mode = 'n', desc = 'Markdown Preview Stop', silent = true },
      { '<leader>mt', ':MarkdownPreviewToggle<CR>', mode = 'n', desc = 'Markdown Preview Toggle', silent = true },
    },
    config = function()
      local g = vim.g
      g.mkdp_auto_start = 0
      g.mkdp_auto_close = 0
      g.mkdp_open_to_the_world = 1
      g.mkdp_open_ip = '127.0.0.1'
      g.mkdp_port = 8888
      g.mkdp_browser = 'none'
      g.mkdp_echo_preview_url = 1
      g.mkdp_preview_options = {
        disable_scroll_type = 0,
        disable_filename = 1,
      }
    end,
  },
}
