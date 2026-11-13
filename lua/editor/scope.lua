local M = {}

-- サイドバーのプロバイダが input = true を宣言していれば、入力領域とみなす。
-- editor.setup() は sidebar.setup() より先に走るため、先に登録を済ませる。
function M.is_input_area(buf)
  local sidebar = require("sidebar")
  local views = require("sidebar.views")

  sidebar.load()

  local name = views.name_of(buf)
  return name ~= nil and views.get(name).input == true
end

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

  -- 通常ファイルと、ファイルエディタではない入力領域を対象にする。
  return vim.bo[buf].buftype == "" or M.is_input_area(buf)
end

-- 通常ファイル用の編集機能を設定する対象か判定する。
function M.is_file_editor(buf)
  if not M.is_editable(buf) then
    return false
  end

  return vim.bo[buf].buftype == "" and not M.is_input_area(buf)
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
