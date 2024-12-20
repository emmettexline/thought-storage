local M = {}
local ai = require('thought_store.ai')

-- Get all existing categories
function M.get_categories()
    local thoughts = M.get_thoughts()
    local categories = {}
    for _, thought in ipairs(thoughts) do
        categories[thought.category] = true
    end
    
    local category_list = {}
    for category in pairs(categories) do
        table.insert(category_list, category)
    end
    return category_list
end

-- Save a thought to a file
function M.save_thought(content)
    -- Get existing categories (excluding 'uncategorized')
    local categories = {}
    local all_cats = M.get_categories()
    for _, cat in ipairs(all_cats) do
        if cat ~= "uncategorized" then
            table.insert(categories, cat)
        end
    end
    
    -- Get title and category from AI
    local title, category = ai.get_title_and_category(content, categories)
    
    -- Generate timestamp for metadata
    local timestamp = os.date('%Y-%m-%d %H:%M:%S')
    
    -- Create filename using title and date
    local date_stamp = os.date('%Y%m%d')
    local filename = string.format("%s_%s.md", date_stamp, title)
    
    -- Get storage path from main module
    local storage_path = require('thought_store').options.storage_path
    local filepath = storage_path .. '/' .. filename
    
    -- Create markdown content with metadata
    local metadata = string.format([[---
title: %s
date: %s
category: %s
---

%s]], title:gsub("-", " "), timestamp, category, content)
    
    -- Write to file
    local file = io.open(filepath, 'w')
    if file then
        file:write(metadata)
        file:close()
        vim.notify(string.format('Thought saved as "%s" in category: %s', title, category), vim.log.levels.INFO)
        return true
    end
    return false
end

-- Update an existing thought
function M.update_thought(filepath, content)
    local file = io.open(filepath, 'w')
    if file then
        file:write(content)
        file:close()
        return true
    end
    return false
end

-- Delete a thought
function M.delete_thought(filepath)
    -- Remove the file
    local success, err = os.remove(filepath)
    if success then
        return true
    end
    vim.notify("Failed to delete thought: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return false
end

-- Get all thoughts
function M.get_thoughts()
    local storage_path = require('thought_store').options.storage_path
    local thoughts = {}
    
    for filename in vim.fs.dir(storage_path) do
        if filename:match('%.md$') then
            local filepath = storage_path .. '/' .. filename
            local file = io.open(filepath, 'r')
            if file then
                local content = file:read('*all')
                file:close()

                -- Extract metadata
                local category = "uncategorized"
                local title = "Untitled"
                local metadata = content:match("^%-%-%-\n(.-)\n%-%-%-\n")
                if metadata then
                    category = metadata:match("category:%s*([^\n]+)")
                    title = metadata:match("title:%s*([^\n]+)")
                end

                table.insert(thoughts, {
                    filename = filename,
                    filepath = filepath,
                    content = content,
                    title = title or "Untitled",
                    category = category or "uncategorized"
                })
            end
        end
    end
    
    -- Sort by filename (timestamp) in reverse order
    table.sort(thoughts, function(a, b)
        return a.filename > b.filename
    end)
    
    return thoughts
end

return M
