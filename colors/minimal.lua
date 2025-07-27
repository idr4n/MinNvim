-- Minimal colorscheme
vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end

vim.g.colors_name = "minimal"

-- Color palette
local colors = {
  bg = "#282828",
  fg = "#a89983",
  comment = "#7d7160",
  string = "#89B482",
  number = "#FB4934",
  statusline_bg = "#303030",
  statusline_fg = "#d4be98",
  statusline_nc = "#a89983",
}

-- Helper function to set highlights
local function hl(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Basic UI
hl("Normal", { fg = colors.fg, bg = colors.bg })
hl("StatusLine", { fg = colors.statusline_fg, bg = colors.statusline_bg })
hl("StatusLineNC", { fg = colors.statusline_nc, bg = colors.statusline_bg })

-- Define the syntax groups we want colored differently
hl("Comment", { fg = colors.comment })
hl("String", { fg = colors.string })
hl("Number", { fg = colors.number })

-- Reset all other syntax groups to Normal to prevent default color bleeding
hl("Keyword", { fg = colors.fg })
hl("Function", { fg = colors.fg })
hl("Type", { fg = colors.fg })
hl("Constant", { fg = colors.fg })
hl("Boolean", { fg = colors.fg })
hl("Operator", { fg = colors.fg })
hl("Identifier", { fg = colors.fg })
hl("Special", { fg = colors.fg })
hl("PreProc", { fg = colors.fg })
hl("Statement", { fg = colors.fg })
hl("Conditional", { fg = colors.fg })
hl("Repeat", { fg = colors.fg })
hl("Label", { fg = colors.fg })
hl("Exception", { fg = colors.fg })
hl("Include", { fg = colors.fg })
hl("Define", { fg = colors.fg })
hl("Macro", { fg = colors.fg })
hl("PreCondit", { fg = colors.fg })
hl("StorageClass", { fg = colors.fg })
hl("Structure", { fg = colors.fg })
hl("Typedef", { fg = colors.fg })
hl("Delimiter", { fg = colors.fg })
