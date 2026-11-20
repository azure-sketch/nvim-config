local M = {}

local FILETYPE = "snacks_dashboard"

-- どのウィンドウにも表示されない未変更の無名通常バッファを削除する。
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

-- Snacks 本体によるキー登録・再描画が完了してから上書きする。
local function disable_close_key()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf)
        and vim.bo[buf].filetype == FILETYPE
    then
      vim.keymap.set("n", "q", "<Nop>", {
        buffer = buf,
        silent = true,
        nowait = true,
        desc = "Disabled on dashboard",
      })
    end
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup(
    "EditorDashboard",
    { clear = true }
  )

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = {
      "SnacksDashboardOpened",
      "SnacksDashboardUpdatePost",
    },
    desc = "Disable dashboard close key after initialization and rendering",
    callback = disable_close_key,
  })

  -- setup より前に起動画面が生成されていた場合にも対応する。
  disable_close_key()
end

-- 指定ウィンドウ（省略時は現在のウィンドウ）に起動画面を表示する。
function M.show(win)
  vim.cmd("stopinsert")
  require("snacks").dashboard({ win = win or 0 })
  discard_blank_buffers()
end

return M
