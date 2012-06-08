render = {}

-- Sort z-coordinate
function render:sort() 
    table.sort(self, function (a, b) return a.z < b.z end)
end

-- Adds Drawable object
function render:add(obj, x, y, z, brightness)
    local o = {inner = obj, x = x, y = y, z = z, bright = brightness}
    self[#self + 1] = o
end

-- Renders in correct order and with right brightness
function render:draw()
    self:sort()
    for i,v in ipairs(self) do
        -- doubleplusungood way to adjust brightness 
        gr.setColor(v.bright, v.bright, v.bright)
        gr.draw(v.inner, v.x, v.y)
        
        -- gr.setColorMode("modulate")
        -- gr.setBlendMode("multiplicative")
        -- gr.setColor(v.bright, v.bright, v.bright)
        -- w = v.inner:getWidth()
        -- h = v.inner:getHeight()
        -- gr.rectangle("fill", v.x, v.y, v.x + w - 1, v.y + h - 1)
    end
    self={}
end