local M = {}

local views = require("ui.sidebar.views")

local last_view = "files"

local function eligible(buf)
  if not vim.api.nvim_buf_is_valid(buf)
      or not vim.api.nvim_buf_is_loaded(buf)
  then
    return false
  end

  if views.name_of(buf) then
    return true
  end

  return vim.bo[buf].buftype == ""
      and vim.bo[buf].modifiable
      and not vim.api.nvim_buf_get_name(buf):match("^fugitive://")
end

local function focus_view(name)
  vim.cmd("stopinsert")
  last_view = name

  -- 既に表示されていれば、閉じずにフォーカスする。
  local win = views.find(name)

  if win then
    vim.api.nvim_set_current_win(win)
  else
    -- 非表示のときだけ、既存の排他切り替え処理で開く。
    require("ui.sidebar").toggle(name)
  end

  -- 検索画面は、そのまま文字入力できる状態にする。
  if name == "search" then
    local buf = vim.api.nvim_get_current_buf()

    if vim.bo[buf].filetype == "grug-far"
        and vim.bo[buf].modifiable
    then
      vim.cmd("startinsert")
    end
  end
end

local function focus_sidebar()
  local win, name = views.find()

  if win then
    focus_view(name)
  else
    focus_view(last_view)
  end
end

local function attach(buf)
  if not eligible(buf) then
    return
  end

  local function map(lhs, callback, desc)
    vim.keymap.set({ "n", "i", "s", "x" }, lhs, callback, {
      buffer = buf,
      silent = true,
      desc = desc,
    })
  end

  map("<C-S-e>", function()
    focus_view("files")
  end, "Focus files sidebar")

  map("<C-S-f>", function()
    focus_view("search")
  end, "Focus search sidebar")

  map("<C-S-g>", function()
    focus_view("git")
  end, "Focus Git sidebar")

  map("<C-0>", focus_sidebar, "Focus sidebar")
end

function M.setup()
  local group = vim.api.nvim_create_augroup(
    "VSCodeSidebarKeys",
    { clear = true }
  )

  vim.api.nvim_create_autocmd({
    "BufEnter",
    "WinEnter",
    "FileType",
    "InsertEnter",
  }, {
    group = group,
    callback = function(event)
      local buf = event.buf

      local name = views.name_of(buf)
      if name then
        last_view = name
      end

      vim.schedule(function()
        attach(buf)
      end)
    end,
  })

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    attach(buf)
  end
end

return M
