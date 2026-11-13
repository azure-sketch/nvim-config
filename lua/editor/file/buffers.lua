local M = {}

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

  -- 既存ファイルの未保存変更を残したまま、
  -- 新しい編集バッファを作る。
  local new_buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(new_buf)

  resume_input()
end

-- キーの割り当ては editor/keymaps.lua にある。
M.switch = switch_buffer
M.new_file = new_file

return M
