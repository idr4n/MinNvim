-- Name: pyright
-- Instal: pip install pyright, or, npm install -g pyright
-- format: use ruff or uvx ruff
--    ruff format --check
--    ruff check

return {
  cmd = { 'pyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = {
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    'Pipfile',
    'pyrightconfig.json',
    '.git',
  },
  settings = {
    python = {
      analysis = {
        typeCheckingMode = 'on',
        diagnosticMode = 'workspace',
        extraPaths = { '/Applications/Sublime Text.app/Contents/MacOS/Lib/python38' },
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
      },
    },
  },
}
