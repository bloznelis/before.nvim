local M = {}

M.edit_locations = {}
M.cursor = 1
M.max_entries = 5

local function withinBounds(bufnr, line)
  local total_lines = vim.api.nvim_buf_line_count(bufnr)

  return line > 1 and line < total_lines
end

local function bufvalid(bufnr)
  return vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_is_valid(bufnr)
end

local function sameLine(thisLocation, thatLocation)
  return thisLocation.line == thatLocation.line and thisLocation.bufnr == thatLocation.bufnr
end

local function isNormalBuffer(bufnr)
  return vim.api.nvim_buf_get_option(bufnr, 'buftype') == ''
end

local function shouldRemove(location)
  return not bufvalid(location.bufnr) or not withinBounds(location.bufnr, location.line) or
      not isNormalBuffer(location.bufnr)
end

function M.track_edit()
  local bufnr = vim.api.nvim_get_current_buf()
  local pos = vim.api.nvim_win_get_cursor(0)
  local location = { bufnr = bufnr, line = pos[1], col = pos[2] }
  local prev_location = M.edit_locations[#M.edit_locations]

  if isNormalBuffer(bufnr) then
    if prev_location then
      if not sameLine(location, prev_location) then
        M.edit_locations[#M.edit_locations + 1] = location
        M.cursor = #M.edit_locations
      end
    else
      M.edit_locations[#M.edit_locations + 1] = location
      M.cursor = #M.edit_locations
    end
  end

  if #M.edit_locations > M.max_entries then
    table.remove(M.edit_locations, 1)
    M.cursor = M.max_entries
  end
end

local function findJump(currentLocation)
  local localCursor = M.cursor
  local lookBackAmount = M.cursor
  for i = 1, lookBackAmount do
    localCursor = localCursor - i
    local location = M.edit_locations[localCursor]

    if location and shouldRemove(location) then
      table.remove(M.edit_locations, localCursor)
    else
      if location and not sameLine(currentLocation, location) then
        M.cursor = localCursor
        return location
      end
    end
  end

  local fallbackLocation = M.edit_locations[#M.edit_locations]
  if fallbackLocation and shouldRemove(fallbackLocation) then
    table.remove(M.edit_locations, #M.edit_locations)
  else
    M.cursor = #M.edit_locations
    return fallbackLocation
  end
end

function M.jump_to_prev_edit()
  if #M.edit_locations > 0 then
    local bufnr = vim.api.nvim_get_current_buf()
    local pos = vim.api.nvim_win_get_cursor(0)
    local current = { bufnr = bufnr, line = pos[1], col = pos[2] }

    local newLocation = findJump(current)

    if newLocation then
      vim.api.nvim_win_set_buf(0, newLocation.bufnr)
      vim.api.nvim_win_set_cursor(0, { newLocation.line, newLocation.col })
    end
  else
    print("No previous edit locations stored.")
  end
end

M.defaults = {
  historySize = 10,

  mapping = {
    registerDefaults = true,
    jumpToPreviousEdit = "<C-h>"
  }
}

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", M.defaults, opts)

  M.max_entries = opts.historySize

  if opts.mapping.registerDefaults then
    vim.keymap.set('n', opts.mapping.jumpToPreviousEdit, function()
      require('before').jump_to_prev_edit()
    end, {})
  end

  vim.api.nvim_create_autocmd({ "TextChanged", "InsertEnter" }, {
    pattern = "*",
    callback = function()
      require('before').track_edit()
    end,
  })
end

return M
