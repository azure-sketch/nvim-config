local M = {}

local keymap = require("ui.vscode.keymap")

function M.attach(buf, resume_input)
  local map = keymap.for_buffer(buf)

  -- ジャンプ履歴を移動し、編集可能なら入力へ戻る。
  local function navigate_jump(key)
    return function()
      vim.cmd("stopinsert")

      local command = vim.api.nvim_replace_termcodes(
        key, true, false, true
      )

      vim.cmd.normal({
        command,
        bang = true,
      })

      resume_input()
    end
  end

  map({ "n", "i" }, "<A-Left>",
    navigate_jump("<C-o>"),
    "Go back")

  map({ "n", "i" }, "<A-Right>",
    navigate_jump("<C-i>"),
    "Go forward")

  local function switch_buffer(direction)
    return function()
      vim.cmd("stopinsert")

      local ok, err = pcall(function()
        require("astrocore.buffer").nav(direction)
      end)

      if not ok then
        vim.notify(tostring(err), vim.log.levels.WARN)
      end

      resume_input()
    end
  end

  map({ "n", "i" }, "<C-PageUp>",
    switch_buffer(-1),
    "Previous editor")

  map({ "n", "i" }, "<C-PageDown>",
    switch_buffer(1),
    "Next editor")

  map({ "n", "i" }, "<C-n>", function()
    vim.cmd("stopinsert")

    -- 既存ファイルの未保存変更を残したまま、
    -- 新しい編集バッファを作る。
    local new_buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_set_current_buf(new_buf)

    resume_input()
  end, "New file")

  map({ "n", "i" }, "<C-g>", function()
    -- 入力欄ではなく、元の編集ウィンドウを移動対象にする。
    local target_win = vim.api.nvim_get_current_win()
    local target_buf = vim.api.nvim_get_current_buf()
    local current_line = vim.api.nvim_win_get_cursor(
      target_win
    )[1]

    vim.ui.input({
      prompt = "移動先の行番号: ",
      default = tostring(current_line),
    }, function(value)
      if not value or value == "" then
        resume_input()
        return
      end

      if not vim.api.nvim_win_is_valid(target_win)
          or not vim.api.nvim_buf_is_valid(target_buf)
          or vim.api.nvim_win_get_buf(target_win) ~= target_buf
      then
        resume_input()
        return
      end

      -- 正の整数だけを受け付ける。
      local digits = value:match("^%s*(%d+)%s*$")
      local line = digits and tonumber(digits)

      if not line or line < 1 or line == math.huge then
        vim.notify(
          "1以上の行番号を入力してください",
          vim.log.levels.INFO
        )
        resume_input()
        return
      end

      local count = vim.api.nvim_buf_line_count(target_buf)
      line = math.min(line, count)

      vim.api.nvim_set_current_win(target_win)
      vim.api.nvim_win_set_cursor(target_win, { line, 0 })

      -- 移動先を画面中央付近へ表示する。
      vim.cmd("normal! zz")

      resume_input()
    end)
  end, "Go to line")
end

-- grug-farを含む、設定対象の編集領域に共通で設定する。
function M.attach_common(buf)
  local map = keymap.for_buffer(buf)

  map("i", "<C-Home>", "<C-o>gg<C-o>0", "Go to file start")
  map("i", "<C-End>", "<C-o>G<C-o>$<Right>", "Go to file end")
end

return M
