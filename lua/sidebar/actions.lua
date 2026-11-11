local M = {}

local sidebar = require("sidebar")
local bindings = require("bindings")

function M.setup(resume_input)
  local actions = {}

  -- キー操作以外で表示されたサイドバーも記憶する。
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    group = vim.api.nvim_create_augroup(
      "SidebarState",
      { clear = true }
    ),
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

  -- サイドバーから編集領域に戻る。
  bindings.apply("focus_editor", function()
    vim.cmd("stopinsert")
    require("edgy").goto_main()
    resume_input()
  end)

  return actions
end

return M
