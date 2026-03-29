local M = {}

local config = {
  save_path = vim.fn.stdpath("data") .. "/harpoon_marks.json",
  max_marks = 10,
}

local state = {
  marks = {},
  ui_buf = nil,
  ui_win = nil,
}

-- Persist marks to disk
local function save()
  local file = io.open(config.save_path, "w")
  if file then
    file:write(vim.fn.json_encode(state.marks))
    file:close()
  end
end

-- Load marks from disk
local function load()
  local file = io.open(config.save_path, "r")
  if file then
    local content = file:read("*a")
    file:close()
    if content and content ~= "" then
      local ok, decoded = pcall(vim.fn.json_decode, content)
      if ok and type(decoded) == "table" then
        state.marks = decoded
      end
    end
  end
end

-- Return the absolute path of the current file
local function current_file()
  return vim.fn.expand("%:p")
end

-- Find a mark's index by path
local function find_mark(path)
  for i, mark in ipairs(state.marks) do
    if mark.path == path then
      return i
    end
  end
  return nil
end

-- Add the current file to the mark list
function M.mark_file()
  local path = current_file()
  if path == "" then
    vim.notify("Harpoon: no file to mark", vim.log.levels.WARN)
    return
  end
  if find_mark(path) then
    vim.notify("Harpoon: already marked → " .. vim.fn.fnamemodify(path, ":~:."), vim.log.levels.INFO)
    return
  end
  if #state.marks >= config.max_marks then
    vim.notify("Harpoon: mark list full (max " .. config.max_marks .. ")", vim.log.levels.WARN)
    return
  end
  table.insert(state.marks, { path = path })
  save()
  vim.notify("Harpoon: marked → " .. vim.fn.fnamemodify(path, ":~:."), vim.log.levels.INFO)
end

-- Remove the current file from the mark list
function M.unmark_file()
  local path = current_file()
  local idx = find_mark(path)
  if not idx then
    vim.notify("Harpoon: file not marked", vim.log.levels.WARN)
    return
  end
  table.remove(state.marks, idx)
  save()
  vim.notify("Harpoon: unmarked → " .. vim.fn.fnamemodify(path, ":~:."), vim.log.levels.INFO)
end

-- Toggle mark for the current file
function M.toggle_mark()
  local path = current_file()
  if path == "" then
    vim.notify("Harpoon: no file to mark", vim.log.levels.WARN)
    return
  end
  if find_mark(path) then
    M.unmark_file()
  else
    M.mark_file()
  end
end

-- Navigate to the Nth mark (1-based)
function M.nav_to(index)
  if index < 1 or index > #state.marks then
    vim.notify("Harpoon: no mark at index " .. index, vim.log.levels.WARN)
    return
  end
  local mark = state.marks[index]
  if vim.fn.filereadable(mark.path) == 0 then
    vim.notify("Harpoon: file not readable: " .. mark.path, vim.log.levels.ERROR)
    return
  end
  vim.cmd("edit " .. vim.fn.fnameescape(mark.path))
end

