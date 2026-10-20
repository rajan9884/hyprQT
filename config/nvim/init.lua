-- Minimal init restored after dotfiles cleanup (old symlink was broken).
-- Tries LazyVim-style lazy bootstrap if present, otherwise plain defaults.
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
local lazy_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if vim.loop.fs_stat(lazy_path) then
  vim.opt.rtp:prepend(lazy_path)
  local ok, lazy = pcall(require, "lazy")
  if ok then
    pcall(function() require("config.lazy") end)
    return
  end
end
-- fallback: load local config modules if they exist
pcall(require, "config.options")
pcall(require, "config.keymaps")
pcall(require, "config.autocmds")
