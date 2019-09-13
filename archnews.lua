
local https = require("ssl.https")

-- TINY FETCH GET IMPLEMENTATION
local fetch = function(url)
    local body, code, headers, status = https.request(url)
    return body
end

local data = fetch("https://www.archlinux.org/feeds/news/")
local currentPosition = 1
local report = {}
local reportIndex = 1

-- FINDS THE (POSSIBLE) BEGINNING OF THE NEXT TAG, RETURNS FALSE IF NO TAG FOUND
local gotoNextTag = function()
    for index = currentPosition, #data, 1 do
        if data:sub(index, index) == "<" then 
            do
                currentPosition = index
                return true
            end
        end
    end
    return false
end

-- MOVES TO BEYOND THE (POSSIBLE) END OF THE TAG
local goToEndOfTag = function()
    for index = currentPosition + 1, #data, 1 
        do
            if data:sub(index, index) == ">" then 
                do
                    currentPosition = index + 1
                return
            end
        end
    end
end

-- PASS A TAGNAME AND IT WILL RETURN ITS CONTENTS, AND CHANGE THE INDEX
local getContents = function(tagName)
    -- MOVE TO THE BEGINNING OF THE CONTENTS
    for index = currentPosition, #data, 1 do
        if data:sub(index, index + #tagName) == "<" .. tagName then 
            do
                goToEndOfTag()
                break
            end
        end
    end
    -- GET CONTENTS AND MOVE PAST END OF TAG
    for index = currentPosition, #data, 1 do
        if data:sub(index, index + #tagName + 1) == "</" .. tagName then 
            do
                local contents = data:sub(currentPosition, index -1)
                goToEndOfTag()
                return contents
            end
        end
    end
end

-- EXTRACT ITEM DATA
local processItem = function()
    goToEndOfTag();
    for index = currentPosition, #data, 1 do
        if data:sub(index, index + 6) == "</item>" then 
            do
                -- EXTRACTING ALL DATA
                local title = getContents("title")
                local link = getContents("link")
                local description = getContents("description")
                -- SKIPPING
                getContents("dc:creator")
                local date = getContents("pubDate")
                -- SKIPPING
                getContents("guid")

                title = title:gsub("&gt;", ">")
                description = description:gsub("&gt;", ">")
                description = description:gsub("&lt;", "<")

                report[reportIndex] = {
                    title = title,
                    link = link,
                    description = description,
                    date = date
                }
                reportIndex = reportIndex + 1
                goToEndOfTag()
                return
            end
        end
    end
end

local get = function()
    local itemsToGet = #data
    while currentPosition < itemsToGet 
        do
            gotoNextTag()
            if data:sub(currentPosition + 1, currentPosition + 4) == "item" then processItem() end
            currentPosition = currentPosition + 1
        end
    return report
end

return get
