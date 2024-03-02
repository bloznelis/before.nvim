local M = {}

-- edit locations stack
M.edit_locations = {}
M.cursor = 1

local function is_position_within_bounds(line)
  local total_lines = vim.api.nvim_buf_line_count(0)
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

  M.edit_locations[#M.edit_locations + 1] = location
  M.cursor = #M.edit_locations
end

function M.jump_to_prev_edit()
  if #M.edit_locations > 0 then
    local location = M.edit_locations[M.cursor]
    if location and vim.api.nvim_buf_is_loaded(location.bufnr) then
      dec_cursor()

      if is_position_within_bounds(location.line) then
        vim.api.nvim_win_set_buf(0, location.bufnr)
        vim.api.nvim_win_set_cursor(0, { location.line, location.col })
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
