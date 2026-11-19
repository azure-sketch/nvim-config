local M = {}

-- grug-far の内部依存はここに閉じ込め、表示文字列で行を判定しない。
local function context(buf)
  local ok, instance = pcall(require("grug-far").get_instance, buf)
  local ctx = ok and instance and instance._context
  if ctx and ctx.extmarkIds.results_header then
    return ctx, instance
  end
end

local function cursor_row()
  return vim.api.nvim_win_get_cursor(0)[1] - 1
end

function M.can_resume_input(buf)
  local ctx = context(buf)
  return ctx ~= nil and cursor_row() < require("grug-far.inputs").getHeaderRow(ctx, buf)
end

function M.setup(buf)
  local function bind(modes, key, desc, action)
    vim.keymap.set(modes, key, action, { buffer = buf, silent = true, desc = desc })
  end

  local function input_action(method)
    return function()
      local _, instance = context(buf)
      if instance and M.can_resume_input(buf) then
        instance[method](instance)
      end
    end
  end
  bind({ "n", "i" }, "<Tab>", "Next search input", input_action("goto_next_input"))
  bind({ "n", "i" }, "<S-Tab>", "Previous search input", input_action("goto_prev_input"))

  bind({ "n", "i" }, "<C-Down>", "Focus first search result", function()
    local _, instance = context(buf)
    if instance and M.can_resume_input(buf) and instance:goto_next_match() then
      vim.cmd("stopinsert")
    end
  end)

  bind("n", "<C-Up>", "Return to search input from first result", function()
    local ctx, instance = context(buf)
    if not ctx or M.can_resume_input(buf) then
      return
    end

    -- extmark は行順で返る。ファイル見出しや無効になった結果は飛ばす。
    local marks = vim.api.nvim_buf_get_extmarks(buf, ctx.locationsNamespace, 0, -1, { details = true })
    for _, mark in ipairs(marks) do
      local location = ctx.state.resultLocationByExtmarkId[mark[1]]
      if location and location.lnum and location.count and not mark[4].invalid then
        if cursor_row() == mark[2] then
          local _, last_row = require("grug-far.inputs").getInputPos(ctx, buf, "search")
          if last_row then
            vim.api.nvim_win_set_cursor(0, { last_row, 0 })
            vim.cmd("startinsert!")
          end
        end
        return
      end
    end
  end)
end

return M
