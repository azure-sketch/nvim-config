local M = {}

local keymap = require("ui.vscode.keymap")


-- 通常の編集ファイルだけに設定する。
function M.attach_file(buf)
  local map = keymap.for_buffer(buf)

  -- 入力中・通常状態から、現在行全体を選択する。
  map("i", "<C-l>",
    "<Esc>V<C-g>",
    "Select current line")

  map("n", "<C-l>",
    "V<C-g>",
    "Select current line")

  -- Selectモードでは、
  -- 行選択なら下へ拡張、それ以外なら行選択へ変更する。
  keymap.set("s", "<C-l>", function()
    if vim.fn.mode() == "S" then
      return "<C-g>j<C-g>"
    end

    return "<C-g>V<C-g>"
  end, {
    buffer = buf,
    silent = true,
    expr = true,
    desc = "Expand line selection",
  })

  -- Visualモード側にも同じ考え方で設定する。
  keymap.set("x", "<C-l>", function()
    if vim.fn.mode() == "V" then
      return "j<C-g>"
    end

    return "V<C-g>"
  end, {
    buffer = buf,
    silent = true,
    expr = true,
    desc = "Expand line selection",
  })

  -- 未選択なら現在行をOSクリップボードへコピー。
  map("i", "<C-c>",
    '<C-o>"+yy',
    "Copy current line")

  map("n", "<C-c>",
    '"+yy',
    "Copy current line")

  -- 未選択なら現在行をOSクリップボードへ切り取り。
  map("i", "<C-x>",
    '<C-o>"+dd',
    "Cut current line")

  map("n", "<C-x>",
    '"+dd',
    "Cut current line")
end

-- 設定対象の編集領域に共通で設定する。
function M.attach(buf)
  local map = keymap.for_buffer(buf)

  -- 全選択。最後にSelectモードへ移す。
  map({ "n", "i", "s", "x" }, "<C-a>",
    "<Esc>gg0vG$<C-g>", "Select all")

  -- 選択範囲のコピー・切り取り。
  map({ "s", "x" }, "<C-c>",
    '<C-g>"+y', "Copy selection")

  map({ "s", "x" }, "<C-x>",
    '<C-g>"+d', "Cut selection")

  -- OSクリップボードから貼り付け。
  keymap.set("i", "<C-v>", function()
    -- 行単位でコピーしたものは、現在行の上へ挿入。
    if vim.fn.getregtype("+") == "V" then
      return '<C-o>"+P'
    end

    -- 文字単位なら、カーソル位置へ貼り付け。
    return "<C-r><C-p>+"
  end, {
    buffer = buf,
    silent = true,
    expr = true,
    desc = "Paste",
  })
  map("n", "<C-v>", '"+p', "Paste")

  -- 選択範囲を削除してから貼り付ける。
  -- 削除内容でクリップボードを上書きしない。
  map({ "s", "x" }, "<C-v>",
    '<C-g>"_c<C-r><C-p>+', "Replace selection with clipboard")

  -- 選択範囲を削除し、そのまま入力を続ける。
  map({ "s", "x" }, "<BS>", '<C-g>"_c', "Delete selection")
  map({ "s", "x" }, "<Del>", '<C-g>"_c', "Delete selection")
end

return M
