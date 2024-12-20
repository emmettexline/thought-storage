local M = {}
local storage = require('thought_store.storage')
local ui = require('thought_store.ui')

-- Setup function to initialize the plugin
function M.setup(opts)
    opts = opts or {}
    -- Set default storage path in user's config directory
    opts.storage_path = opts.storage_path or vim.fn.stdpath('data') .. '/thought_store'
    
    -- Create storage directory if it doesn't exist
    vim.fn.mkdir(opts.storage_path, 'p')
    
    -- Store options globally
    M.options = opts
end

-- Save thought command implementation
function M.save_thought()
    -- Get current buffer content
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local content = table.concat(lines, '\n')
    
    -- Save the thought
    storage.save_thought(content)
    
    -- Notify user
    vim.notify('Thought saved!', vim.log.levels.INFO)
end

-- Browse command implementation
function M.browse()
    ui.open_browser()
end

return M
