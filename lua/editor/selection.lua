local M = {}

local keymap = require("keymap")

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

-- 通常の編集ファイルだけに設定する。
-- 全選択・貼り付けなどの共通キーは editor/keymaps.lua にある。
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

return M
