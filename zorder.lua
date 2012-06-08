-- z-order
objs = {}

function objs:sort() 
    table.sort(self, function (a, b) return a.z < b.z end)
end

-- adds Drawable object
function objs:add(obj, x, y, z) 
    --[[o = setmetatable({}, {
        __index = function(x, k)
            print(type(x.inner[k]))
            return x.inner[k]
        end
    }) ]]--
    o = {}
    o.inner = obj
    function o:set(x, y, z) 
        self.x = x or self.x
        self.y = y or self.y
        
        if z then
            self.z = z
            objs:sort() -- HACK
        end
    end   
    function o:get() 
        return self.x, self.y, self.z
    end
    o:set(x, y, z)

    self[#objs + 1] = o
    self:sort()
    
    return o
end

function objs:draw()
    for i,v in ipairs(self) do
        gr.draw(v.inner, v.x, v.y)
    end
end