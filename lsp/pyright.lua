-- Name: pyright
-- Instal: pip install pyright, or, npm install -g pyright
-- format: use ruff or uvx ruff
--    ruff format --check
--    ruff check

return {
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_marker = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", "pyrightconfig.json", ".git" },
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
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightOrganizeImports', function()
      client:exec_cmd({
        command = 'pyright.organizeimports',
        arguments = { vim.uri_from_bufnr(bufnr) },
      })
    end, {
      desc = 'Organize Imports',
    })
  end,
}
