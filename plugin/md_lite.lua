local md_lite = require("md_lite")

vim.api.nvim_create_autocmd({ "BufWinEnter", "TextChanged" }, {
    pattern = "*.md",
    callback = function() 
        md_lite.render(vim.api.nvim_get_current_buf()) 
    end
})

local last_line

vim.api.nvim_create_autocmd("CursorMoved", {
    pattern = "*.md",
    callback = function()
        local line = vim.api.nvim_win_get_cursor(0)[1]
        if line == last_line then return end -- column move, skip
        last_line = line
        md_lite.render(vim.api.nvim_get_current_buf())
    end
})
