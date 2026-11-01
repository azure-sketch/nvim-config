local M = {}

local keymap = require("ui.vscode.keymap")
local bindings = require("ui.vscode.workspace_bindings")
local views = require("ui.sidebar.views")

function M.setup(resume_input, group)
  local actions = {}
  local function sidebar(name)
    return function()
      vim.cmd("stopinsert")
      require("ui.sidebar").toggle(name)
    end
  end

  -- Ctrl+Shift系は端末による区別の問題があるため、
  -- まず確実に切り分けやすいFキーを入口にする。
  local modes = { "n", "i", "s", "x" }

  actions.quick_open = function()
    vim.cmd("stopinsert")

    local ok, picker = pcall(require, "snacks.picker")
    if ok then
      picker.files()
      return
    end

    vim.notify(
      "Snacks Picker / Telescope が見つかりません",
      vim.log.levels.WARN
    )
    resume_input()
  end

  bindings.apply("quick_open", actions.quick_open)

  -- 現在表示されているサイドバーの種類を返す。
  local function visible_sidebar()
    local _, name = views.find()
    return name
  end

  local last_sidebar = "files"

  -- F6/F7/F8で開いた種類も記憶する。
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = group,
    callback = function()
      local name = visible_sidebar()
      if name then
        last_sidebar = name
      end
    end,
  })

  -- Ctrl+B: 表示中なら閉じる。
  -- 閉じている場合は、最後の種類を開いて編集領域へ戻る。
  actions.toggle_sidebar = function()
    vim.cmd("stopinsert")

    local current = visible_sidebar()

    if current then
      last_sidebar = current
    end

    require("ui.sidebar").toggle(current or last_sidebar)

    vim.schedule(function()
      require("edgy").goto_main()
      resume_input()
    end)
  end

  bindings.apply("toggle_sidebar", actions.toggle_sidebar)

  keymap.set(modes, "<C-S-p>", "<Esc>:", {
    desc = "Command line",
  })

  keymap.set(modes, "<F6>", sidebar("files"), {
    desc = "Files sidebar",
  })

  keymap.set(modes, "<F7>", sidebar("search"), {
    desc = "Search sidebar",
  })

  keymap.set(modes, "<F8>", sidebar("git"), {
    desc = "Git sidebar",
  })

  -- サイドバーから編集領域に戻る。
  keymap.set(modes, "<C-1>", function()
    vim.cmd("stopinsert")
    require("edgy").goto_main()
    resume_input()
  end, {
    desc = "Focus editor",
  })
  return actions
end

return M
