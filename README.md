# before.nvim

## Purpose
Track edit locations and jump back to them across buffers.

## Installation
### lazy.nvim
```lua
{
  "bloznelis/before.nvim",
  config = function ()
    local before = require('before')

    vim.keymap.set('n', 'g[', function()
      before.jump_to_prev_edit()
    end, {})

    before.setup()
  end
}
```

## To-Do
* Prune location list. User shouldn't click "go-back" and go nowhere because last edit is at the same
location cursor now.
* Removal of closed buffer locations (or maybe reopen the closed buffer?)
