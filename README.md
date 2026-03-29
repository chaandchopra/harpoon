# harpoon-fixed

A lightweight Neovim plugin for marking files and navigating between them instantly.

## Features

- **Mark files** — pin any open file to a persistent list
- **List marks** — floating UI showing all marked files
- **Navigate** — jump to any mark by index, or cycle next/prev
- **Reorder & delete** — manage marks directly from the UI
- **Persistent** — marks survive across Neovim restarts (saved as JSON)

## Installation

**lazy.nvim**
```lua
{
  dir = "~/Downloads/harpoon-fixed",   -- or a GitHub path after publishing
  config = function()
    require("harpoon").setup()
  end,
}
```

**packer.nvim**
```lua
use {
  "~/Downloads/harpoon-fixed",
  config = function() require("harpoon").setup() end,
}
```

## Default Keymaps

| Key           | Action                        |
|---------------|-------------------------------|
| `<leader>ha`  | Toggle mark on current file   |
| `<leader>hh`  | Open / close mark list        |
| `<leader>hn`  | Jump to next mark             |
| `<leader>hp`  | Jump to previous mark         |
| `<leader>h1`–`h5` | Jump directly to mark N   |

## Mark List UI Keys

| Key       | Action                     |
|-----------|----------------------------|
| `<CR>`    | Open file under cursor     |
| `d`       | Remove mark under cursor   |
| `K`       | Move mark up               |
| `J`       | Move mark down             |
| `1`–`9`   | Jump to that mark directly |
| `q`/`<Esc>` | Close the window         |

## Commands

| Command           | Description                        |
|-------------------|------------------------------------|
| `:HarpoonMark`    | Toggle mark on current file        |
| `:HarpoonList`    | Open / close mark list             |
| `:HarpoonNext`    | Jump to next mark                  |
| `:HarpoonPrev`    | Jump to previous mark              |
| `:HarpoonNav {n}` | Jump to mark number n              |

## Setup Options

```lua
require("harpoon").setup({
  save_path = vim.fn.stdpath("data") .. "/harpoon_marks.json",
  max_marks = 10,
  keymaps   = true,   -- set false to define your own
})
```
