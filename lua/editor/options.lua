local M = {}

function M.setup()
  -- Shift+移動で選択を開始・解除する。
  vim.opt.keymodel = { "startsel", "stopsel" }

  -- キーやマウスによる選択をSelectモードにする。
  -- 選択後の文字入力は、選択範囲の置き換えになる。
  vim.opt.selectmode = { "mouse", "key" }
  vim.opt.selection = "exclusive"

  vim.opt.mouse = "a"
end

return M
