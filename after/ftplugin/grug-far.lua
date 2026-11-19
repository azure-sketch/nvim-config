-- Tab は検索入力欄の移動に使うため、このバッファでは補完を無効にする。
vim.b.completion = false
require("sidebar.search_guide").setup_buffer(vim.api.nvim_get_current_buf())
