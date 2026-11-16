-- mise 設定ファイル（mise.toml など）の補完・検証。mise 本体の `mise lsp` を使う（Mason では入れない）。
-- mise が対象ファイルを自分で判定し、Cargo.toml など他の TOML は無視するので、filetype は toml でよい。

---@type vim.lsp.Config
return {
  cmd = { "mise", "lsp" },
  filetypes = { "toml" },
  root_markers = { "mise.toml", ".mise.toml" },
}