-- Navigate to the next mark relative to the current file
function M.nav_next()
  if #state.marks == 0 then
    vim.notify("Harpoon: no marks", vim.log.levels.WARN)
    return
  end
  local path = current_file()
  local idx = find_mark(path)
  local next_idx = idx and (idx % #state.marks) + 1 or 1
  M.nav_to(next_idx)
end

-- Navigate to the previous mark relative to the current file
function M.nav_prev()
  if #state.marks == 0 then
    vim.notify("Harpoon: no marks", vim.log.levels.WARN)
    return
  end
  local path = current_file()
  local idx = find_mark(path)
  local prev_idx = idx and ((idx - 2 + #state.marks) % #state.marks) + 1 or #state.marks
  M.nav_to(prev_idx)
end

-- ── UI ──────────────────────────────────────────────────────────────────────

local function close_ui()
  if state.ui_win and vim.api.nvim_win_is_valid(state.ui_win) then
    vim.api.nvim_win_close(state.ui_win, true)
  end
  state.ui_win = nil
  state.ui_buf = nil
end

local function render_ui()
  if not state.ui_buf or not vim.api.nvim_buf_is_valid(state.ui_buf) then return end
  vim.bo[state.ui_buf].modifiable = true
  local lines = {}
  if #state.marks == 0 then
    lines = { "  (no marks — add files with <leader>ha)" }
  else
    for i, mark in ipairs(state.marks) do
      local rel = vim.fn.fnamemodify(mark.path, ":~:.")
      lines[i] = string.format("  %d  %s", i, rel)
    end
  end
  vim.api.nvim_buf_set_lines(state.ui_buf, 0, -1, false, lines)
  vim.bo[state.ui_buf].modifiable = false
end

-- Open the floating mark list
function M.toggle_ui()
  if state.ui_win and vim.api.nvim_win_is_valid(state.ui_win) then
    close_ui()
    return
  end

  -- Create scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  state.ui_buf = buf
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "harpoon"

  -- Float dimensions
  local width = math.max(50, math.floor(vim.o.columns * 0.5))
  local height = math.max(5, math.min(#state.marks + 2, 20))
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " Harpoon Marks ",
    title_pos = "center",
  })
  state.ui_win = win

  render_ui()

  -- Keymaps inside the UI
  local opts = { buffer = buf, nowait = true, silent = true }

  -- Open file under cursor
  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_win_get_cursor(win)[1]
    close_ui()
    M.nav_to(line)
  end, opts)

  -- Delete mark under cursor
  vim.keymap.set("n", "d", function()
    local line = vim.api.nvim_win_get_cursor(win)[1]
    if state.marks[line] then
      local removed = vim.fn.fnamemodify(state.marks[line].path, ":~:.")
      table.remove(state.marks, line)
      save()
      render_ui()
      vim.notify("Harpoon: removed → " .. removed, vim.log.levels.INFO)
    end
  end, opts)

  -- Move mark up
  vim.keymap.set("n", "K", function()
    local line = vim.api.nvim_win_get_cursor(win)[1]
    if line > 1 then
      state.marks[line], state.marks[line - 1] = state.marks[line - 1], state.marks[line]
      save()
      render_ui()
      vim.api.nvim_win_set_cursor(win, { line - 1, 0 })
    end
  end, opts)

  -- Move mark down
  vim.keymap.set("n", "J", function()
    local line = vim.api.nvim_win_get_cursor(win)[1]
    if line < #state.marks then
      state.marks[line], state.marks[line + 1] = state.marks[line + 1], state.marks[line]
      save()
      render_ui()
      vim.api.nvim_win_set_cursor(win, { line + 1, 0 })
    end
  end, opts)

  -- Close
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, close_ui, opts)
  end

  -- Number keys 1-9: jump directly
  for i = 1, 9 do
    vim.keymap.set("n", tostring(i), function()
      close_ui()
      M.nav_to(i)
    end, opts)
  end

  -- Close float when focus leaves
  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = buf,
    once = true,
    callback = close_ui,
  })
end

-- ── Setup ────────────────────────────────────────────────────────────────────

function M.setup(opts)
  opts = opts or {}
  if opts.save_path then config.save_path = opts.save_path end
  if opts.max_marks then config.max_marks = opts.max_marks end

  load()

  -- Default keymaps (can be disabled with keymaps = false)
  if opts.keymaps ~= false then
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { desc = desc, silent = true })
    end
    map("<leader>ha", M.toggle_mark,  "Harpoon: toggle mark")
    map("<leader>hh", M.toggle_ui,    "Harpoon: open mark list")
    map("<leader>hn", M.nav_next,     "Harpoon: next mark")
    map("<leader>hp", M.nav_prev,     "Harpoon: prev mark")
    map("<leader>h1", function() M.nav_to(1) end, "Harpoon: go to mark 1")
    map("<leader>h2", function() M.nav_to(2) end, "Harpoon: go to mark 2")
    map("<leader>h3", function() M.nav_to(3) end, "Harpoon: go to mark 3")
    map("<leader>h4", function() M.nav_to(4) end, "Harpoon: go to mark 4")
    map("<leader>h5", function() M.nav_to(5) end, "Harpoon: go to mark 5")
  end
end

return M
