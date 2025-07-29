-- Name: rust_analyzer
-- Install: brew install rust-analyzer

return {
  cmd = { 'rust-analyzer' },
  filetypes = { 'rust' },
  root_markers = { 'Cargo.toml', 'rust-project.json', '.git' },
  settings = {
    ['rust-analyzer'] = {
      check = { command = 'clippy' },
      cargo = { features = 'all' },
    },
  },
}
