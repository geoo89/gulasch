require 'field'
require 'object'

editor = {
    ox = 0, oy = 0,            -- offsets
    selectx = 0, selecty = 0,  -- selected field
    sobject = nil, dx = 0, dy = 0, -- selected object
    cell_types = {"NONE.png", "goal.png"},
    half_open = nil,
    level_list = {},
    level_idx = 1,
    
    object_types = {function() return rigidbody(0, 0, 0.125, 0.125, "crate.png", 50, 0, 0, 1, DOWN) end, 
                    function() return rigidbody(0, 0, 0.25, 0.25, "player.png", 999, 0, 0, 2, DOWN) end}, 
    object_names = {"crate.png"},
    wall = LEFT
} 

editor.INC = 5.0
editor.FILE_NAME = 'levels.txt'
editor.LEVEL_DIR = 'levels/'

editor.keys = {
    RESET = 'r',
    LEFT = 'a', RIGHT = 'd', UP = 'w', DOWN = 's',
    WLEFT = 'left', WRIGHT = 'right', WUP = 'up', WDOWN = 'down',
    CYCLE = 'return', PLACE = 'i', REMOVE = 'p', PORTAL = 'lctrl', PORTAL_CHOOSE = 'lalt',
    LEVEL_PLUS = 'f9', LEVEL_MINUS = 'f10', LEVEL_SAVE = 'f5'
}

-- Set level to self.file_idx
function editor:loadLevel()
    print("Loading level " .. self.LEVEL_DIR .. self.level_list[self.level_idx]) 
    import(self.LEVEL_DIR .. self.level_list[self.level_idx])
end

-- Save current level
function editor:saveLevel()
    print("Saving level " .. self.LEVEL_DIR .. self.level_list[self.level_idx]) 
    field:export(self.LEVEL_DIR .. self.level_list[self.level_idx])
end

-- Initialise editor --> load file list
function editor:init()
    local file, msg = io.open(self.FILE_NAME)
    if (not file) then
        error("Could not open level list: " .. msg)
        os.exit(1)
    end
    
    for line in file:lines() do
        print("Level found: " .. self.LEVEL_DIR .. line)
        self.level_list[#self.level_list + 1] = line
        print(#self.level_list)
    end
    
    self:loadLevel()
    io.close(file)
end

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

-- Toggle wall
function editor:toggleWall(dir)
    field:toggleWall(self.selectx, self.selecty, dir)
end

-- Set portal
function editor:setPortal(dir) 
    if (self.half_open) then
        field:openPortal(self.half_open.xin, self.half_open.yin, self.selectx, self.selecty,
                         self.half_open.side, DOWN, dir, DOWN)
        self.half_open = nil
    else
        self.half_open = {}
        self.half_open.xin = self.selectx
        self.half_open.yin = self.selecty
        self.half_open.side = dir
    end
end

-- Toggle portal
function editor:togglePortal(dir)
    field:togglePortal(self.selectx, self.selecty, dir)
end

-- All kinds of stuff
function editor:keyboard(key)
    if (key == self.keys.RESET) then
        self.ox = 0
        self.oy = 0
    elseif (key == self.keys.WLEFT) then
        if (kb.isDown(self.keys.PORTAL)) then
            self:setPortal(LEFT)
        elseif (kb.isDown(self.keys.PORTAL_CHOOSE)) then
            self:togglePortal(LEFT)
        else 
            self:toggleWall(LEFT)
        end
    elseif (key == self.keys.WRIGHT) then
        if (kb.isDown(self.keys.PORTAL)) then
            self:setPortal(RIGHT)
        elseif (kb.isDown(self.keys.PORTAL_CHOOSE)) then
            self:togglePortal(RIGHT)
        else 
            self:toggleWall(RIGHT)
        end
    elseif (key == self.keys.WUP) then
        if (kb.isDown(self.keys.PORTAL)) then
            self:setPortal(UP)
        elseif (kb.isDown(self.keys.PORTAL_CHOOSE)) then
            self:togglePortal(UP)
        else 
            self:toggleWall(UP)
        end
    elseif (key == self.keys.WDOWN) then
        if (kb.isDown(self.keys.PORTAL)) then
            self:setPortal(LEFT)
        elseif (kb.isDown(self.keys.PORTAL_CHOOSE)) then
            self:togglePortal(LEFT)
        else 
            self:toggleWall(LEFT)
        end
    elseif (key == self.keys.LEVEL_PLUS) then
        self.level_idx = self.level_idx % #self.level_list + 1
        self:loadLevel()
    elseif (key == self.keys.LEVEL_MINUS) then
        self.level_idx = (self.level_idx + #self.level_list - 2) % #self.level_list + 1
        self:loadLevel()
    elseif (key == self.keys.LEVEL_SAVE) then
        self:saveLevel()
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
        if (o and o ~= player) then
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
        print("Selected cell: " .. self.selectx .. ", " .. self.selecty)
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
    field:shadeEditor(CELLSIZE * self.ox, CELLSIZE * self.oy, self.selectx, self.selecty, half_open)
end