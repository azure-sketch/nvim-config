-- 参照元の移行が完了するまで、通常ファイル用の実装へ転送する。
return {
  close = require("editor.file.buffers").close,
}
