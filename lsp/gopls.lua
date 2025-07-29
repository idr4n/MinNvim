-- Name: gopls
-- Install: go install golang.org/x/tools/gopls@latest
-- Formatter: gopls formats with gofmt by default. Otherwise, use:
--    gofumpt (stricter formatter)
--    goimports (update import lines, adding missing ones and removing unreferenced ones)

return {
  cmd = { 'gopls' },
  filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
  root_markers = { 'go.mod', 'go.work', '.git' },
}
