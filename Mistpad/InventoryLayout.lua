local _, M = ...
M.BagLayout = {}
function M.BagLayout.Calculate(size, screenWidth, screenHeight, slots, extraFooter, settings)
    local cell, gap, padding, header, footer = 48, 4, 16, 106, 42
    if settings then
        cell = math.max(32, math.min(80, tonumber(settings.itemSize) or 48))
        header = settings.searchBar and 96 or 64
    end
    footer = footer + (extraFooter or 0)
    local pitch = cell + gap
    local maxWidth = math.max(1, screenWidth - 48)
    local columns = size == "small" and 4 or size == "medium" and 8 or
        math.max(1, math.floor((maxWidth - padding * 2 + gap) / pitch))
    local width = size == "large" and maxWidth or columns * pitch - gap + padding * 2
    local rows = math.max(settings and settings.dynamicContents and 0 or 1, math.ceil(slots / columns))
    local maxHeight = math.max(header + footer + cell, screenHeight - 96)
    local visibleRows = math.min(rows, math.max(1, math.floor((maxHeight - header - footer + gap) / pitch)))
    if settings then visibleRows = math.min(visibleRows, math.max(1, math.floor(tonumber(settings.maxRows) or 8))) end
    local viewport = math.max(1, visibleRows * pitch - gap)
    return {columns = columns, cell = cell, gap = gap, pitch = pitch, padding = padding,
        header = header, footer = footer, width = width, height = header + footer + viewport,
        viewport = viewport, contentHeight = math.max(1, rows * pitch - gap),
        contentWidth = columns * pitch - gap, rows = rows}
end

function M.BagLayout.Anchor(settings, ratio)
    ratio = ratio or 1
    if settings.bagAnchor == "left" then return "BOTTOMLEFT", 24 / ratio end
    if settings.bagAnchor == "right" then return "BOTTOMRIGHT", -24 / ratio end
    return "BOTTOM", 0
end
