local M = {}

local keymap = require("ui.vscode.keymap")


-- 通常の編集ファイルだけに設定する。
function M.attach_file(buf, resume_input)
  local map = keymap.for_buffer(buf)

  -- コメント操作は、Neovimのgc / gccマッピングへ委譲する。
  -- 既存のmap()はnoremapなので、ここだけremapを有効にする。
  local function comment_map(mode, lhs, rhs)
    keymap.set(mode, lhs, rhs, {
      buffer = buf,
      silent = true,
      remap = true,
      desc = "Toggle line comment",
    })
  end

  -- 端末によってCtrl+/がCtrl+_として届く場合にも対応する。
  for _, key in ipairs({ "<C-/>", "<C-_>" }) do
    comment_map("i", key, "<C-o>gcc")
    comment_map("n", key, "gcc")

    -- コメント切り替え後、対象範囲を再選択する。
    comment_map("x", key, "gcgv<C-g>")
    comment_map("s", key, "<C-g>gcgv<C-g>")
  end

  map({ "n", "i" }, "<C-S-m>", function()
    vim.cmd("stopinsert")

    local ok, picker = pcall(require, "snacks.picker")

    if not ok then
      vim.notify(
        "Snacks Pickerが見つかりません",
        vim.log.levels.WARN
      )
      resume_input()
      return
    end

    picker.diagnostics()
  end, "Show problems")

  map({ "n", "i" }, "<A-S-f>", function()
    vim.cmd("stopinsert")

    if vim.fn.exists(":Format") ~= 2 then
      vim.notify(
        "AstroNvimのFormatコマンドが利用できません",
        vim.log.levels.WARN
      )
      resume_input()
      return
    end

    local ok, err = pcall(vim.cmd, "Format")

    if not ok then
      vim.notify(tostring(err), vim.log.levels.WARN)
    end

    resume_input()
  end, "Format document")

  map({ "n", "i" }, "<C-h>", function()
    require("ui.vscode_replace").open(resume_input)
  end, "Replace in current file")
end

-- 設定対象の編集領域に共通で設定する。
function M.attach(buf)
  local map = keymap.for_buffer(buf)

  -- ファイル先頭・末尾。
  map("i", "<C-Home>", "<C-o>gg<C-o>0", "Go to file start")
  map("i", "<C-End>", "<C-o>G<C-o>$<Right>", "Go to file end")

  -- ファイル内検索。検索語を入力してEnterで確定。
  map("i", "<C-f>", "<Esc>/", "Find in file")
  map("n", "<C-f>", "/", "Find in file")

  map({ "n", "i" }, "<F3>", function()
    local ok, err = pcall(vim.cmd, "normal! n")
    if not ok then
      vim.notify(tostring(err), vim.log.levels.INFO)
    end
  end, "Next match")

  map({ "n", "i" }, "<S-F3>", function()
    local ok, err = pcall(vim.cmd, "normal! N")
    if not ok then
      vim.notify(tostring(err), vim.log.levels.INFO)
    end
  end, "Previous match")

  -- 現在の編集バッファを閉じる。
  -- 強制終了しないため、未保存の変更は保護される。
  map({ "n", "i" }, "<C-w>", function()
    local ok, err = pcall(function()
      require("astrocore.buffer").close()
    end)

    if not ok then
      vim.notify(tostring(err), vim.log.levels.WARN)
    end
  end, "Close editor")
end

return M
