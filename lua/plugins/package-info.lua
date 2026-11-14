---@type LazySpec
return {
  "vuki656/package-info.nvim",
  dependencies = { "MunifTanjim/nui.nvim" },
  event = "BufRead package.json",
  ---@type table
  opts = {
    -- package.json を開いたら、最新バージョンを自動で表示する
    autostart = true,
    -- ロックファイルがないプロジェクトでは pnpm を使う
    package_manager = "pnpm",
  },
}
