require 'field'
require 'object'

editor = {
    ox = 0, oy = 0,            -- offsets
    selectx = 0, selecty = 0,  -- selected field
    sobject = nil, dx = 0, dy = 0, -- selected object
    cell_types = {"NONE.png", "goal.png"},
    
    -- Hack extra object names
    object_types = {function() return rigidbody(0, 0, 0.125, 0.125, "crate.png", 50, 0, 0, 1, DOWN) end, 
                    function() return rigidbody(0, 0, 0.25, 0.25, "player.png", 999, 0, 0, 2, DOWN) end}, 
    object_names = {"crate.png", "player.png"}
} 

editor.INC = 5.0

editor.keys = {
    RESET = 'r',
    LEFT = 'a', RIGHT = 'd', UP = 'w', DOWN = 's',
    WLEFT = 'left', WRIGHT = 'right', WUP = 'up', WDOWN = 'down',
    CYCLE = 'return', PLACE = 'p', REMOVE = 'o'
}

-- Move view
function editor:update(dt) 
    if (kb.isDown(self.keys.LEFT)) then
        self.ox = self.ox + self.INC * dt
    elseif (kb.isDown(self.keys.RIGHT)) then
        self.ox = self.ox - self.INC * dt
    elseif (kb.isDown(self.keys.UP)) then
        self.oy = self.oy + self.INC * dt
    elseif (kb.isDown(self.keys.DOWN)) then
        self.oy = self.oy - self.INC * dt
    end
end

-- Mouse position to field position
function editor:mouseToField(x, y)
    return -self.ox + x / CELLSIZE, -self.oy + y / CELLSIZE
end

-- Get object at mouse
function editor:getObject()
    local mx, my = self:mouseToField(mouse.getX(), mouse.getY())

    for i, o in pairs(objects) do
        -- Hack...
        if (math.abs(mx - o.cx) < o.xrad and math.abs(my - o.cy) < o.yrad and o.img ~= "star.png") then
            self.sobject = o
            self.dx = o.cx - mx
            self.dy = o.cy - my
            return o
        end
    end
end

-- Get cell at mouse
function editor:getCell()
    local mx, my = self:mouseToField(mouse.getX(), mouse.getY())

    local cx = math.floor(mx)
    local cy = math.floor(my)
    return cx, cy
end


-- All kinds of stuff
function editor:keyboard(key)
    if (key == self.keys.RESET) then
        ox = 0
        oy = 0
    elseif (key == self.keys.WLEFT) then
        field:toggleWall(self.selectx, self.selecty, LEFT)
    elseif (key == self.keys.WRIGHT) then
        field:toggleWall(self.selectx, self.selecty, RIGHT)
    elseif (key == self.keys.WUP) then
        field:toggleWall(self.selectx, self.selecty, UP)
    elseif (key == self.keys.WDOWN) then
        field:toggleWall(self.selectx, self.selecty, DOWN)
    elseif (key == self.keys.CYCLE) then
        local o = self:getObject()
        
        if (o) then
            -- Hack
            -- Change object type
            local cur = table.find(self.object_names, o.img)
            local next = self.object_types[cur % #self.object_types + 1]()
            next.cx = o.cx
            next.cy = o.cy
            
            local idx = table.find(objects, o)
            objects[idx] = next
        else
            local cur = table.find(self.cell_types, field:get(self.selectx, self.selecty).background)
            local next = self.cell_types[cur % #self.cell_types + 1]
            field:get(self.selectx, self.selecty).background = next
        end
    elseif (key == self.keys.PLACE) then
        -- Place object
        local mx, my = self:mouseToField(mouse.getX(), mouse.getY())
        objects[#objects + 1] = self.object_types[1]()
        objects[#objects].cx = mx
        objects[#objects].cy = my
    elseif (key == self.keys.REMOVE) then
        local o = self:getObject()
        if (o) then
            table.remove(objects, table.find(objects, o))
        end
    end
end

-- Select objects and fields
function editor:mousePressed(x, y, button)
    local mx, my = self:mouseToField(x, y)

    if button == "l" then
        -- Did we select an object?
        self.sobject = self:getObject()
        if (self.sobject) then 
            return
        end
    
        self.selectx, self.selecty = self:getCell()
    end
end

-- Move object
function editor:mouseMoved(x, y)
    local mx, my = self:mouseToField(x, y)
    if (self.sobject) then
        self.sobject.cx = mx + self.dx
        self.sobject.cy = my + self.dy
    end
end 

function editor:mouseReleased(x, y, button)
    self.sobject = nil
end 

-- Draw fields
function editor:shade()
    field:shadeEditor(CELLSIZE * self.ox, CELLSIZE * self.oy, self.selectx, self.selecty)
end