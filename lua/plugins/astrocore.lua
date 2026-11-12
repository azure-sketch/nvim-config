---@type LazySpec
return {
  "AstroNvim/astrocore",

  ---@type AstroCoreOpts
  opts = {
    features = {
      large_buf = { size = 1024 * 256, lines = 10000 },
      autopairs = true,
      cmp = true,
      diagnostics = { virtual_text = true, virtual_lines = false },
      highlighturl = true,
      notifications = true,
    },

    diagnostics = {
      virtual_text = true,
      underline = true,
    },

    options = {
      opt = {
        number = true,
        relativenumber = false,
        signcolumn = "yes",
        spell = false,

        tabstop = 2,
        shiftwidth = 2,
        softtabstop = 2,
        expandtab = true,

        wrap = true,
        linebreak = true,
        breakindent = true,
        breakindentopt = "shift:2",

        list = true,
        listchars = { tab = "→ ", space = "·", trail = "·", nbsp = "␣" },

        cursorline = true,

        fileformat = "unix",
        fileformats = { "unix", "dos" },
        fileencodings = { "ucs-bom", "utf-8", "cp932", "euc-jp", "default" },
        fixeol = true,
        foldcolumn = "1",
      },

      g = {},
    },

    autocmds = {
      auto_save_on_focus_lost = {
        {
          event = { "FocusLost", "BufLeave" },
          desc = "Save the current modified file buffer",
          nested = true, -- 保存時の BufWritePre(トリム)を発火させる
          callback = function(event)
            local buf = event.buf
            if vim.bo[buf].buftype == ""
                and vim.bo[buf].modifiable
                and vim.bo[buf].modified
                and vim.api.nvim_buf_get_name(buf) ~= ""
            then
              vim.api.nvim_buf_call(buf, function() vim.cmd "silent! update" end)
            end
          end,
        },
      },
    },
  },

  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      once = true,
      callback = function()
        require("editor").setup()
        require("sidebar.keys").setup()
      end,
    })
  end,
}
