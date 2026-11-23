-- TODOコメントの色分け・サイン表示・一覧(Snacks picker)。
-- VS Code「Better Todo Tree」の代替。
-- 色は色相だけ合わせた近似値。変更はここだけで行う。
local function icon(codepoint)
  return vim.fn.nr2char(codepoint) .. " "
end

return {
  "folke/todo-comments.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    signs = true, -- 左のサインカラムにアイコン
    merge_keywords = false, -- 既定のFIX/WARN/PERF/TESTは使わない

    keywords = {
      TODO = { icon = icon(0xf058), color = "todo" },
      FIXME = { icon = icon(0xf0238), color = "fixme" },
      NOTE = { icon = icon(0xf1fc), color = "note" },
      REVIEW = { icon = icon(0xf055), color = "review" },
      HACK = { icon = icon(0xf0e7), color = "hack" },
    },

    colors = {
      todo = { "#ffa500" }, -- オレンジ
      fixme = { "#ffff00" }, -- 黄
      note = { "#00bfff" }, -- 水色
      review = { "#008000" }, -- 緑
      hack = { "#800080" }, -- 紫
    },

    -- 背景は塗らず、キーワードとその後ろの文字色だけ変える。
    highlight = {
      before = "",
      keyword = "fg",
      after = "fg",
      -- 「TODO:」のようにコロン付きだけを対象にする(誤検出防止)。
      pattern = [[.*<(KEYWORDS)\s*:]],
    },
    gui_style = { fg = "BOLD" },

    -- 一覧(ripgrep)側の検索パターン。highlight.pattern と揃える。
    search = { pattern = [[\b(KEYWORDS):]] },
  },
}
