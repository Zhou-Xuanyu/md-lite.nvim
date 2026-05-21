local md_lite = require("md_lite")

vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "InsertLeave", "CursorMoved" }, {
    pattern = "*.md",
    callback = function()
        md_lite.render(vim.api.nvim_get_current_buf())
    end,
})
