-- editorのキー定義を、影響範囲ごとに一覧で管理する。
-- 動作の実装は area/ と file/ に置き、ここでは「どのキーで何を呼ぶか」だけを書く。
--
-- 影響範囲:
--   area: 通常ファイルとgrug-farの両方
--   file: 通常ファイルのみ
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

-- 通常ファイルだけで使うキー。
local function file_entries(resume_input)
  local lines = require("editor.file.lines")
  local lsp = require("editor.file.lsp")
  local navigation = require("editor.file.navigation")
  local buffers = require("editor.file.buffers")
  local problems = require("editor.file.problems")
  local format = require("editor.file.format")
  local replace = require("editor.file.replace")
  local selection = require("editor.file.selection")

  local entries = {}

  -- 行の編集
  vim.list_extend(entries, {
    -- 選択していないときのインデント解除。
    { "i", "<S-Tab>", "<C-d>", "Outdent current line" },
    { "n", "<S-Tab>", "<<", "Outdent current line" },

    -- Visualモードで選択されている場合。
    -- インデント後は再選択し、Selectモードへ戻す。
    { "x", "<Tab>", ">gv<C-g>", "Indent selected lines" },
    { "x", "<S-Tab>", "<gv<C-g>", "Outdent selected lines" },

    -- Shift+矢印などでSelectモードになっている場合。
    -- 内部でVisualへ切り替えてから行をインデントする。
    { "s", "<Tab>", "<C-g>>gv<C-g>", "Indent selected lines" },
    { "s", "<S-Tab>", "<C-g><gv<C-g>", "Outdent selected lines" },

    -- 現在行の下・上へ、新しい行を追加して入力。
    { "i", "<C-CR>", "<Esc>o", "Insert line below" },
    { "n", "<C-CR>", "o", "Insert line below" },
    { "i", "<C-S-CR>", "<Esc>O", "Insert line above" },
    { "n", "<C-S-CR>", "O", "Insert line above" },

    -- 現在行を上下へ移動。
    { "i", "<A-Up>", "<C-o>:silent! move .-2<CR>", "Move line up" },
    { "n", "<A-Up>", ":<C-u>silent! move .-2<CR>", "Move line up" },
    { "i", "<A-Down>", "<C-o>:silent! move .+1<CR>", "Move line down" },
    { "n", "<A-Down>", ":<C-u>silent! move .+1<CR>", "Move line down" },

    -- Visualモードの選択行を移動し、Selectモードで再選択。
    { "x", "<A-Up>", ":<C-u>silent! '<,'>move '<-2<CR>gv<C-g>",
      "Move selected lines up" },
    { "x", "<A-Down>", ":<C-u>silent! '<,'>move '>+1<CR>gv<C-g>",
      "Move selected lines down" },

    -- Shift+移動で選択した場合も、同じ操作にする。
    { "s", "<A-Up>", "<C-g>:<C-u>silent! '<,'>move '<-2<CR>gv<C-g>",
      "Move selected lines up" },
    { "s", "<A-Down>", "<C-g>:<C-u>silent! '<,'>move '>+1<CR>gv<C-g>",
      "Move selected lines down" },

    -- 現在行を削除。
    -- ブラックホールレジスタを使い、コピー内容を保持する。
    { "i", "<C-S-k>", '<C-o>"_dd', "Delete line" },
    { "n", "<C-S-k>", '"_dd', "Delete line" },

    -- 選択範囲がかかる行全体を削除。
    { "x", "<C-S-k>", '"_D', "Delete selected lines" },
    { "s", "<C-S-k>", '<C-g>"_D', "Delete selected lines" },

    -- 現在行を上下へ複製する。
    { "i", "<A-S-Down>", "<C-o>:copy .<CR>", "Duplicate line down" },
    { "n", "<A-S-Down>", ":<C-u>copy .<CR>", "Duplicate line down" },
    { "i", "<A-S-Up>", "<C-o>:copy .-1<CR>", "Duplicate line up" },
    { "n", "<A-S-Up>", ":<C-u>copy .-1<CR>", "Duplicate line up" },
    { { "s", "x" }, "<A-S-Up>", lines.duplicate_selected_up,
      "Duplicate selected lines up" },
    { { "s", "x" }, "<A-S-Down>", lines.duplicate_selected_down,
      "Duplicate selected lines down" },
  })

  -- 言語サーバー
  vim.list_extend(entries, {
    { { "n", "i" }, "<C-.>", lsp.code_action, "Show code actions" },
    { { "n", "i" }, "<C-k>", lsp.hover_prefix, "VS Code-style Ctrl+K prefix" },
    { { "n", "i" }, "<F12>", lsp.definition, "Go to definition" },
    { { "n", "i" }, "<F24>", lsp.references, "Find references" },
    { { "n", "i" }, "<F2>", lsp.rename, "Rename symbol" },
    { { "n", "i" }, "<C-S-o>", lsp.document_symbols(resume_input),
      "Go to symbol in file" },
    { { "n", "i" }, "<C-t>", lsp.workspace_symbols(resume_input),
      "Go to symbol in workspace" },
  })

  -- 移動
  vim.list_extend(entries, {
    { { "n", "i" }, "<A-Left>", function()
      navigation.back(resume_input)
    end, "Go back" },
    { { "n", "i" }, "<A-Right>", function()
      navigation.forward(resume_input)
    end, "Go forward" },
    { { "n", "i" }, "<C-g>", function()
      navigation.go_to_line(resume_input)
    end, "Go to line" },
  })

  -- エディタ（バッファ）の切り替え
  vim.list_extend(entries, {
    { { "n", "i" }, "<C-PageUp>", function()
      buffers.switch(-1, resume_input)
    end, "Previous editor" },
    { { "n", "i" }, "<C-PageDown>", function()
      buffers.switch(1, resume_input)
    end, "Next editor" },
    { { "n", "i" }, "<C-n>", function()
      buffers.new_file(resume_input)
    end, "New file" },
  })

  -- 行コメントの切り替え。
  -- Neovimのgc / gccマッピングへ委譲するため、remapを有効にする。
  -- Ctrl+_は、端末がCtrl+/の代わりに送る場合の別名。
  local comment_mappings = {
    { mode = "i", rhs = "<C-o>gcc" },
    { mode = "n", rhs = "gcc" },
    { mode = "x", rhs = "gcgv<C-g>" },
    { mode = "s", rhs = "<C-g>gcgv<C-g>" },
  }

  for _, lhs in ipairs({ "<C-/>", "<C-_>" }) do
    for _, mapping in ipairs(comment_mappings) do
      entries[#entries + 1] = {
        mapping.mode,
        lhs,
        mapping.rhs,
        "Toggle line comment",
        { remap = true },
      }
    end
  end

  -- 問題一覧・整形・置換
  vim.list_extend(entries, {
    { { "n", "i" }, "<C-S-m>", function()
      problems.show(resume_input)
    end, "Show problems" },
    { { "n", "i" }, "<A-S-f>", function()
      format.document(resume_input)
    end, "Format document" },
    { { "n", "i" }, "<C-h>", function()
      replace.open(resume_input)
    end, "Replace in current file" },
  })

  -- 行の選択・コピー・切り取り
  vim.list_extend(entries, {
    -- 入力中・通常状態から、現在行全体を選択する。
    { "i", "<C-l>", "<Esc>V<C-g>", "Select current line" },
    { "n", "<C-l>", "V<C-g>", "Select current line" },

    -- 選択状態に応じて、実行するキー列を返す。
    { "s", "<C-l>", selection.expand_select_line,
      "Expand line selection", { expr = true } },
    { "x", "<C-l>", selection.expand_visual_line,
      "Expand line selection", { expr = true } },

    -- 未選択なら現在行をOSクリップボードへコピー・切り取りする。
    { "i", "<C-c>", '<C-o>"+yy', "Copy current line" },
    { "n", "<C-c>", '"+yy', "Copy current line" },
    { "i", "<C-x>", '<C-o>"+dd', "Cut current line" },
    { "n", "<C-x>", '"+dd', "Cut current line" },
  })

  return entries
end

function M.apply_file(buf, resume_input)
  apply(buf, file_entries(resume_input))
end

function M.apply_area(buf, resume_input)
  apply(buf, area_entries(resume_input))
end

return M
