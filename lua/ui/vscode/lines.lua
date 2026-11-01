local M = {}

local keymap = require("ui.vscode.keymap")

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

function M.attach(buf)
  local map = keymap.for_buffer(buf)

  -- 選択していないときのインデント解除。
  map("i", "<S-Tab>", "<C-d>", "Outdent current line")
  map("n", "<S-Tab>", "<<", "Outdent current line")

  -- Visualモードで選択されている場合。
  -- インデント後は再選択し、Selectモードへ戻す。
  map("x", "<Tab>", ">gv<C-g>", "Indent selected lines")
  map("x", "<S-Tab>", "<gv<C-g>", "Outdent selected lines")

  -- Shift+矢印などでSelectモードになっている場合。
  -- 内部でVisualへ切り替えてから行をインデントする。
  map("s", "<Tab>", "<C-g>>gv<C-g>", "Indent selected lines")
  map("s", "<S-Tab>", "<C-g><gv<C-g>", "Outdent selected lines")

  -- 現在行の下へ、新しい行を追加して入力。
  map("i", "<C-CR>", "<Esc>o", "Insert line below")
  map("n", "<C-CR>", "o", "Insert line below")

  -- 現在行の上へ、新しい行を追加して入力。
  map("i", "<C-S-CR>", "<Esc>O", "Insert line above")
  map("n", "<C-S-CR>", "O", "Insert line above")

  -- 現在行を上へ移動。
  map("i", "<A-Up>",
    "<C-o>:silent! move .-2<CR>",
    "Move line up")

  map("n", "<A-Up>",
    ":<C-u>silent! move .-2<CR>",
    "Move line up")

  -- 現在行を下へ移動。
  map("i", "<A-Down>",
    "<C-o>:silent! move .+1<CR>",
    "Move line down")

  map("n", "<A-Down>",
    ":<C-u>silent! move .+1<CR>",
    "Move line down")

  -- Visualモードの選択行を移動し、Selectモードで再選択。
  map("x", "<A-Up>",
    ":<C-u>silent! '<,'>move '<-2<CR>gv<C-g>",
    "Move selected lines up")

  map("x", "<A-Down>",
    ":<C-u>silent! '<,'>move '>+1<CR>gv<C-g>",
    "Move selected lines down")

  -- Shift+移動で選択した場合も、同じ操作にする。
  map("s", "<A-Up>",
    "<C-g>:<C-u>silent! '<,'>move '<-2<CR>gv<C-g>",
    "Move selected lines up")

  map("s", "<A-Down>",
    "<C-g>:<C-u>silent! '<,'>move '>+1<CR>gv<C-g>",
    "Move selected lines down")

  -- 現在行を削除。
  -- ブラックホールレジスタを使い、コピー内容を保持する。
  map("i", "<C-S-k>",
    '<C-o>"_dd',
    "Delete line")

  map("n", "<C-S-k>",
    '"_dd',
    "Delete line")

  -- 選択範囲がかかる行全体を削除。
  map("x", "<C-S-k>",
    '"_D',
    "Delete selected lines")

  map("s", "<C-S-k>",
    '<C-g>"_D',
    "Delete selected lines")

  -- 現在行を下へ複製する。
  map("i", "<A-S-Down>",
    "<C-o>:copy .<CR>",
    "Duplicate line down")

  map("n", "<A-S-Down>",
    ":<C-u>copy .<CR>",
    "Duplicate line down")

  -- 現在行を上へ複製する。
  map("i", "<A-S-Up>",
    "<C-o>:copy .-1<CR>",
    "Duplicate line up")

  map("n", "<A-S-Up>",
    ":<C-u>copy .-1<CR>",
    "Duplicate line up")

  map({ "s", "x" }, "<A-S-Up>",
    duplicate_selected_lines(-1),
    "Duplicate selected lines up")

  map({ "s", "x" }, "<A-S-Down>",
    duplicate_selected_lines(1),
    "Duplicate selected lines down")
end

return M
