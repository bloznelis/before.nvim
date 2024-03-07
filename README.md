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

    vim.keymap.set('n', '<C-h>', before.jump_to_last_edit, {})
    vim.keymap.set('n', '<C-l>', before.jump_to_next_edit, {})
  end
}
```

### Configuration
```lua
require('before').setup({
  -- How many edit locations to store in memory (default: 10)
  history_size = 42
  -- Should it wrap around the ends of the edit history (default: false)
  history_wrap_enabled = true
})
```
