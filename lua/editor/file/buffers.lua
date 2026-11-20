local M = {}

-- 名前付きの通常ファイル、または変更済みの無名バッファが残っているか。
local function has_file_buffer()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf)
        and vim.bo[buf].buflisted and vim.bo[buf].buftype == ""
    then
      if vim.api.nvim_buf_get_name(buf) ~= "" or vim.bo[buf].modified then
        return true
      end
    end
  end
  return false
end

function M.close()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_get_current_buf()
  local ok, err = pcall(function()
    -- listedの有無や残数によらずウィンドウを保持する公開APIを使う。
    -- forceは指定せず、未保存変更の確認とキャンセルを維持する。
    require("snacks").bufdelete({ buf = buf })
  end)

  if not ok then
    vim.notify(tostring(err), vim.log.levels.WARN)
    return
  end

  vim.schedule(function()
    -- キャンセル時や別処理による窓の破棄・切替を上書きしない。
    if not vim.api.nvim_win_is_valid(win)
        or vim.api.nvim_win_get_buf(win) == buf
        or has_file_buffer()
    then
      return
    end
    local replacement = vim.api.nvim_win_get_buf(win)
    if vim.bo[replacement].buftype == ""
        and vim.api.nvim_buf_get_name(replacement) == ""
        and not vim.bo[replacement].modified
    then
      require("editor.global.dashboard").show(win)
    end
  end)
end

local function switch_buffer(direction, resume_input)
  vim.cmd("stopinsert")

  local ok, err = pcall(function()
    require("astrocore.buffer").nav(direction)
  end)

  if not ok then
    vim.notify(tostring(err), vim.log.levels.WARN)
  end

  resume_input()
end

local function new_file(resume_input)
  vim.cmd("stopinsert")

  -- 既存ファイルの未保存変更を残したまま、新しい編集バッファを作る。
  local new_buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(new_buf)

  resume_input()
end

M.switch = switch_buffer
M.new_file = new_file

return M
