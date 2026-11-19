local M = {}

-- VS Code 本家の Tokyo Night (Night / Storm) パレット。
function M.apply(hl)
  local foreground = "#a9b1d6"
  local muted = "#565f89"
  local surface = "#414868"
  local added = "#9ece6a"
  local removed = "#f7768e"

  hl.GrugFarInputLabel = { fg = foreground }
  hl.GrugFarInputPlaceholder = { fg = muted }
  hl.GrugFarResultsHeader = { fg = muted }
  hl.GrugFarResultsStats = { fg = foreground }
  hl.GrugFarResultsPath = { fg = foreground }
  hl.GrugFarResultsLineNr = { fg = muted }
  hl.GrugFarResultsCursorLineNo = { fg = foreground }
  hl.GrugFarResultsNumberLabel = { fg = muted }
  hl.GrugFarResultsMatch = { fg = "#c0caf5", bg = surface }
  hl.GrugFarResultsMatchAdded = { fg = added }
  hl.GrugFarResultsMatchRemoved = { fg = removed }
  hl.GrugFarResultsAddIndicator = { fg = added }
  hl.GrugFarResultsRemoveIndicator = { fg = removed }
  hl.GrugFarResultsChangeIndicator = { fg = "#e0af68" }
  hl.GrugFarResultsDiffSeparatorIndicator = { fg = muted }
end

return M
