require 'shortcut'

text = {lines_left = {}, lines_other = {}, fonts = {}}
text.FONT_SIZE = 12
text.LEADING = 1.2
text.OFF_X = 10
text.OFF_Y = 10

-- Get font of respective size
function text:getFont(size)
    if not self.fonts[size] then
        self.fonts[size] = gr.newFont(size)
    end
    
    return self.fonts[size]
end

function text:init()
    
end

-- Add text to render list
function text:print(str, x, y, size)
    if x and y then
        self.lines_other[#self.lines_other + 1] = {str = str, size = size or self.FONT_SIZE, x = x, y = y}
    else
        self.lines_left[#self.lines_left + 1] = {str = str, size = size or self.FONT_SIZE}
    end
end

function text:draw()
    -- Now print lines in given sizes
    local x = text.OFF_X
    local y = text.OFF_Y
    for i, v in ipairs(self.lines_left) do
        gr.setFont(self:getFont(v.size))
        gr.print(v.str, x, y)
        y = y + v.size * self.LEADING
    end
    
    -- Now print arbitrary lines
    for i, v in ipairs(self.lines_other) do
        gr.setFont(self:getFont(v.size))
        gr.print(v.str, v.x, v.y)
    end
    
    self.lines_left = {}
    self.lines_other = {}
end