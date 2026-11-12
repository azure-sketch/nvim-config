local M = {}

local session
local pending = false

local function valid_win(win)
  return vim.api.nvim_win_is_valid(win)
end

local function has_buffer(win, buf)
  return valid_win(win)
      and vim.api.nvim_win_get_buf(win) == buf
end

local function diffoff(win)
  if valid_win(win) then
    vim.api.nvim_win_call(win, function()
      vim.cmd("diffoff")
    end)
  end
end

local function finish()
  local s = session

  if not s then
    return
  end

  for _, comparison in ipairs(s.comparisons) do
    if has_buffer(comparison.win, comparison.buf)
        and vim.bo[comparison.buf].modified
    then
      session = nil
      vim.notify(
        "比較元に未保存の変更があるため、自動では閉じません",
        vim.log.levels.WARN
      )
      return
    end
  end

  session = nil
  diffoff(s.work_win)

  for _, comparison in ipairs(s.comparisons) do
    if has_buffer(comparison.win, comparison.buf) then
      diffoff(comparison.win)
      vim.api.nvim_win_close(comparison.win, false)
    end
  end

  vim.cmd("redrawtabline")
end

local function detect()
  local work
  local work_count = 0
  local comparisons = {}
  local diff_count = 0

  for _, win in ipairs(
    vim.api.nvim_tabpage_list_wins(0)
  ) do
    if vim.wo[win].diff then
      diff_count = diff_count + 1

      local buf = vim.api.nvim_win_get_buf(win)
      local name = vim.api.nvim_buf_get_name(buf)

      if name:match("^fugitive://") then
        table.insert(comparisons, {
          win = win,
          buf = buf,
        })
      elseif vim.bo[buf].buftype == "" then
        work_count = work_count + 1
        work = { win = win, buf = buf }
      end
    end
  end

  if work_count == 1
      and #comparisons >= 1
      and #comparisons <= 2
      and diff_count == #comparisons + 1
  then
    session = {
      tab = vim.api.nvim_get_current_tabpage(),
      work_win = work.win,
      work_buf = work.buf,
      comparisons = comparisons,
    }
  end
end

local function check()
  if not session then
    detect()
    return
  end

  if not vim.api.nvim_tabpage_is_valid(session.tab) then
    session = nil
    return
  end

  if session.tab ~= vim.api.nvim_get_current_tabpage() then
    return
  end

  local work_present =
      has_buffer(session.work_win, session.work_buf)

  local work_listed =
      vim.api.nvim_buf_is_valid(session.work_buf)
      and vim.bo[session.work_buf].buflisted

  if not work_present or not work_listed then
    finish()
    return
  end

  for _, comparison in ipairs(session.comparisons) do
    if not has_buffer(comparison.win, comparison.buf) then
      finish()
      return
    end
  end

  -- 2-wayから3-wayへ増えた場合も追跡対象を更新する
  detect()
end

-- 現在の作業ウィンドウを残して、手動で差分表示を終了する。
-- 自動片付けのfinish()とは対象の決め方が異なる。
function M.close()
  local current = vim.api.nvim_get_current_win()

  if not vim.wo[current].diff then
    vim.notify("差分表示中の作業ファイルで実行してください")
    return
  end

  local buf = vim.api.nvim_win_get_buf(current)
  local name = vim.api.nvim_buf_get_name(buf)

  if vim.bo[buf].buftype ~= ""
      or name:match("^fugitive://")
  then
    vim.notify("右側の作業ファイルへ移動して実行してください")
    return
  end

  local targets = {}

  -- 閉じ始める前に、すべての対象を確認する。
  -- 比較側に未保存変更があれば、何も閉じずに中止する。
  for _, win in ipairs(
    vim.api.nvim_tabpage_list_wins(0)
  ) do
    if win ~= current and vim.wo[win].diff then
      local other = vim.api.nvim_win_get_buf(win)

      if vim.bo[other].modified then
        vim.notify(
          "比較側に未保存の変更があります。保存・確認してから閉じてください",
          vim.log.levels.WARN
        )
        return
      end

      table.insert(targets, win)
    end
  end

  for _, win in ipairs(targets) do
    vim.api.nvim_win_close(win, false)
  end

  vim.api.nvim_set_current_win(current)
  vim.cmd("diffoff")
end

function M.setup()
  local group = vim.api.nvim_create_augroup(
    "SidebarGitDiffSession",
    { clear = true }
  )

  local function queue_check()
    if pending then
      return
    end

    pending = true

    vim.schedule(function()
      pending = false
      check()
    end)
  end

  vim.api.nvim_create_autocmd({
    "BufEnter",
    "BufWinEnter",
    "BufDelete",
    "BufWipeout",
    "WinClosed",
    "TabEnter",
  }, {
    group = group,
    callback = queue_check,
  })

  vim.api.nvim_create_autocmd("OptionSet", {
    group = group,
    pattern = "diff",
    callback = queue_check,
  })
end

return M
