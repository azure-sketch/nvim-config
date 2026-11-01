local M = {}

local keymap = require("ui.vscode.keymap")

local keys = { "<C-/>", "<C-_>" }

local mappings = {
  { mode = "i", rhs = "<C-o>gcc" },
  { mode = "n", rhs = "gcc" },
  { mode = "x", rhs = "gcgv<C-g>" },
  { mode = "s", rhs = "<C-g>gcgv<C-g>" },
}

function M.attach(buf)
  local map = keymap.for_buffer(buf)

  -- Neovimのgc / gccマッピングへ委譲するため、
  -- コメント操作だけremapを有効にする。
  --
  -- Ctrl+_は、端末がCtrl+/の代わりに送る場合の別名。
  for _, key in ipairs(keys) do
    for _, mapping in ipairs(mappings) do
      map(
        mapping.mode,
        key,
        mapping.rhs,
        "Toggle line comment",
        { remap = true }
      )
    end
  end
end

return M
