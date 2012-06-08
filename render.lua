render = {content = {}}

-- Sorts z-coordinate
function render:sort() 
    table.sort(self, function (a, b) return a.z < b.z end)
end

-- Adds Drawable object
function render:add(obj, x, y, z, brightness)
    local o = {inner = obj, x = x, y = y, z = z, bright = brightness}
    self.content[#self.content + 1] = o
end

-- Renders in correct order and with right brightness
function render:draw()
    self:sort()
    
    pr, pg, pb, pa = gr.getColor()
    for i,v in ipairs(self.content) do
        -- doubleplusungood way to adjust brightness 
        gr.setColor(v.bright, v.bright, v.bright)
        gr.draw(v.inner, v.x, v.y)
    end
    gr.setColor(pr, pg, pb, pa)

    self.content = {}
end