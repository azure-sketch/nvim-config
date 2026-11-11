local M = {}

local keymap = require("editor.keymap")

local function move_match(command)
  local ok, err = pcall(vim.cmd, command)

  if not ok then
    vim.notify(tostring(err), vim.log.levels.INFO)
  end
end

-- 通常の編集ファイルだけに設定する。
function M.attach_file(buf, resume_input)
  local map = keymap.for_buffer(buf)

  map({ "n", "i" }, "<C-h>", function()
    require("editor.replace").open(resume_input)
  end, "Replace in current file")
end

-- grug-farを含む、設定対象の編集領域に共通で設定する。
function M.attach(buf)
  local map = keymap.for_buffer(buf)

  -- 検索語を入力してEnterで確定する。
  map("i", "<C-f>", "<Esc>/", "Find in file")
  map("n", "<C-f>", "/", "Find in file")

  map({ "n", "i" }, "<F3>", function()
    move_match("normal! n")
  end, "Next match")

  map({ "n", "i" }, "<S-F3>", function()
    move_match("normal! N")
  end, "Previous match")
end

return M
