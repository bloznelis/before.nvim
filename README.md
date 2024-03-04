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
  * This is quite rare now, but still sometimes happens due to some edgecase. Probably need to loop around the list to find the next hop.
* Limit edit location list size (make it configurable)
* Maybe better event to listen to would be [TextChanged](https://neovim.io/doc/user/autocmd.html#TextChanged)https://neovim.io/doc/user/autocmd.html#TextChanged, instead of BufWrite, because if cursor is moved away from the actual edit when the write happens it will record a wrong location.
