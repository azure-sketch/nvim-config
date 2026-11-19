local M = {}

local toggles = {
  { key = "<M-c>", flag = "--ignore-case", desc = "Match Case", inverted = true },
  { key = "<M-w>", flag = "--word-regexp", desc = "Whole Word" },
  { key = "<M-r>", flag = "--fixed-strings", desc = "Regex", inverted = true },
}

local function ripgrep(buf)
  local ok, instance = pcall(require("grug-far").get_instance, buf)
  if ok and instance:get_status_info().engineType == "ripgrep" then
    return instance
  end
end

function M.setup_buffer(buf)
  for _, toggle in ipairs(toggles) do
    vim.keymap.set({ "n", "i" }, toggle.key, function()
      local instance = ripgrep(buf)
      if not instance then
        return
      end
      local active = instance:toggle_flags({ toggle.flag })[1]
      if toggle.inverted then
        active = not active
      end
      vim.notify(toggle.desc .. (active and ": on" or ": off"))
      vim.cmd("redrawstatus")
    end, { buffer = buf, silent = true, desc = toggle.desc })
  end
end

local function guide_keys()
  local buf = vim.api.nvim_get_current_buf()
  local input = require("sidebar.search_navigation").can_resume_input(buf)
  local keys = input and { "<Tab>", "<S-Tab>", "<C-Down>" } or { "<Up>", "<Down>", "<CR>", "<C-Up>" }
  if ripgrep(buf) then
    for _, toggle in ipairs(toggles) do
      keys[#keys + 1] = toggle.key
    end
  end
  keys[#keys + 1] = "<C-M-CR>"
  return keys
end

local key_labels = {
  ["<S-Tab>"] = "Shift+Tab", ["<C-Down>"] = "Ctrl+↓", ["<C-Up>"] = "Ctrl+↑",
  ["<Up>"] = "↑", ["<Down>"] = "↓", ["<CR>"] = "Enter", ["<C-M-CR>"] = "Ctrl+Alt+Enter",
}

local function entry(key, mode)
  local map = vim.fn.maparg(key, mode, false, true)
  if map.buffer ~= 1 or not map.desc then
    return
  end
  local label = key_labels[key] or key:gsub("^<M%-(%a)>$", function(letter)
    return "Alt+" .. letter:upper()
  end):gsub("[<>]", "")
  return label .. ": " .. map.desc
end

function M.wrap(statusline)
  local group = vim.api.nvim_create_augroup("SearchActionGuide", { clear = true })
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "ModeChanged", "BufEnter", "WinEnter", "VimResized" }, {
    group = group,
    callback = function()
      if vim.bo.filetype == "grug-far" then
        vim.cmd("redrawstatus")
      end
    end,
  })
  return {
    fallthrough = false,
    {
      condition = function()
        local mode = vim.fn.mode()
        return vim.bo.filetype == "grug-far" and (mode == "n" or mode == "i")
      end,
      provider = function()
        local mode = vim.fn.mode()
        local help = entry("<F1>", mode) or ""
        local separator = "  |  "
        local width = vim.o.columns - vim.fn.strdisplaywidth(help) - #separator
        local entries = {}
        for _, key in ipairs(guide_keys()) do
          local text = entry(key, mode)
          if text then
            local used = vim.fn.strdisplaywidth(text) + (#entries > 0 and #separator or 0)
            if used <= width then
              entries[#entries + 1] = text
              width = width - used
            end
          end
        end
        local function escape(text)
          return text:gsub("%%", "%%%%")
        end
        return escape(table.concat(entries, separator)) .. "%=" .. escape(help)
      end,
    },
    statusline,
  }
end

return M
