local ns = vim.api.nvim_create_namespace("md_lite")

local function render_list(buf, lines, cursor_line)
    local i = 1
    local counts = {}
    while i <= #lines do
        local line = lines[i]
        local spaces = line:match("^(%s*)%d+%.%s")

        if spaces ~= nil then
            local offset = #spaces
            if counts[offset] == nil then
                counts[offset] = 1
            else
                counts[offset] = counts[offset] + 1
            end

            -- clear inner count whenever outer increment
            for k in pairs(counts) do
                if k > offset then counts[k] = nil end
            end

            -- cursor_line 1 based
            if i ~= cursor_line then
                local count = counts[offset]
                -- nvim api 0 based
                vim.api.nvim_buf_set_extmark(buf, ns, i - 1, offset, {
                    virt_text = { { count .. ".", "@markup.list" } },
                    virt_text_pos = "overlay",
                })
            end
        else
            counts = {}
        end
        i = i + 1
    end
end

local function render(buf)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local cursor_line = vim.api.nvim_win_get_cursor(0)[1]
    render_list(buf, lines, cursor_line)
end

return { render = render }
