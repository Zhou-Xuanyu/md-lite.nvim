-- md_lite.lua — render ordered lists with correct sequential numbers.

local ns = vim.api.nvim_create_namespace("md_lite")

local function render(buf)
    -- clear previous extmarks
    -- 0,-1 row range
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

    -- return all lines as lua table
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local count = 0
    -- 0 means current window
    -- [1] filter out row from {row, col}
    local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

    -- note that line_index is 1 based
    for line_index, line in ipairs(lines) do
        -- pattern of ordered list in markdown
        -- ^ start of line
        -- (%s*) indent: () is what match returns
        -- %d+ digits
        -- %. the dot
        -- %s space
        local indent = line:match("^(%s*)%d+%.%s")

        if indent then
            count = count + 1
            -- skip the overlay on the cursor line so raw markdown stays visible
            if line_index ~= cursor_line then
                -- note here we want 0 based index
                vim.api.nvim_buf_set_extmark(buf, ns, line_index - 1, #indent, {
                    virt_text = { { count .. ".", "@markup.list" } },
                    virt_text_pos = "overlay",
                })
            end
        else
            count = 0
        end
    end
end

return { render = render }
