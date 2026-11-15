---@type vim.lsp.Config
return {
  -- プロジェクト直下に typescript が無い（pnpm の仮想ストアにだけある）ときのフォールバック。
  -- lspconfig の before_init を置き換えるため、同じ探し方を先に行う。
  before_init = function(_, config)
    local tsdk = require("lspconfig.util").get_typescript_server_path(config.root_dir)
    if tsdk == "" and config.root_dir then
      local dirs = { config.root_dir }
      for dir in vim.fs.parents(config.root_dir) do
        dirs[#dirs + 1] = dir
      end
      for _, dir in ipairs(dirs) do
        local lib = dir .. "/node_modules/.pnpm/node_modules/typescript/lib"
        if vim.uv.fs_stat(lib .. "/typescript.js") then
          tsdk = lib
          break
        end
      end
    end
    config.init_options = config.init_options or {}
    config.init_options.typescript = config.init_options.typescript or {}
    config.init_options.typescript.tsdk = tsdk
  end,
}
