render = {content = {}}

-- Sorts z-coordinate
function render:sort() 
    table.sort(self.content, function (a, b) return a.z < b.z end)
end

-- Adds Drawable object
function render:add(obj, minx, miny, z, brightness, sx, sy, r)
    assert(obj, "Draw object does not exist")
    assert(minx and miny and z, "Dimensions not given")
    local brightness = brightness or 255
    
    -- Bug: scales about center
    
    -- Scale images
    local sx = sx or 1.0
    local sy = sy or 1.0
    --[[w = w or obj:getWidth()
    h = h or obj:getHeight()
    if obj:typeOf("Image") then
        sx = w / obj:getWidth()
        sy = h / obj:getHeight()
    end]]--

    -- Rotation
    r = r or 0
    
    -- Move into centre
    -- ox = sx * obj:getWidth() / 2
    -- minx = minx + ox
    -- oy = sy * obj:getHeight() / 2
    -- miny = miny + oy
    
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