# before.nvim

## Purpose
Track edit locations and jump back to them, like [changelist](https://neovim.io/doc/user/motion.html#changelist), but across buffers.

![peeked](https://github.com/bloznelis/before.nvim/assets/33397865/1130572d-dd75-4a07-9c79-9afc91b5d67a)

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

    -- Look for previous edits in quickfix list
    vim.keymap.set('n', '<leader>oq', before.show_edits_in_quickfix, {})

    -- Look for previous edits in telescope (needs telescope, obviously)
    vim.keymap.set('n', '<leader>oe', before.show_edits_in_telescope, {})
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
})
```
#### Telescope picker
```lua
-- You can provide telescope opts to the picker via show_edits_in_telescope arguments:
vim.keymap.set('n', '<leader>oe', function()
  before.show_edits_in_telescope(require('telescope.themes').get_dropdown())
end, {})
```

#### Register Telescope extension

You may also register the extension via telescope:

```lua
require 'telescope'.setup({ '$YOUR_TELESCOPE_OPTS' })
require 'telescope'.load_extension('before')
```

Then call via vimscript:

```vim
:Telescope before
```

or lua:

```lua
require 'telescope'.extensions.before.before
```
