require 'shortcut'

text = {lines = {}, fonts = {}}
text.FONT_SIZE = 12
text.FONT_COLOR = {255, 255, 255, 255}
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
function text:print(str, x, y, size, color)
    -- 2-parameter version
    local size = size
    if x and not y then
        size = x
    end

    self.lines[#self.lines + 1] = {
        str = str, size = size or self.FONT_SIZE, 
        x = x, y = y, 
        color = color or self.FONT_COLOR
    }
end

function text:draw()
    -- Now print lines in given sizes
    local x = text.OFF_X
    local y = text.OFF_Y
    
    pr, pg, pb, pa = gr.getColor()
    for i, v in ipairs(self.lines) do
        gr.setFont(self:getFont(v.size))
        gr.setColor(v.color)
        if (v.x and v.y) then 
            gr.print(v.str, v.x, v.y)
        else
            gr.print(v.str, x, y)
            y = y + v.size * self.LEADING
        end
    end
    gr.setColor(pr, pg, pb, pa)
    
    self.lines = {}
end