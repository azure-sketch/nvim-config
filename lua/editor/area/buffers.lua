local M = {}

-- 名前付きの通常ファイル、または変更済みの無名バッファが残っているか。
local function has_file_buffer()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted and vim.bo[buf].buftype == "" then
      if vim.api.nvim_buf_get_name(buf) ~= "" or vim.bo[buf].modified then
        return true
      end
    end
  end

  return false
end

-- 起動画面を出した後に、どのウィンドウにも表示されない空の無名バッファを削除する。
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

function M.close()
  local ok, err = pcall(function()
    require("astrocore.buffer").close()
  end)

  if not ok then
    vim.notify(tostring(err), vim.log.levels.WARN)
    return
  end

  -- 閉じた結果ファイルが1つも残らないときだけ、起動画面を表示する。
  -- 編集領域のウィンドウ内に出すため、win = 0 を渡す。
  vim.schedule(function()
    if has_file_buffer() then
      return
    end

    vim.cmd("stopinsert")
    require("snacks").dashboard({ win = 0 })
    discard_blank_buffers()
  end)
end

return M
