-- Name: ruff
-- Instal: pip install ruff
-- format: use ruff or uvx ruff
--    ruff format --check
--    ruff check

return {
  cmd = { "ruff", "server" },
  filetypes = { "python" },
  root_marker = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
}
