require 'shortcut'

text = {lines = {}}
text.FONT_SIZE = 12
text.LEADING = 1.2
text.OFF_X = 10
text.OFF_Y = 10

function text:init()
    gr.setFont(gr.newFont(self.FONT_SIZE))
end

-- Add text to render list
function text:print(str, size)
    self.lines[#self.lines + 1] = {str = str, size = size or self.FONT_SIZE}
end

function text:draw()
    -- Now print lines in given sizes
    local x = text.OFF_X
    local y = text.OFF_Y
    for i, v in ipairs(self.lines) do
        gr.print(v.str, x, y, 0, v.size / self.FONT_SIZE)
        y = y + v.size * self.LEADING
    end
    self.lines = {}
end