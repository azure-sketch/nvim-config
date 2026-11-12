local M = {}

function M.open()
  local work_win = vim.api.nvim_get_current_win()
  local work_buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(work_buf)

  if vim.bo[work_buf].buftype ~= ""
      or path == ""
      or path:match("^fugitive://")
  then
    vim.notify(
      "競合中の作業ファイルを開いてから実行してください"
    )
    return
  end

  for _, win in ipairs(
    vim.api.nvim_tabpage_list_wins(0)
  ) do
    if vim.wo[win].diff then
      vim.notify(
        "既存の差分を閉じてから実行してください"
      )
      return
    end
  end

  local entries = vim.fn.system({
    "git",
    "-C",
    vim.fn.fnamemodify(path, ":h"),
    "ls-files",
    "--unmerged",
    "--",
    vim.fn.fnamemodify(path, ":t"),
  })

  if vim.v.shell_error ~= 0 then
    vim.notify(
      "Gitの競合状態を取得できませんでした",
      vim.log.levels.ERROR
    )
    return
  end

  if not entries:find(" 2\t", 1, true)
      or not entries:find(" 3\t", 1, true)
  then
    vim.notify(
      "ours・theirs両方が存在する競合ファイルが対象です"
    )
    return
  end

  vim.cmd("Gvdiffsplit!")

  local ours
  local theirs

  for _, win in ipairs(
    vim.api.nvim_tabpage_list_wins(0)
  ) do
    if vim.wo[win].diff then
      local buf = vim.api.nvim_win_get_buf(win)
      local name = vim.api.nvim_buf_get_name(buf)

      if name:match("^fugitive://.*//2/") then
        ours = win
      elseif name:match("^fugitive://.*//3/") then
        theirs = win
      end
    end
  end

  if not ours or not theirs then
    vim.notify(
      "比較元を識別できないため、標準配置を維持します",
      vim.log.levels.WARN
    )
    return
  end

  -- resultをoursの下へ移動する
  local moved = vim.fn.win_splitmove(
    work_win,
    ours,
    { vertical = false, rightbelow = true }
  )

  if moved ~= 0 then
    vim.notify(
      "resultの配置変更に失敗しました",
      vim.log.levels.ERROR
    )
    return
  end

  -- theirsをoursの右へ移動する
  moved = vim.fn.win_splitmove(
    theirs,
    ours,
    { vertical = true, rightbelow = true }
  )

  if moved ~= 0 then
    vim.notify(
      "theirsの配置変更に失敗しました",
      vim.log.levels.ERROR
    )
    return
  end

  -- 空間が許す場合、上段の幅をおおむね揃える
  local top_width =
      vim.api.nvim_win_get_width(ours)
      + vim.api.nvim_win_get_width(theirs)

  vim.api.nvim_win_set_width(
    ours,
    math.floor(top_width / 2)
  )

  vim.api.nvim_set_current_win(work_win)

  -- 下段に編集領域全体の約半分の高さを割り当てる
  local total_height =
      vim.api.nvim_win_get_height(work_win)
      + vim.api.nvim_win_get_height(ours)
      + 1

  vim.api.nvim_win_set_height(
    work_win,
    math.max(3, math.floor(total_height / 2))
  )
end

return M
