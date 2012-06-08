render = {}

-- Sort z-coordinate
function render:sort() 
    table.sort(self, function (a, b) return a.z < b.z end)
end

-- Adds Drawable object
function render:add(img, x, y, z, brightness)
    local o = {inner = img, x = x, y = y, z = z, bright = brightness}
    self[#self + 1] = o
end

-- Renders in correct order
function render:draw()
    self:sort()
    for i,v in ipairs(self) do
        gr.draw(v.inner, v.x, v.y)
    end
    self={}
end