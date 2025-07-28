-- Name: vtsls
-- Install: npm install -g @vtsls/language-server
-- Formatter: use prettier cli

return {
  cmd = { "vtsls", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
  root_markers = { "tsconfig.json", "package.json", "jsconfig.json", ".git" },
}
