local M = {}

-- どのウィンドウにも表示されない空の無名バッファを削除する。
local function discard_blank_buffers()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf)
        and vim.bo[buf].buflisted
        and vim.bo[buf].buftype == ""
        and vim.api.nvim_buf_get_name(buf) == ""
        and not vim.bo[buf].modified
        and #vim.fn.win_findbuf(buf) == 0
    then
      pcall(vim.api.nvim_buf_delete, buf, {})
    end
  end
end

-- 指定ウィンドウ（省略時は現在のウィンドウ）に起動画面を表示する。
function M.show(win)
  vim.cmd("stopinsert")
  require("snacks").dashboard({ win = win or 0 })
  discard_blank_buffers()
end

return M
