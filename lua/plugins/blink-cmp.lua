return {
  "saghen/blink.cmp",

  opts = function(_, opts)
    opts.keymap = opts.keymap or {}

    -- VS Code風の編集操作に使うキー
    local reserved_keys = {
      "g",
      "h",
      "k",
      "l",
      "n",
      "t",
    }

    for _, key in ipairs(reserved_keys) do
      opts.keymap["<C-" .. key .. ">"] = false
      opts.keymap["<C-" .. key:upper() .. ">"] = false
    end
  end,
}
