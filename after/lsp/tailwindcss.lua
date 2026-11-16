-- package.json があるプロジェクトでだけ tailwindcss を起動する（JS ランタイムは node のみの前提）。
-- nvim-lspconfig の既定は、ルート判定の最後に .git を含むため、Tailwind を使わない
-- Git リポジトリの .md などにも接続してしまう。その .git のフォールバックを使わない。

---@type vim.lsp.Config
return {
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, "package.json")
    if root then on_dir(root) end
  end,
}
