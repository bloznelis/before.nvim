local M = {}

M.edit_locations = {}
M.dedupe_table = {}
M.cursor = 1

M.max_entries = nil
M.history_wrap_enabled = nil

local function within_bounds(bufnr, line)
  local total_lines = vim.api.nvim_buf_line_count(bufnr)

  return line > 0 and line < total_lines + 1
end

local function bufvalid(bufnr)
  return vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_is_valid(bufnr)
end

local function same_line(this_location, that_location)
  return this_location.line == that_location.line and this_location.bufnr == that_location.bufnr
end

local function is_regular_buffer(bufnr)
  return vim.api.nvim_buf_get_option(bufnr, 'buftype') == ''
end

local function should_remove(location)
  return not bufvalid(location.bufnr) or not within_bounds(location.bufnr, location.line) or
      not is_regular_buffer(location.bufnr)
end

local function assign_location(new_location, location_idx, new_cursor)
  local key = string.format("%s:%d", new_location.file, new_location.line)

  local same_line_history_idx = M.dedupe_table[key]
  if same_line_history_idx then
    table.remove(M.edit_locations, same_line_history_idx)
    location_idx = location_idx - 1
    new_cursor = new_cursor - 1
  end

  M.edit_locations[location_idx] = new_location
  M.cursor = new_cursor
  M.dedupe_table[key] = #M.edit_locations
end

