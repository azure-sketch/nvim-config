---@type LazySpec
return {
  "AstroNvim/astrocore",

  ---@type AstroCoreOpts
  opts = {
    commands = {
      -- 処理は lua/editor/file/json_sort.lua に置く
      JsonSortKeys = {
        function(args) require("editor.file.json_sort").run(args) end,
        range = true,
        desc = "JSON のキーを並べ替える（jq。選択範囲があれば範囲のみ）",
      },
    },
  },
}
