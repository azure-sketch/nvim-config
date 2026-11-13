local M = {}

-- Insertモードの貼り付け。<expr>マッピングのrhsとして使う。
function M.paste_in_insert()
  -- 行単位でコピーしたものは、現在行の上へ挿入する。
  if vim.fn.getregtype("+") == "V" then
    return '<C-o>"+P'
  end

  -- 文字単位なら、カーソル位置へ貼り付ける。
  return "<C-r><C-p>+"
end

return M
