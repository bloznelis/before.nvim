# before.nvim
## Purpose
Track edit locations and jump back to them, like [changelist](https://neovim.io/doc/user/motion.html#changelist) across buffers.

## Installation
### lazy.nvim
```lua
{
  "bloznelis/before.nvim",
  opts = {
      -- How many edit locations to store in memory (default: 10)
      historySize = 10,

      mapping = {
        -- Should plugin register default keymaps on setup (default: false)
        registerDefaults = true,
        -- Keymap to jump to previous edit location (default: <C-h>)
        jumpToPreviousEdit = "<C-h>"
      }
    }
}
```
