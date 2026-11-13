-- editorのキー定義を、影響範囲ごとに一覧で管理する。
-- 動作の実装は area/ と file/ に置き、ここでは「どのキーで何を呼ぶか」だけを書く。
--
-- 各項目: { モード, lhs, rhs, 説明, 追加オプション }
local M = {}

local keymap = require("keymap")

local function apply(buf, entries)
  local map = keymap.for_buffer(buf)

  for _, entry in ipairs(entries) do
    map(entry[1], entry[2], entry[3], entry[4], entry[5])
  end
end

-- 通常ファイルとgrug-farの両方で使うキー。
local function area_entries(resume_input)
  local save = require("editor.area.save")
  local clipboard = require("editor.area.clipboard")
  local find = require("editor.area.find")
  local buffers = require("editor.area.buffers")

  return {
    -- 保存
    { { "n", "i", "s", "x" }, "<C-s>", function()
      save.write(resume_input)
    end, "Save file" },
    { { "n", "i" }, "<C-S-s>", function()
      save.save_as(resume_input)
    end, "Save file as" },

    -- 元に戻す・やり直し
    { "i", "<C-z>", "<C-o>u", "Undo" },
    { "i", "<C-y>", "<C-o><C-r>", "Redo" },
    { "n", "<C-z>", "u", "Undo" },
    { "n", "<C-y>", "<C-r>", "Redo" },
    { { "s", "x" }, "<C-z>", "<Esc>u", "Undo" },
    { { "s", "x" }, "<C-y>", "<Esc><C-r>", "Redo" },

    -- 全選択。最後にSelectモードへ移す。
    { { "n", "i", "s", "x" }, "<C-a>", "<Esc>gg0vG$<C-g>", "Select all" },

    -- 選択範囲のコピー・切り取り。
    { { "s", "x" }, "<C-c>", '<C-g>"+y', "Copy selection" },
    { { "s", "x" }, "<C-x>", '<C-g>"+d', "Cut selection" },

    -- OSクリップボードから貼り付ける。
    { "i", "<C-v>", clipboard.paste_in_insert, "Paste", { expr = true } },
    { "n", "<C-v>", '"+p', "Paste" },

    -- 削除内容でクリップボードを上書きせず、
    -- 選択範囲をクリップボードの内容で置き換える。
    { { "s", "x" }, "<C-v>", '<C-g>"_c<C-r><C-p>+',
      "Replace selection with clipboard" },

    -- 選択範囲を削除し、そのまま入力を続ける。
    { { "s", "x" }, "<BS>", '<C-g>"_c', "Delete selection" },
    { { "s", "x" }, "<Del>", '<C-g>"_c', "Delete selection" },

    -- ファイルの先頭・末尾へ移動。
    { "i", "<C-Home>", "<C-o>gg<C-o>0", "Go to file start" },
    { "i", "<C-End>", "<C-o>G<C-o>$<Right>", "Go to file end" },

    -- 検索語を入力してEnterで確定する。
    { "i", "<C-f>", "<Esc>/", "Find in file" },
    { "n", "<C-f>", "/", "Find in file" },
    { { "n", "i" }, "<F3>", find.next_match, "Next match" },
    { { "n", "i" }, "<S-F3>", find.prev_match, "Previous match" },

    -- 強制破棄は行わず、既存の終了処理へ委譲する。
    { { "n", "i" }, "<C-w>", buffers.close, "Close editor" },
  }
end

function M.apply_area(buf, resume_input)
  apply(buf, area_entries(resume_input))
end

return M
