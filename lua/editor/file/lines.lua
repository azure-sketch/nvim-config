local M = {}

local function normal(keys)
  vim.cmd.normal({
    vim.api.nvim_replace_termcodes(
      keys, true, false, true
    ),
    bang = true,
  })
end

local function duplicate_selected_lines(direction)
  return function()
    local current_buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()

    local anchor = vim.fn.getpos("v")
    local cursor = vim.api.nvim_win_get_cursor(win)

    local first = math.min(anchor[2], cursor[1])
    local last = math.max(anchor[2], cursor[1])

    local lines = vim.api.nvim_buf_get_lines(
      current_buf, first - 1, last, false
    )

    -- 範囲を取得してから選択を解除する。
    normal("<Esc>")

    -- 上なら元の範囲の直前、下なら直後へ挿入する。
    local insert_at = direction < 0
        and (first - 1)
        or last

    vim.api.nvim_buf_set_lines(
      current_buf,
      insert_at,
      insert_at,
      false,
      lines
    )

    -- 複製した行を行単位で選択し直す。
    local new_first = insert_at + 1
    local new_last = insert_at + #lines

    vim.api.nvim_win_set_cursor(win, { new_first, 0 })
    normal("V")
    vim.api.nvim_win_set_cursor(win, { new_last, 0 })
    normal("<C-g>")
  end
end

-- キーの割り当ては editor/keymaps.lua にある。
M.duplicate_selected_up = duplicate_selected_lines(-1)
M.duplicate_selected_down = duplicate_selected_lines(1)

return M
