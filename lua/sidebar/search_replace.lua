local M = {}

local function locations(buf, ctx)
  local rows = {}
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, ctx.locationsNamespace, 0, -1, { details = true })) do
    local loc = ctx.state.resultLocationByExtmarkId[mark[1]]
    if loc and loc.lnum and not mark[4].invalid then
      rows[#rows + 1] = { row = mark[2], loc = loc }
    end
  end
  return rows
end

local function apply(buf, instance)
  local ctx = instance._context
  local win = vim.api.nvim_get_current_win()
  local row = vim.api.nvim_win_get_cursor(win)[1] - 1
  local results = require("grug-far.render.resultsList")
  local current = results.getResultLocation(row, buf, ctx)
  if not current or not current.lnum then
    return
  end

  local first, last = row, row
  local order, count = {}, 0
  for _, item in ipairs(locations(buf, ctx)) do
    local loc = item.loc
    if not order[loc.filename] then
      count = count + 1
      order[loc.filename] = count
    end
    if loc.filename == current.filename and loc.lnum == current.lnum then
      first = math.min(first, item.row)
      last = math.max(last, item.row)
    end
  end

  local tasks = require("grug-far.tasks")
  local function refresh()
    if not instance:is_valid() or not instance:is_open() then
      return
    end
    require("grug-far.actions.search")({ buf = buf, context = ctx })
    local task = tasks.getTasksByType(ctx, "search")[1]
    if not task then
      return
    end

    local function restore()
      if not instance:is_valid() or task.isAborted or not vim.api.nvim_win_is_valid(win) then
        return
      end
      if vim.api.nvim_get_current_win() ~= win or vim.api.nvim_win_get_buf(win) ~= buf then
        return
      end
      if not task.isFinished then
        vim.defer_fn(restore, 30)
        return
      end
      if ctx.state.status == "error" or tasks.hasActiveTasksWithType(ctx, "search") then
        return
      end
      local target, fallback
      for _, item in ipairs(locations(buf, ctx)) do
        local loc = item.loc
        if loc.count then
          fallback = item.row
          if loc.filename == current.filename and loc.lnum > current.lnum
            or order[loc.filename] and order[loc.filename] > order[current.filename] then
            target = item.row
            break
          end
        end
      end
      target = target or fallback
      if target then
        vim.api.nvim_win_set_cursor(win, { target + 1, 0 })
      end
    end
    vim.defer_fn(restore, 30)
  end

  require("grug-far.utils").convertAnyScratchBufToRealBuf()
  require("grug-far.actions.sync")({
    buf = buf,
    context = ctx,
    startRow = first,
    endRow = last,
    shouldNotifyOnComplete = false,
    on_success = function()
      vim.schedule(refresh)
    end,
  })
end

function M.setup_buffer(buf)
  local key = "<localleader>j"
  local original = vim.api.nvim_buf_call(buf, function()
    return vim.fn.maparg(key, "n", false, true)
  end)
  if original.buffer ~= 1 then
    return
  end
  vim.keymap.set("n", key, function()
    local instance = require("grug-far").get_instance(buf)
    if instance:get_status_info().engineType == "ripgrep" then
      apply(buf, instance)
    else
      instance:apply_next_change()
    end
  end, { buffer = buf, silent = true, desc = original.desc })
end

return M
