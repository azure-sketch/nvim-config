local M = {}

local keymap = require("editor.keymap")

-- ジャンプ履歴を移動し、編集可能なら入力へ戻る。
local function navigate_jump(key, resume_input)
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

local function go_to_line(resume_input)
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
end

-- 通常の編集ファイルだけに設定する。
function M.attach_file(buf, resume_input)
  local map = keymap.for_buffer(buf)

  map({ "n", "i" }, "<A-Left>", function()
    navigate_jump("<C-o>", resume_input)
  end, "Go back")

  map({ "n", "i" }, "<A-Right>", function()
    navigate_jump("<C-i>", resume_input)
  end, "Go forward")

  map({ "n", "i" }, "<C-g>", function()
    go_to_line(resume_input)
  end, "Go to line")
end

-- grug-farを含む、設定対象の編集領域に共通で設定する。
function M.attach(buf)
  local map = keymap.for_buffer(buf)

  map("i", "<C-Home>", "<C-o>gg<C-o>0", "Go to file start")
  map("i", "<C-End>", "<C-o>G<C-o>$<Right>", "Go to file end")
end

return M
