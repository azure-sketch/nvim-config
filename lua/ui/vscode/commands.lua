local M = {}

local keymap = require("ui.vscode.keymap")

-- 通常の編集ファイルだけに設定する。
function M.attach_file(buf, resume_input)
  local map = keymap.for_buffer(buf)

  map({ "n", "i" }, "<C-h>", function()
    require("ui.vscode_replace").open(resume_input)
  end, "Replace in current file")
end

-- 設定対象の編集領域に共通で設定する。
function M.attach(buf)
  local map = keymap.for_buffer(buf)

  -- ファイル先頭・末尾。
  map("i", "<C-Home>", "<C-o>gg<C-o>0", "Go to file start")
  map("i", "<C-End>", "<C-o>G<C-o>$<Right>", "Go to file end")

  -- ファイル内検索。検索語を入力してEnterで確定。
  map("i", "<C-f>", "<Esc>/", "Find in file")
  map("n", "<C-f>", "/", "Find in file")

  map({ "n", "i" }, "<F3>", function()
    local ok, err = pcall(vim.cmd, "normal! n")

    if not ok then
      vim.notify(tostring(err), vim.log.levels.INFO)
    end
  end, "Next match")

  map({ "n", "i" }, "<S-F3>", function()
    local ok, err = pcall(vim.cmd, "normal! N")

    if not ok then
      vim.notify(tostring(err), vim.log.levels.INFO)
    end
  end, "Previous match")

  -- 強制終了しないため、未保存の変更は保護される。
  map({ "n", "i" }, "<C-w>", function()
    local ok, err = pcall(function()
      require("astrocore.buffer").close()
    end)

    if not ok then
      vim.notify(tostring(err), vim.log.levels.WARN)
    end
  end, "Close editor")
end

return M
