return {
  "AstroNvim/astrocore",

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
