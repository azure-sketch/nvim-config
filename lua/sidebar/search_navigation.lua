local M = {}

-- 入力欄の内部位置を参照しない。入力開始は明示的な操作で行う。
function M.can_resume_input()
  return false
end

local function with_instance(buf, action)
  local ok, instance = pcall(require("grug-far").get_instance, buf)
  if not ok or not instance or not instance:is_valid() then
    return
  end
  instance:when_ready(function()
    if instance:is_valid() and vim.api.nvim_get_current_buf() == buf then
      action(instance)
    end
  end)
end

function M.focus_input(buf)
  with_instance(buf, function(instance)
    instance:goto_input("search")
    vim.cmd("startinsert")
  end)
end

function M.setup(buf)
  local function bind(modes, key, desc, action)
    vim.keymap.set(modes, key, function()
      with_instance(buf, action)
    end, { buffer = buf, silent = true, nowait = true, desc = desc })
  end

  bind({ "n", "i" }, "<Tab>", "Next search input", function(instance)
    instance:goto_next_input()
    vim.cmd("startinsert")
  end)
  bind({ "n", "i" }, "<S-Tab>", "Previous search input", function(instance)
    instance:goto_prev_input()
    vim.cmd("startinsert")
  end)
  bind({ "n", "i" }, "<C-Down>", "Focus first search result", function(instance)
    instance:goto_first_input()
    if instance:goto_next_match({ wrap = false, includeUncounted = false }) then
      vim.cmd("stopinsert")
    end
  end)
  bind("n", "<Up>", "Previous search match", function(instance)
    instance:goto_prev_match({ wrap = false, includeUncounted = false })
  end)
  bind("n", "<Down>", "Next search match", function(instance)
    instance:goto_next_match({ wrap = false, includeUncounted = false })
  end)
  bind({ "n", "i" }, "<C-Up>", "Return to search input", function(instance)
    instance:goto_input("search")
    vim.cmd("startinsert")
  end)

  local function target_action(method, options)
    return function(instance)
      if require("sidebar.search_target").prepare() then
        instance[method](instance, options)
      end
    end
  end
  bind("n", "<CR>", "Go to search location", target_action("goto_location"))
  bind("n", "<localleader>o", "Open search location", target_action("open_location"))
  bind("n", "<localleader>j", "Apply next search change", target_action("apply_next_change"))
  bind("n", "<localleader>k", "Apply previous search change", target_action("apply_prev_change"))
end

return M
