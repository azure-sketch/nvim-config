-- 行番号やインデントなどの一般設定は plugins/astrocore.lua に置く。
-- ここには、選択・入力動作に関係する設定だけを置く。
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
