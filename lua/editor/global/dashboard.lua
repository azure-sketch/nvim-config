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

-- 起動画面から離れる操作を無効にする（q など）。
-- Snacks がキーを登録し終えた後に上書きするため、schedule する。
local function lock_keys(buf)
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end

    vim.keymap.set("n", "q", "<Nop>", {
      buffer = buf,
      silent = true,
      nowait = true,
      desc = "Disabled on dashboard",
    })
  end)
end

-- ファイルが別ウィンドウで開かれたら、残った起動画面を閉じる。
-- 例: 起動画面だけの状態で grug-far の結果を開いた場合。
local function close_when_file_opens(file_buf)
  vim.schedule(function()
    if not is_named_file(file_buf) then
      return
    end

    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local buf = vim.api.nvim_win_get_buf(win)

      if vim.bo[buf].filetype == FILETYPE
          and #vim.api.nvim_tabpage_list_wins(0) > 1
      then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end

    discard_blank_buffers()
  end)
end

-- 起動画面の閉じ方を制御するautocmdを登録する。
function M.setup()
  local group = vim.api.nvim_create_augroup("EditorDashboard", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = FILETYPE,
    desc = "Keep dashboard open until a file buffer appears",
    callback = function(event)
      lock_keys(event.buf)
    end,
  })

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
