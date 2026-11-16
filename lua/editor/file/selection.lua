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

-- Select／Visualの選択を解除してから、指定した操作を実行する。
-- Normalへの遷移で予約される入力復帰より先に、操作を実行する。
function M.without_selection(action)
  return function()
    vim.cmd.normal({
      vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
      bang = true,
    })

    action()
  end
end

return M
