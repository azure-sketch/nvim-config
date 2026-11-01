local M = {}

local keymap = require("ui.vscode.keymap")

local function close_editor()
  local ok, err = pcall(function()
    require("astrocore.buffer").close()
  end)

  if not ok then
    vim.notify(tostring(err), vim.log.levels.WARN)
  end
end

-- grug-farを含む、設定対象の編集領域に共通で設定する。
function M.attach(buf)
  local map = keymap.for_buffer(buf)

  -- 強制破棄は行わず、既存の終了処理へ委譲する。
  map({ "n", "i" }, "<C-w>", close_editor, "Close editor")
end

return M
