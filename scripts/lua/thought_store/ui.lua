local M = {}
local storage = require('thought_store.storage')

-- Keep track of windows and current thought
M.content_win = nil
M.current_thought = nil

-- Helper function to find thought by title in display
local function find_thought_by_display_line(line, thoughts)
    if line:match("^%s*##%s+") then
        local display_title = line:match("^%s*##%s+(.+)$")
        for _, thought in ipairs(thoughts) do
            local metadata = thought.content:match("^%-%-%-\n(.-)\n%-%-%-\n")
            if metadata then
                local title = metadata:match("title:%s*([^\n]+)")
                if title == display_title then
                    return thought
                end
            end
        end
    end
    return nil
end

function M.open_browser()
    -- Create a new scratch buffer
    vim.cmd('enew')
    local buf = vim.api.nvim_get_current_buf()
    
    -- Set buffer options
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'filetype', 'thought-store')
    
    -- Get thoughts
    local thoughts = storage.get_thoughts()
    
    -- Group thoughts by category
    local categories = {}
    for _, thought in ipairs(thoughts) do
        categories[thought.category] = categories[thought.category] or {}
        table.insert(categories[thought.category], thought)
    end
    
    -- Prepare content
    local lines = {'# Thought Storage', '', ''}
    
    -- Sort categories
    local sorted_categories = {}
    for category in pairs(categories) do
        table.insert(sorted_categories, category)
    end
    table.sort(sorted_categories)
    
    -- Display thoughts by category
    for _, category in ipairs(sorted_categories) do
        table.insert(lines, string.format('# [%s]', category:upper()))
        table.insert(lines, '-----------------')
        table.insert(lines, '')
        
        for _, thought in ipairs(categories[category]) do
            -- Extract title and date from metadata
            local title = "Untitled"
            local date = thought.filename:match("^(%d%d%d%d%d%d%d%d)")
            if date then
                date = date:gsub("(%d%d%d%d)(%d%d)(%d%d)", "%1-%2-%3")
            end
            
            local metadata = thought.content:match("^%-%-%-\n(.-)\n%-%-%-\n")
            if metadata then
                title = metadata:match("title:%s*([^\n]+)") or "Untitled"
            end
            
            table.insert(lines, string.format("## %s", title))
            table.insert(lines, string.format("   %s", date))
            table.insert(lines, "")
        end
    end
    
    -- Set content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    
    -- Store the main window id
    local main_win = vim.api.nvim_get_current_win()
    
    -- Enter to view/edit thought
    vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', '', {
        callback = function()
            local cursor = vim.api.nvim_win_get_cursor(0)[1]
            local line = vim.api.nvim_buf_get_lines(buf, cursor - 1, cursor, false)[1]
            
            local thought = find_thought_by_display_line(line, thoughts)
            if thought then
                M.current_thought = thought
                
                -- Create or reuse split
                if not M.content_win or not vim.api.nvim_win_is_valid(M.content_win) then
                    -- Create split on the right
                    vim.cmd('botright vsplit')
                    M.content_win = vim.api.nvim_get_current_win()
                end
                
                -- Switch to content window
                vim.api.nvim_set_current_win(M.content_win)
                
                -- Create new buffer for content
                vim.cmd('enew')
                local content_buf = vim.api.nvim_get_current_buf()
                
                -- Set buffer options
                vim.api.nvim_buf_set_option(content_buf, 'buftype', 'nofile')
                vim.api.nvim_buf_set_option(content_buf, 'swapfile', false)
                vim.api.nvim_buf_set_option(content_buf, 'bufhidden', 'wipe')
                vim.api.nvim_buf_set_option(content_buf, 'filetype', 'markdown')
                
                -- Set content
                local content_lines = vim.split(thought.content, '\n')
                vim.api.nvim_buf_set_lines(content_buf, 0, -1, false, content_lines)
                
                -- Set up buffer for editing
                vim.api.nvim_buf_set_option(content_buf, 'modifiable', true)
                vim.api.nvim_buf_set_option(content_buf, 'readonly', false)
                
                -- Add save mapping for content buffer
                vim.api.nvim_buf_set_keymap(content_buf, 'n', '<leader>w', '', {
                    callback = function()
                        local updated_content = vim.api.nvim_buf_get_lines(content_buf, 0, -1, false)
                        local success = storage.update_thought(M.current_thought.filepath, table.concat(updated_content, '\n'))
                        if success then
                            vim.notify('Thought updated!', vim.log.levels.INFO)
                        else
                            vim.notify('Failed to update thought!', vim.log.levels.ERROR)
                        end
                    end,
                    noremap = true,
                    silent = true
                })
                
                -- Return focus to main window
                vim.api.nvim_set_current_win(main_win)
            end
        end,
        noremap = true,
        silent = true
    })
    
    -- d to delete thought
    vim.api.nvim_buf_set_keymap(buf, 'n', 'd', '', {
        callback = function()
            local cursor = vim.api.nvim_win_get_cursor(0)[1]
            local line = vim.api.nvim_buf_get_lines(buf, cursor - 1, cursor, false)[1]
            
            local thought = find_thought_by_display_line(line, thoughts)
            if thought then
                -- Confirm deletion
                vim.ui.input({
                    prompt = "Delete this thought? (y/N): ",
                }, function(input)
                    if input and input:lower() == 'y' then
                        if storage.delete_thought(thought.filepath) then
                            -- Close content window if it's showing this thought
                            if M.current_thought and M.current_thought.filepath == thought.filepath then
                                if M.content_win and vim.api.nvim_win_is_valid(M.content_win) then
                                    vim.api.nvim_win_close(M.content_win, true)
                                end
                            end
                            
                            -- Refresh the browser
                            M.open_browser()
                            vim.notify("Thought deleted", vim.log.levels.INFO)
                        end
                    end
                end)
            end
        end,
        noremap = true,
        silent = true
    })
    
    -- q to quit
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '', {
        callback = function()
            if M.content_win and vim.api.nvim_win_is_valid(M.content_win) then
                vim.api.nvim_win_close(M.content_win, true)
            end
            vim.cmd('q')
        end,
        noremap = true,
        silent = true
    })
    
    -- Make buffer readonly
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

return M
