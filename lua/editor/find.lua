local M = {}

local keymap = require("keymap")

-- 通常の編集ファイルだけに設定する。
-- ファイル内検索のキーは editor/keymaps.lua にある。
function M.attach_file(buf, resume_input)
  local map = keymap.for_buffer(buf)

  map({ "n", "i" }, "<C-h>", function()
    require("editor.replace").open(resume_input)
  end, "Replace in current file")
end

return M
