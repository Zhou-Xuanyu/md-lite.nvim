local ns = vim.api.nvim_create_namespace("md_lite")

-- Recursively renders ordered list items starting at `start` (1-based) in `lines`.
--
-- Each call owns one indentation level (`indent_offset`). It walks forward
-- through lines and handles three cases:
--
--   1. Not a list item         → reset count, advance
--   2. indent_level == offset  → base case: number this item, advance
--   3. indent_level >  offset  → recurse one level deeper; resume where it stopped
--
-- When the call encounters a line whose indent_level is shallower than its
-- own offset, that line belongs to an ancestor — return `i` without consuming
-- it so the parent can process it.
--
-- Returns the index of the first line it did NOT consume.
local function render_block(buf, lines, start, indent_offset, cursor_line, unit_size)
    local count = 0
    local i = start

    while i <= #lines do
        local line = lines[i]
        -- capture leading whitespace only when followed by "N. " (ordered list item)
        local indent = line:match("^(%s*)%d+%.%s")

        if indent == nil then
            -- not a list item at any level — reset count for this level and move on
            count = 0
            i = i + 1
        else
            -- number of indent levels = leading spaces / spaces-per-level
            local indent_level = math.floor(#indent / unit_size)

            if indent_level < indent_offset then
                -- this line belongs to a shallower level — stop and let the caller handle it
                return i
            elseif indent_level == indent_offset then
                -- base case: item belongs to our level, assign the next sequential number
                count = count + 1
                -- skip overlay on cursor line so raw markdown stays visible while editing
                if i ~= cursor_line then
                    vim.api.nvim_buf_set_extmark(buf, ns, i - 1, #indent, {
                        virt_text = { { count .. ".", "@markup.list" } },
                        virt_text_pos = "overlay",
                    })
                end
                i = i + 1
            else
                -- recursive case: item is deeper than our level
                -- hand off to a new call at indent_offset + 1
                -- that call will return the index of the first line it couldn't handle
                -- (i.e. where indentation went back up), and we resume from there
                i = render_block(buf, lines, i, indent_offset + 1, cursor_line, unit_size)
            end
        end
    end

    return i
end

local function render(buf)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

    -- resolve indent unit from buffer settings:
    -- shiftwidth=0 means "use tabstop"; for hard tabs each tab char = one level
    local sw = vim.bo[buf].shiftwidth
    if sw == 0 then sw = vim.bo[buf].tabstop end
    local unit_size = vim.bo[buf].expandtab and sw or 1

    -- kick off at line 1, indent level 0 (no indentation = top level)
    render_block(buf, lines, 1, 0, cursor_line, unit_size)
end

return { render = render }
