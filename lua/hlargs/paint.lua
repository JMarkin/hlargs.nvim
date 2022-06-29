local M = {}
local config = require("hlargs.config")
local colorpalette = require("hlargs.colorpalette")
local hl_group = "Hlargs"

local BUF_ARG_COLOR = {}

-- Clears a namespace within limits
-- (or in the entire buffer if limits is nil)
function M.clear(bufnr, ns, limits)
  local from, to = 0, -1
  if limits then
    from, to = limits[1], limits[2]
  end
  BUF_ARG_COLOR[bufnr] = {}
  vim.api.nvim_buf_clear_namespace(bufnr, ns, from, to)
end

function M.set_extmark(bufnr, ns, start_row, start_col, end_row, end_col, hl_group, priority)
  local ok, mark_id = pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, start_row, start_col, {
    end_line = end_row,
    end_col = end_col,
    hl_group = hl_group,
    priority = priority,
  })
  return mark_id
end

function get_hl_group(bufnr, start_row, start_col, end_row, end_col)
  if not config.opts.use_colorpalette then
    return hl_group
  end
  local check_cache = BUF_ARG_COLOR[bufnr] ~= nil
  if not check_cache then
    BUF_ARG_COLOR[bufnr] = {}
  end
  local arg_name = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {})
  arg_name = arg_name[1]

  if BUF_ARG_COLOR[bufnr][arg_name] == nil then
    local color = colorpalette.get_color()
    BUF_ARG_COLOR[bufnr][arg_name] = color
  end
  return BUF_ARG_COLOR[bufnr][arg_name].hl_group
end

function M.combine_nss(bufnr, dst, src, limits)
  local from, to = 0, -1
  if limits then
    from, to = { limits[1], 0 }, { limits[2], -1 }
  end

  local ok, extmarks = pcall(vim.api.nvim_buf_get_extmarks, bufnr, src, from, to, { details = true })
  for _, extmark in ipairs(extmarks) do
    local start_row, start_col, end_row, end_col = extmark[2], extmark[3], extmark[4].end_row, extmark[4].end_col
    local hl_group = get_hl_group(bufnr, start_row, start_col, end_row, end_col)
    M.set_extmark(bufnr, dst, start_row, start_col, end_row, end_col, hl_group, config.opts.hl_priority)
  end
end

setmetatable(M, {
  __call = function(self, bufnr, ns, node)
    local start_row, start_col, end_row, end_col = node:range()
    M.set_extmark(bufnr, ns, start_row, start_col, end_row, end_col, hl_group, config.opts.hl_priority)
  end,
})

return M
