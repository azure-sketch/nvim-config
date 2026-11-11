local layout = require("ui.layout")
local bindings = require("ui.vscode.workspace_bindings")

local terminal
local terminal_cwd

local function resume_editor()
  vim.schedule(function()
    local buf = vim.api.nvim_get_current_buf()

    if vim.bo[buf].buftype == ""
        and vim.bo[buf].modifiable
        and not vim.api.nvim_buf_get_name(buf):match("^fugitive://")
    then
      vim.cmd("startinsert")
    end
  end)
end

local function toggle_terminal()
  -- 最初に開いたディレクトリを維持する。
  -- 編集対象が変わっても、毎回別のシェルを作らない。
  terminal_cwd = terminal_cwd or vim.fn.getcwd()

  local exists = terminal
      and terminal.buf
      and vim.api.nvim_buf_is_valid(terminal.buf)

  local was_visible = exists
      and terminal.win
      and vim.api.nvim_win_is_valid(terminal.win)

  if exists then
    terminal:toggle()
  else
    terminal = require("snacks.terminal").toggle(nil, {
      cwd = terminal_cwd,
      win = {
        position = "bottom",
        height = layout.terminal.height,
      },
    })
  end

  if was_visible then
    resume_editor()
  end
end

return {
  "folke/snacks.nvim",

  opts = {
    styles = {
      input = {
        keys = {
          i_esc = { "<Esc>", "cancel", mode = "i", expr = false },
          n_esc = { "<Esc>", "cancel", mode = "n", expr = false },
        },
      },
    },

    picker = {
      win = {
        input = {
          keys = {
            ["<Esc>"] = { "close", mode = { "n", "i" } },
            ["<Down>"] = { "list_down", mode = { "n", "i" } },
            ["<Up>"] = { "list_up", mode = { "n", "i" } },
            ["<CR>"] = { "confirm", mode = { "n", "i" } },
          },
        },

        list = {
          keys = {
            ["<Esc>"] = { "close", mode = { "n", "i" } },
          },
        },
      },
    },

    terminal = {
      enabled = true,

      win = {
        position = "bottom",
        height = layout.terminal.height,

        keys = {
          editor = {
            bindings.lhs("focus_editor"),
            function()
              require("edgy").goto_main()
              resume_editor()
            end,
            mode = { "n", "t" },
            desc = bindings.desc("focus_editor"),
          },
        },
      },
    },
  },

  keys = {
    {
      "<C-@>",
      toggle_terminal,
      mode = { "n", "i", "s", "x", "t" },
      desc = "Toggle integrated terminal",
    },
  },
}
