local layout = require("layout")
local bindings = require("bindings")
local term = require("terminal")

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
              term.resume_editor()
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
      term.toggle,
      mode = { "n", "i", "s", "x", "t" },
      desc = "Toggle integrated terminal",
    },
  },
}