local function find_backwards_jump(currentLocation)
  local local_cursor = M.cursor
  local lookback_amount = M.cursor
  for i = 0, lookback_amount do
    local_cursor = local_cursor - i
    local location = M.edit_locations[local_cursor]

    if location and not bufvalid(location.bufnr) then
      vim.cmd.edit(location.file)
      local new_bufnr = vim.api.nvim_get_current_buf()
      location['bufnr'] = new_bufnr
      M.edit_locations[local_cursor] = location
    end

    if location and should_remove(location) then
      table.remove(M.edit_locations, local_cursor)
    else
      if location and not same_line(currentLocation, location) then
        M.cursor = local_cursor
        return location
      end
    end
  end

  if M.history_wrap_enabled then
    local fallback_location = M.edit_locations[#M.edit_locations]
    if fallback_location and should_remove(fallback_location) then
      table.remove(M.edit_locations, #M.edit_locations)
    else
      M.cursor = #M.edit_locations
      return fallback_location
    end
  else
    print("[before.nvim]: At the end of the edits list.")
  end
end

local function find_forward_jump(currentLocation)
  local local_cursor = M.cursor
  local lookback_amount = M.cursor
  for i = 0, lookback_amount do
    local_cursor = local_cursor + i
    local location = M.edit_locations[local_cursor]

    if location and not bufvalid(location.bufnr) then
      vim.cmd.edit(location.file)
      local new_bufnr = vim.api.nvim_get_current_buf()
      location['bufnr'] = new_bufnr
      M.edit_locations[local_cursor] = location
    end

    if location and should_remove(location) then
      table.remove(M.edit_locations, local_cursor)
    else
      if location and not same_line(currentLocation, location) then
        M.cursor = local_cursor
        return location
      end
    end
  end

  if M.history_wrap_enabled then
    local fallback_location = M.edit_locations[1]
    if fallback_location and should_remove(fallback_location) then
      table.remove(M.edit_locations, 1)
    else
      M.cursor = 1
      return fallback_location
    end
  else
    print("[before.nvim]: At the front of the edits list.")
  end
end

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function load_file_line(file, linenum)
  local cnt = 1
  for line in io.lines(file) do
    if cnt == linenum then
      return trim(line)
    end
    cnt = cnt + 1
  end

  return ''
end

local function load_buf_line(bufnr, linenum)
  return trim(vim.api.nvim_buf_get_lines(bufnr, linenum - 1, linenum, false)[1])
end

local function get_line_content(location)
  local line_content = nil

  if bufvalid(location.bufnr) then
    line_content = load_buf_line(location.bufnr, location.line)
  else
    line_content = load_file_line(location.file, location.line)
  end

  if line_content == '' then
    line_content = "[EMPTY-LINE]"
  end
  return line_content
end

local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values

function M.show_edits_in_telescope(opts)
  local default_opts = {
    prompt_title = "Edit Locations",
    finder = finders.new_table({
      results = M.edit_locations,
      entry_maker = function(entry)
        local line_content = get_line_content(entry)
        return {
          value = entry.file .. entry.line,
          display = entry.line .. ':' .. entry.bufnr .. '| ' .. line_content,
          ordinal = entry.line .. ':' .. entry.bufnr .. '| ' .. line_content,
          filename = entry.file,
          bufnr = entry.bufnr,
          lnum = entry.line,
          col = entry.col,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = require('telescope.config').values.grep_previewer({}),
  }

  opts = vim.tbl_deep_extend("force", default_opts, opts or {})

  pickers.new({ preview_title = "Preview" }, opts):find()
end

function M.show_edits_in_quickfix()
  local qf_entries = {}
  for _, location in pairs(M.edit_locations) do
    local line_content = get_line_content(location)
    if bufvalid(location.bufnr) then
      table.insert(qf_entries, { bufnr = location.bufnr, lnum = location.line, col = location.col, text = line_content })
    else
      table.insert(qf_entries,
        { filename = location.file, lnum = location.line, col = location.col, text = line_content })
    end
  end

  vim.fn.setqflist({}, 'r', { title = 'Edit Locations', items = qf_entries })
  vim.cmd([[copen]])
end

-- DEPRECATED, but don't want to brake the users by removing.
function M.show_edits(picker_opts)
  if M.telescope_for_preview then
    M.show_edits_in_telescope(picker_opts)
  else
    M.show_edits_in_quickfix()
  end
end

function M.track_edit()
  local bufnr = vim.api.nvim_get_current_buf()
  local file = vim.fn.expand("%:p")
  local pos = vim.api.nvim_win_get_cursor(0)
  local location = { bufnr = bufnr, line = pos[1], col = pos[2], file = file }

  if is_regular_buffer(bufnr) and within_bounds(location.bufnr, location.line) then
    assign_location(location, #M.edit_locations + 1, #M.edit_locations + 1)
  end

  if #M.edit_locations > M.max_entries then
    table.remove(M.edit_locations, 1)
    M.cursor = M.max_entries
  end
end

function M.jump_to_last_edit()
  if #M.edit_locations > 0 then
    local bufnr = vim.api.nvim_get_current_buf()
    local pos = vim.api.nvim_win_get_cursor(0)
    local current = { bufnr = bufnr, line = pos[1], col = pos[2] }

    local new_location = find_backwards_jump(current)

    if new_location then
      vim.api.nvim_win_set_buf(0, new_location.bufnr)
      vim.api.nvim_win_set_cursor(0, { new_location.line, new_location.col })
    end
  else
    print("[before.nvim]: No edit locations stored.")
  end
end

function M.jump_to_next_edit()
  if #M.edit_locations > 0 then
    local bufnr = vim.api.nvim_get_current_buf()
    local pos = vim.api.nvim_win_get_cursor(0)
    local current = { bufnr = bufnr, line = pos[1], col = pos[2] }

    local new_location = find_forward_jump(current)

    if new_location then
      vim.api.nvim_win_set_buf(0, new_location.bufnr)
      vim.api.nvim_win_set_cursor(0, { new_location.line, new_location.col })
    end
  else
    print("[before.nvim]: No edit locations stored.")
  end
end

M.defaults = {
  history_size = 10,
  history_wrap_enabled = false,
  -- DEPRECATED, but don't want to brake the users by removing.
  telescope_for_preview = false
}

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", M.defaults, opts or {})

  M.max_entries = opts.history_size
  M.history_wrap_enabled = opts.history_wrap_enabled
  M.telescope_for_preview = opts.telescope_for_preview

  vim.api.nvim_create_autocmd({ "TextChanged", "InsertEnter" }, {
    pattern = "*",
    callback = function()
      require('before').track_edit()
    end,
  })
end

return M
