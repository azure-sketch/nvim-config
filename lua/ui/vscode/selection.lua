local M = {}

local keymap = require("ui.vscode.keymap")

-- Selectモードの行選択なら下へ拡張し、
-- それ以外なら行選択へ変更する。
local function expand_select_line()
  if vim.fn.mode() == "S" then
    return "<C-g>j<C-g>"
  end

  return "<C-g>V<C-g>"
end

-- Visualモードの行選択なら下へ拡張し、
-- それ以外なら行選択へ変更する。
local function expand_visual_line()
  if vim.fn.mode() == "V" then
    return "j<C-g>"
  end

  return "V<C-g>"
end

local function paste_in_insert()
  -- 行単位でコピーしたものは、現在行の上へ挿入する。
  if vim.fn.getregtype("+") == "V" then
    return '<C-o>"+P'
  end

  -- 文字単位なら、カーソル位置へ貼り付ける。
  return "<C-r><C-p>+"
end

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

  -- 選択状態に応じて、実行するキー列を返す。
  map("s", "<C-l>",
    expand_select_line,
    "Expand line selection",
    { expr = true })

  map("x", "<C-l>",
    expand_visual_line,
    "Expand line selection",
    { expr = true })

  -- 未選択なら現在行をOSクリップボードへコピーする。
  map("i", "<C-c>",
    '<C-o>"+yy',
    "Copy current line")

  map("n", "<C-c>",
    '"+yy',
    "Copy current line")

  -- 未選択なら現在行をOSクリップボードへ切り取る。
  map("i", "<C-x>",
    '<C-o>"+dd',
    "Cut current line")

  map("n", "<C-x>",
    '"+dd',
    "Cut current line")
end

-- grug-farを含む、設定対象の編集領域に共通で設定する。
function M.attach(buf)
  local map = keymap.for_buffer(buf)

  -- 全選択。最後にSelectモードへ移す。
  map({ "n", "i", "s", "x" }, "<C-a>",
    "<Esc>gg0vG$<C-g>",
    "Select all")

  -- 選択範囲のコピー・切り取り。
  map({ "s", "x" }, "<C-c>",
    '<C-g>"+y',
    "Copy selection")

  map({ "s", "x" }, "<C-x>",
    '<C-g>"+d',
    "Cut selection")

  -- OSクリップボードから貼り付ける。
  map("i", "<C-v>",
    paste_in_insert,
    "Paste",
    { expr = true })

  map("n", "<C-v>", '"+p', "Paste")

  -- 削除内容でクリップボードを上書きせず、
  -- 選択範囲をクリップボードの内容で置き換える。
  map({ "s", "x" }, "<C-v>",
    '<C-g>"_c<C-r><C-p>+',
    "Replace selection with clipboard")

  -- 選択範囲を削除し、そのまま入力を続ける。
  map({ "s", "x" }, "<BS>",
    '<C-g>"_c',
    "Delete selection")

  map({ "s", "x" }, "<Del>",
    '<C-g>"_c',
    "Delete selection")
end

return M
