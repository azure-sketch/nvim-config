local M = {}

local keymap = require("keymap")

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

-- 通常の編集ファイルだけに設定する。
-- エディタを閉じるキーは editor/keymaps.lua にある。
function M.attach_file(buf, resume_input)
  local map = keymap.for_buffer(buf)

  map({ "n", "i" }, "<C-PageUp>", function()
    switch_buffer(-1, resume_input)
  end, "Previous editor")

  map({ "n", "i" }, "<C-PageDown>", function()
    switch_buffer(1, resume_input)
  end, "Next editor")

  map({ "n", "i" }, "<C-n>", function()
    new_file(resume_input)
  end, "New file")
end

return M
