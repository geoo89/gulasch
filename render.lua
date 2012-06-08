render = {content = {}}

-- Sorts z-coordinate
function render:sort() 
    table.sort(self.content, function (a, b) return a.z < b.z end)
end

-- Adds Drawable object
function render:add(obj, minx, miny, z, brightness, maxx, maxy, r)
    assert(obj, "Draw object does not exist")
    assert(minx and miny and z, "Dimensions not given")
    local brightness = brightness or 255
    
    -- Scale images
    local sx = 1.0
    local sy = 1.0
    if obj:typeOf("Image") and maxx and maxy then
        sx = (maxx - minx + 1) / obj:getWidth()
        sy = (maxy - miny + 1) / obj:getHeight()
    end

    r = r or 0
    
    local o = {inner = obj, x = minx, y = miny, z = z, bright = brightness, sx = sx, sy = sy, r = r}
    
    self.content[#self.content + 1] = o
end

-- Renders in correct order and with right brightness
function render:draw()
    self:sort()
    
    pr, pg, pb, pa = gr.getColor()
    for i,v in ipairs(self.content) do
        -- doubleplusungood way to adjust brightness 
        gr.setColor(v.bright, v.bright, v.bright)
        gr.draw(v.inner, v.x, v.y, v.r, v.sx, v.sy)
    end
    gr.setColor(pr, pg, pb, pa)

    self.content = {}
end