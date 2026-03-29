-- Auto-loaded by Neovim. Sets up user commands so the plugin works
-- even without an explicit require('harpoon').setup() call.

if vim.g.loaded_harpoon then return end
vim.g.loaded_harpoon = true

local function lazy_harpoon(method, ...)
  local args = { ... }
  return function()
    local ok, h = pcall(require, "harpoon")
    if not ok then
      vim.notify("Harpoon: failed to load — " .. h, vim.log.levels.ERROR)
      return
    end
    h[method](table.unpack(args))
  end
end

-- User commands
vim.api.nvim_create_user_command("HarpoonMark",    lazy_harpoon("toggle_mark"), { desc = "Harpoon: toggle mark on current file" })
vim.api.nvim_create_user_command("HarpoonList",    lazy_harpoon("toggle_ui"),   { desc = "Harpoon: open/close mark list" })
vim.api.nvim_create_user_command("HarpoonNext",    lazy_harpoon("nav_next"),    { desc = "Harpoon: navigate to next mark" })
vim.api.nvim_create_user_command("HarpoonPrev",    lazy_harpoon("nav_prev"),    { desc = "Harpoon: navigate to previous mark" })
vim.api.nvim_create_user_command("HarpoonNav", function(args)
  local idx = tonumber(args.args)
  if not idx then
    vim.notify("Harpoon: provide a mark index, e.g. :HarpoonNav 2", vim.log.levels.WARN)
    return
  end
  lazy_harpoon("nav_to", idx)()
end, { nargs = 1, desc = "Harpoon: navigate to mark N" })
