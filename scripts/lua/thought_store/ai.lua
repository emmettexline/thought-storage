local M = {}

function M.get_title_and_category(text, existing_categories)
    -- Build the prompt with instructions for both title and category
    local prompt = string.format([[You are a simple categorization system. You must respond in this exact format, using exactly these two lines with these exact prefixes - no other text allowed:

TITLE: (write 3-5 descriptive words here)
CATEGORY: (write single category word here)

Text to categorize:
%s

%s]], 
        text,
        existing_categories and #existing_categories > 0 
            and string.format("\nExisting categories you can use: %s", table.concat(existing_categories, ", "))
            or "")
    
    -- Create the JSON payload
    local payload = vim.json.encode({
        model = "llama3.2",
        prompt = prompt,
        stream = false
    })
    
    -- Escape single quotes for shell
    payload = payload:gsub("'", "'\\''")
    
    -- Construct curl command
    local curl_command = string.format(
        "curl -s -X POST 'http://localhost:11434/api/generate' -H 'Content-Type: application/json' -d '%s'",
        payload
    )
    
    -- Execute the command
    vim.notify("Processing thought...", vim.log.levels.INFO)
    local handle = io.popen(curl_command)
    if not handle then
        vim.notify("Failed to connect to Ollama", vim.log.levels.ERROR)
        return "untitled", "uncategorized"
    end
    
    local result = handle:read("*a")
    handle:close()
    
    if not result or result == "" then
        vim.notify("No response from Ollama", vim.log.levels.ERROR)
        return "untitled", "uncategorized"
    end
    
    local ok, parsed = pcall(vim.json.decode, result)
    if not ok then
        vim.notify("Failed to parse JSON: " .. result, vim.log.levels.ERROR)
        return "untitled", "uncategorized"
    end
    
    if not parsed or not parsed.response then
        vim.notify("Invalid response format", vim.log.levels.ERROR)
        return "untitled", "uncategorized"
    end
    
    -- Parse the response for title and category
    local response = parsed.response:gsub("\r", "")  -- Remove any carriage returns
    
    -- Look for exact matches including the prefix
    local title = response:match("TITLE:%s*([^\n]+)")
    local category = response:match("CATEGORY:%s*([^\n]+)")
    
    -- If we don't find the exact format, try to use the first two lines
    if not title or not category then
        local lines = {}
        for line in response:gmatch("[^\n]+") do
            table.insert(lines, line)
        end
        if #lines >= 2 then
            title = lines[1]
            category = lines[2]
        end
    end
    
    -- Show what we're working with
    vim.notify(string.format("Found - Title: '%s', Category: '%s'", 
        title or "not found", category or "not found"), vim.log.levels.INFO)
    
    if not title or not category then
        return "untitled", "uncategorized"
    end
    
    -- Clean up the title (remove special chars but keep spaces)
    title = title:gsub("[^%w%s-]", ""):gsub("%s+", "-"):lower()
    
    -- Clean up the category
    category = category:gsub("[^%w]", ""):lower()
    
    -- Final validation
    if title == "" then title = "untitled" end
    if category == "" then category = "uncategorized" end
    
    return title, category
end

return M
