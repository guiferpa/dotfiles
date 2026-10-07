-- Tells whether a buffer belongs to a project that configures ESLint, so
-- eslint_d only runs where it has a config to read. Without one it exits
-- with an error that nvim-lint and conform surface on every buffer.
local M = {}

local config_files = {
  "eslint.config.js",
  "eslint.config.mjs",
  "eslint.config.cjs",
  "eslint.config.ts",
  "eslint.config.mts",
  "eslint.config.cts",
  ".eslintrc",
  ".eslintrc.js",
  ".eslintrc.cjs",
  ".eslintrc.yaml",
  ".eslintrc.yml",
  ".eslintrc.json",
}

local function package_json_has_config(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return false
  end
  local decoded_ok, pkg = pcall(vim.json.decode, table.concat(lines, "\n"))
  return decoded_ok and type(pkg) == "table" and pkg.eslintConfig ~= nil
end

function M.has_config(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr or 0)
  if path == "" then
    return false
  end
  local start = vim.fs.dirname(path)

  if #vim.fs.find(config_files, { path = start, upward = true, limit = 1 }) > 0 then
    return true
  end

  for _, pkg in ipairs(vim.fs.find("package.json", { path = start, upward = true, limit = math.huge })) do
    if package_json_has_config(pkg) then
      return true
    end
  end
  return false
end

M.filetypes = {
  javascript = true,
  typescript = true,
  javascriptreact = true,
  typescriptreact = true,
}

return M
