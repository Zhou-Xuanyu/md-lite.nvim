local ns = vim.api.nvim_create_namespace("md_lite")

-- Recursively renders ordered list items starting at `start` (1-based).
--
-- Before matching, strip `indent_offset * indent_size` characters from the
-- line so it looks top-level to this call. After stripping:
--
--   indent == nil   → not a list item (or shallower line stripped to garbage):
--                     at depth 0 just reset and advance; at depth >0 return
--                     so the parent can re-process the line with its own prefix
--   #indent == 0    → base case: item belongs to our level, assign next number
--   #indent >  0    → recursive case: still has indent, go one level deeper
--
-- Returns the index of the first line it did NOT consume.
local function render_block(buf, lines, start, indent_offset, cursor_line, indent_size)
    local count = 0
    local line_index = start
    -- number of characters to strip = levels * spaces-per-level
    local strip = indent_offset * indent_size

    while line_index <= #lines do
        local line = lines[line_index]
        -- strip the expected prefix for this level; leaves garbage if line is shallower
        line = line:sub(strip + 1)

        --   ^     = anchor to start of stripped line
        --   (%s*) = capture any remaining indentation
        --   %d+   = one or more digits
        --   %.    = literal dot
        --   %s    = space after dot
        local indent = line:match("^(%s*)%d+%.%s")

        if indent == nil then
            -- either not a list item, or a shallower line whose prefix was stripped to garbage
            count = 0
            if indent_offset > 0 then
                -- let the parent re-process this line at the correct level
                return line_index
            end
            line_index = line_index + 1
        elseif #indent == 0 then
            -- base case: no remaining indent after stripping — item belongs to our level
            count = count + 1
            if line_index ~= cursor_line then
                -- column in the original line = the characters we stripped
                vim.api.nvim_buf_set_extmark(buf, ns, line_index - 1, strip, {
                    virt_text = { { count .. ".", "@markup.list" } },
                    virt_text_pos = "overlay",
                })
            end
            line_index = line_index + 1
        else
            -- recursive case: still has indentation after stripping, go one level deeper
            -- resume from wherever the deeper call stopped
            line_index = render_block(buf, lines, line_index, indent_offset + 1, cursor_line, indent_size)
        end
    end

    return line_index
end

local function render(buf)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local cursor_line = vim.api.nvim_win_get_cursor(0)[1]

    -- indent_size is how many characters wide one indent level is.
    --
    -- expandtab=true  means the user indents with spaces, so one level = shiftwidth spaces.
    -- expandtab=false means the user indents with tab characters, so one level = 1 tab char.
    --
    -- shiftwidth=0 is a special Vim value meaning "same as tabstop", so we resolve
    -- it to tabstop before using it.
    local shiftwidth = vim.bo[buf].shiftwidth
    if shiftwidth == 0 then shiftwidth = vim.bo[buf].tabstop end
    local indent_size
    if vim.bo[buf].expandtab then
        indent_size = shiftwidth  -- e.g. 2 or 4 spaces per level
    else
        indent_size = 1           -- one tab character per level
    end

    -- kick off at line 1, indent level 0 (no indentation = top level)
    render_block(buf, lines, 1, 0, cursor_line, indent_size)
end

return { render = render }
