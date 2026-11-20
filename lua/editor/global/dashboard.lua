local M = {}

local FILETYPE = "snacks_dashboard"

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

-- 名前付きの通常ファイルか判定する。ディレクトリは含めない。
local function is_named_file(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "" then
    return false
  end

  local name = vim.api.nvim_buf_get_name(buf)
  return name ~= "" and vim.fn.isdirectory(name) == 0
end

-- ファイルが別ウィンドウで開かれたら、残った起動画面を閉じる。
-- 例: 起動画面だけの状態で grug-far の結果を開いた場合。
-- 分割状態が描画されないよう、schedule せず同期的に閉じる。
local function close_when_file_opens(file_buf)
  if not is_named_file(file_buf) then
    return
  end

  local wins = vim.api.nvim_tabpage_list_wins(0)

  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)

    if vim.bo[buf].filetype == FILETYPE and #wins > 1 then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end

  -- 空バッファの片付けは、ウィンドウ構成が落ち着いてから行う。
  vim.schedule(discard_blank_buffers)
end

-- 起動画面を、ファイルが開かれたときに閉じるautocmdを登録する。
-- 起動画面を q で閉じられないようにする設定は plugins/snacks.lua が持つ。
function M.setup()
  local group = vim.api.nvim_create_augroup("EditorDashboard", { clear = true })

  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    desc = "Close dashboard window when a file opens beside it",
    callback = function(event)
      close_when_file_opens(event.buf)
    end,
  })
end

-- 指定ウィンドウ（省略時は現在のウィンドウ）に起動画面を表示する。
function M.show(win)
  vim.cmd("stopinsert")
  require("snacks").dashboard({ win = win or 0 })
  discard_blank_buffers()
end

return M
