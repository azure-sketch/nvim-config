-- Tab は検索入力欄の移動に使うため、このバッファでは補完を無効にする。
vim.b.completion = false
local buf = vim.api.nvim_get_current_buf()
require("sidebar.search_guide").setup_buffer(buf)
vim.schedule(function()
  if vim.api.nvim_buf_is_valid(buf) then
    require("sidebar.search_replace").setup_buffer(buf)
  end
end)
