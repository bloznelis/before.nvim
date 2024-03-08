# before.nvim

## Purpose
Track edit locations and jump back to them, like [changelist](https://neovim.io/doc/user/motion.html#changelist), but across buffers.

![peeked](https://github.com/bloznelis/before.nvim/assets/33397865/dc60139e-4abc-4766-88f2-cb14f256e8f9)

## Installation
### lazy.nvim
```lua
{
  'bloznelis/before.nvim',
  config = function()
    local before = require('before')
    before.setup()

    -- Jump to previous entry in the edit history
    vim.keymap.set('n', '<C-h>', before.jump_to_last_edit, {})

    -- Jump to next entry in the edit history
    vim.keymap.set('n', '<C-l>', before.jump_to_next_edit, {})

    -- Move edit history to quickfix (or telescope)
    vim.keymap.set('n', '<leader>oe', before.show_edits, {})
  end
}
```

### Configuration
#### Settings
```lua
require('before').setup({
  -- How many edit locations to store in memory (default: 10)
  history_size = 42
  -- Wrap around the ends of the edit history (default: false)
  history_wrap_enabled = true
  -- Use telescope quickfix picker for `show_edits` command (default: false)
  telescope_for_preview = true
})
```
#### Telescope picker
```lua
-- Provide custom opts to telescope picker as show_edits argument:
vim.keymap.set('n', '<leader>oe', function()
  before.show_edits(require('telescope.themes').get_dropdown())
end, {})
```
