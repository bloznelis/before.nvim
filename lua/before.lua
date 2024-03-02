local M = {}

-- edit locations stack
M.edit_locations = {}
M.cursor = 1
M.max_entries = 5

local function is_position_within_bounds(bufnr, line)
  local total_lines = vim.api.nvim_buf_line_count(bufnr)
  if line < 1 or line > total_lines then
    return false
  end

  return true
end

local function dec_cursor()
  M.cursor = M.cursor - 1
  if M.cursor < 1 then
    M.cursor = #M.edit_locations
  end
end

function M.track_edit()
  local bufnr = vim.api.nvim_get_current_buf()
  local pos = vim.api.nvim_win_get_cursor(0) -- 0 gets the current window
  local location = { bufnr = bufnr, line = pos[1], col = pos[2] }
  local prev_location = M.edit_locations[#M.edit_locations]

  if prev_location then
    if location.line ~= prev_location.line then --should check for same buffer only
      M.edit_locations[#M.edit_locations + 1] = location
      M.cursor = #M.edit_locations
    end
  else
    M.edit_locations[#M.edit_locations + 1] = location
    M.cursor = #M.edit_locations
  end

  if #M.edit_locations > M.max_entries then
    table.remove(M.edit_locations, 1)
    M.cursor = M.max_entries
  end
end

function M.jump_to_prev_edit()
  if #M.edit_locations > 0 then
    local bufnr = vim.api.nvim_get_current_buf()
    local pos = vim.api.nvim_win_get_cursor(0) -- 0 gets the current window
    local current = { bufnr = bufnr, line = pos[1], col = pos[2] }
    local location_cursor = M.cursor
    local location = M.edit_locations[location_cursor]

    if location then
      -- If previous edit location is the same as current cursor, try a later one.
      -- This accommodates for cursor still being in a just-edited-line.
      if current.line == location.line then
        location_cursor = M.cursor - 1
        location = M.edit_locations[location_cursor]
      end

      dec_cursor()

      if location and vim.api.nvim_buf_is_loaded(location.bufnr) and is_position_within_bounds(location.bufnr, location.line) then
        vim.api.nvim_win_set_buf(0, location.bufnr)
        vim.api.nvim_win_set_cursor(0, { location.line, location.col })
      else
        table.remove(M.edit_locations, location_cursor)
      end
    end
  else
    print("No previous edit locations stored.")
  end
end

function M.setup()
  vim.cmd([[
    augroup EditTracker
      autocmd!
      autocmd BufWrite * lua require('before').track_edit()
    augroup END
  ]])
end

return M
