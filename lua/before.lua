local M = {}

M.edit_locations = {}
M.cursor = 1
M.max_entries = nil

local function within_bounds(bufnr, line)
  local total_lines = vim.api.nvim_buf_line_count(bufnr)

  return line > 1 and line < total_lines
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
  local invalid_bufnr = not bufvalid(location.bufnr) or not within_bounds(location.bufnr, location.line) or
      not is_regular_buffer(location.bufnr)

  -- then try to look up filename
  local invalid_file = not vim.fn.filereadable(location.file)

  -- return invalid_bufnr or invalid_file?
  --  TODO: don't really know what to do here
  return false
end

function M.track_edit()
  local bufnr = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(bufnr)
  local pos = vim.api.nvim_win_get_cursor(0)
  local location = { file = file, bufnr = bufnr, line = pos[1], col = pos[2] }
  local prev_location = M.edit_locations[#M.edit_locations]

  if is_regular_buffer(bufnr) then
    if prev_location then
      if not same_line(location, prev_location) then
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

  M.save_cache()
end

local function find_backwards_jump(currentLocation)
  local local_cursor = M.cursor
  local lookback_amount = M.cursor
  for i = 1, lookback_amount do
    local_cursor = local_cursor - i
    local location = M.edit_locations[local_cursor]

    if location and should_remove(location) then
      table.remove(M.edit_locations, local_cursor)
    else
      if location and not same_line(currentLocation, location) then
        M.cursor = local_cursor
        return location
      end
    end
  end

  local fallback_location = M.edit_locations[#M.edit_locations]
  if fallback_location and should_remove(fallback_location) then
    table.remove(M.edit_locations, #M.edit_locations)
  else
    M.cursor = #M.edit_locations
    return fallback_location
  end
end

local function find_forward_jump(currentLocation)
  local local_cursor = M.cursor
  local lookback_amount = M.cursor
  for i = 1, lookback_amount do
    local_cursor = local_cursor + i
    local location = M.edit_locations[local_cursor]

    if location and should_remove(location) then
      table.remove(M.edit_locations, local_cursor)
    else
      if location and not same_line(currentLocation, location) then
        M.cursor = local_cursor
        return location
      end
    end
  end

  local fallback_location = M.edit_locations[1]
  if fallback_location and should_remove(fallback_location) then
    table.remove(M.edit_locations, 1)
  else
    M.cursor = 1
    return fallback_location
  end
end

function M.jump_to_last_edit()
  if #M.edit_locations > 0 then
    local bufnr = vim.api.nvim_get_current_buf()
    local file = vim.api.nvim_buf_get_name(bufnr)
    local pos = vim.api.nvim_win_get_cursor(0)
    local current = { file = file, bufnr = bufnr, line = pos[1], col = pos[2] }

    local new_location = find_backwards_jump(current)

    vim.print(vim.inspect(new_location))

    if new_location and new_location.file ~= file then
      vim.api.nvim_command("e " .. new_location.file)
      vim.api.nvim_win_set_cursor(0, { new_location.line, new_location.col })
    else
      if new_location then
        vim.api.nvim_win_set_buf(0, new_location.bufnr)
        vim.api.nvim_win_set_cursor(0, { new_location.line, new_location.col })
      end
    end
  else
    print("No edit locations stored.")
  end
end

function M.jump_to_next_edit()
  if #M.edit_locations > 0 then
    local bufnr = vim.api.nvim_get_current_buf()
    local file = vim.api.nvim_buf_get_name(bufnr)
    local pos = vim.api.nvim_win_get_cursor(0)
    local current = { file = file, bufnr = bufnr, line = pos[1], col = pos[2] }

    local new_location = find_forward_jump(current)

    if new_location and new_location.file ~= file then
      vim.api.nvim_command("e " .. new_location.file)
      vim.api.nvim_win_set_cursor(0, { new_location.line, new_location.col })
    else
      if new_location then
        vim.api.nvim_win_set_buf(0, new_location.bufnr)
        vim.api.nvim_win_set_cursor(0, { new_location.line, new_location.col })
      end
    end
  else
    print("No edit locations stored.")
  end
end

function M.cache_path()
  return vim.fn.stdpath("cache") .. "/before"
end

function M.save_cache()
  local path = M.cache_path()

  if vim.fn.isdirectory(path) == 0 then
    vim.fn.mkdir(path, "p")
  end

  local cache = M.serialize_cache(M.edit_locations)

  vim.fn.writefile(cache, path .. "/cache")
end

function M.load_cache()
  local path = M.cache_path()

  local success, data = pcall(vim.fn.readfile, path .. "/cache")
  -- print("success", success)
  if success then
    M.edit_locations = M.deserialize_cache(data)
    M.cursor = #M.edit_locations
  else
    -- do nothing?
    -- M.edit_locations = {}
  end

  print("loaded cache", vim.inspect(M.edit_locations))
end

function M.serialize_cache(content)
  local lines = {}
  for _, location in ipairs(content) do
    table.insert(lines, string.format("%s:%s:%s:%s", location.file, location.bufnr, location.line, location.col))
  end

  return lines
end

-- Loop through it and serialize it to a string:
function M.deserialize_cache(lines)
  local content = {}
  for _, line in ipairs(lines) do
    local parts = vim.fn.split(line, ":")

    -- ignore repeated entries
    local tableContains = function(tab, val)
      for index, value in ipairs(tab) do
        if value.file == val.file and value.bufnr == val.bufnr and value.line == val.line and value.col == val.col then
          return true
        end
      end
      return false
    end

    local entry = { file = parts[1], bufnr = tonumber(parts[2]), line = tonumber(parts[3]), col = tonumber(parts[4]) }
    if not tableContains(content, entry) then
      table.insert(content, entry)
    end
  end

  return content
end

M.defaults = {
  history_size = 10
}

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", M.defaults, opts or {})

  M.max_entries = opts.history_size

  vim.api.nvim_create_autocmd({ "TextChanged", "InsertEnter" }, {
    pattern = "*",
    callback = function()
      require('before').track_edit()
    end,
  })

  vim.api.nvim_create_autocmd({ "VimEnter" }, {
    pattern = '*',
    callback = function()
      M.load_cache()
    end,
  })
end

return M
