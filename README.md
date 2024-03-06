# before.nvim
## Purpose
Track edit locations and jump back to them, like [changelist](https://neovim.io/doc/user/motion.html#changelist), but across buffers.

![peeked](https://github.com/bloznelis/before.nvim/assets/33397865/d7d8c79e-e716-4588-b602-2271fb0bda1e)

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
})
```
