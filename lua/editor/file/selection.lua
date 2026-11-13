local M = {}

-- Selectモードの行選択なら下へ拡張し、
-- それ以外なら行選択へ変更する。
-- <expr>マッピングのrhsとして使う。
function M.expand_select_line()
  if vim.fn.mode() == "S" then
    return "<C-g>j<C-g>"
  end

  return "<C-g>V<C-g>"
end

-- Visualモードの行選択なら下へ拡張し、
-- それ以外なら行選択へ変更する。
-- <expr>マッピングのrhsとして使う。
function M.expand_visual_line()
  if vim.fn.mode() == "V" then
    return "j<C-g>"
  end

  return "V<C-g>"
end

return M
