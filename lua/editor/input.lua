local M = {}

function M.is_editable(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  if not vim.bo[buf].modifiable then
    return false
  end

  local name = vim.api.nvim_buf_get_name(buf)

  if name:match("^fugitive://") then
    return false
  end

  -- 通常ファイルと、検索・置換の入力画面を対象にする。
  return vim.bo[buf].buftype == ""
      or vim.bo[buf].filetype == "grug-far"
end

-- 通常ファイル用の編集機能を設定する対象か判定する。
function M.is_file_editor(buf)
  if not M.is_editable(buf) then
    return false
  end

  return vim.bo[buf].buftype == ""
      and vim.bo[buf].filetype ~= "grug-far"
end

function M.resume()
  vim.schedule(function()
    if not M.is_editable(vim.api.nvim_get_current_buf()) then
      return
    end

    if vim.fn.mode() ~= "n" then
      return
    end

    vim.cmd("startinsert")
  end)
end

return M
