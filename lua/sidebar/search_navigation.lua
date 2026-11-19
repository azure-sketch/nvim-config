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
    vim.keymap.set(modes, key, action, { buffer = buf, silent = true, nowait = true, desc = desc })
  end

  local function input_action(method)
    return function()
      local ctx, instance = context(buf)
      if not instance or not M.can_resume_input(buf) then
        return
      end
      local inputs = require("grug-far.inputs")
      -- 初期カーソルが上部の余白にいる場合も、先頭の入力欄を起点に移動する。
      if not inputs.getInputAtRow(ctx, buf, cursor_row()) then
        instance:goto_first_input()
      end
      instance[method](instance)
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

  local function result_action(method)
    return function()
      local _, instance = context(buf)
      if instance and not M.can_resume_input(buf) then
        instance[method](instance, { wrap = false, includeUncounted = false })
      end
    end
  end
  bind("n", "<Up>", "Previous search match", result_action("goto_prev_match"))
  bind("n", "<Down>", "Next search match", result_action("goto_next_match"))

  bind("n", "<C-Up>", "Return to search input", function()
    local ctx = context(buf)
    if not ctx or M.can_resume_input(buf) then
      return
    end
    local _, last_row = require("grug-far.inputs").getInputPos(ctx, buf, "search")
    if last_row then
      vim.api.nvim_win_set_cursor(0, { last_row, 0 })
      vim.cmd("startinsert!")
    end
  end)
end

return M
