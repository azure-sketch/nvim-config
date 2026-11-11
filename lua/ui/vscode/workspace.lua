local M = {}

local keymap = require("ui.vscode.keymap")
local bindings = require("bindings")
local sidebar = require("ui.sidebar")

function M.setup(resume_input, group)
  local actions = {}
  local function toggle_view(name)
    return function()
      vim.cmd("stopinsert")
      sidebar.toggle(name)
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
      "Snacks Picker が見つかりません",
      vim.log.levels.WARN
    )
    resume_input()
  end

  bindings.apply("quick_open", actions.quick_open)

  -- キー操作以外で表示されたサイドバーも記憶する。
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = group,
    callback = function()
      sidebar.remember_visible()
    end,
  })

  -- 表示を切り替えた後、編集領域へ戻る。
  actions.toggle_sidebar = function()
    vim.cmd("stopinsert")

    sidebar.toggle_last()

    vim.schedule(function()
      require("edgy").goto_main()
      resume_input()
    end)
  end

  bindings.apply("toggle_sidebar", actions.toggle_sidebar)

  keymap.set(modes, "<C-S-p>", "<Esc>:", {
    desc = "Command line",
  })

  keymap.set(modes, "<F6>", toggle_view("files"), {
    desc = "Files sidebar",
  })

  keymap.set(modes, "<F7>", toggle_view("search"), {
    desc = "Search sidebar",
  })

  keymap.set(modes, "<F8>", toggle_view("git"), {
    desc = "Git sidebar",
  })

  -- サイドバーから編集領域に戻る。
  bindings.apply("focus_editor", function()
    vim.cmd("stopinsert")
    require("edgy").goto_main()
    resume_input()
  end)

  return actions
end

return M
