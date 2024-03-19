local ok, telescope = pcall(require, 'telescope')
local before_telescope = require('before').show_edits_in_telescope

if not ok then
  -- this shouldn't happen: lua/telescope/_extensions gets called _by_ telescope.
  error 'Install nvim-telescope/telescope.nvim to use the telescope extension for bloznelis/before.nvim.'
end

return telescope.register_extension {
  exports = {
    before = before_telescope,
  }
}
