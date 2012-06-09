require 'field'
require 'object'

editor = {
    ox = 0, oy = 0,            -- offsets
    selectx = 0, selecty = 0,  -- selected field
    sobject = nil, dx = 0, dy = 0, -- selected object
    cell_types = {"NONE.png", "goal.png"},
}

editor.INC = 5.0

editor.keys = {
    RESET = 'r',
    LEFT = 'a',
    RIGHT = 'd',
    UP = 'w',
    DOWN = 's',
    WLEFT = 'left',
    WRIGHT = 'right',
    WUP = 'up',
    WDOWN = 'down',
    GOAL = 'g',
    CYCLE_CELL = 'return'
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

function editor:keyboard(key)
    if (key == self.keys.RESET) then
        ox = 0
        oy = 0
    elseif (key == self.keys.WLEFT) then
        field:get(self.selectx, self.selecty).colLeft = not field:get(self.selectx, self.selecty).colLeft
    elseif (key == self.keys.WRIGHT) then
        field:get(self.selectx + 1, self.selecty).colLeft = not field:get(self.selectx + 1, self.selecty).colLeft
    elseif (key == self.keys.WUP) then
        field:get(self.selectx, self.selecty).colTop = not field:get(self.selectx, self.selecty).colTop
    elseif (key == self.keys.WDOWN) then
        field:get(self.selectx, self.selecty + 1).colTop = not field:get(self.selectx, self.selecty + 1).colTop
    elseif (key == self.keys.CYCLE_CELL) then
        local cur = table.find(self.cell_types, field:get(self.selectx, self.selecty).background)
        local next = self.cell_types[cur % #self.cell_types + 1]
        field:get(self.selectx, self.selecty).background = next
    end
end

-- Mouse position to field position
function editor:mouseToField(x, y)
    return -self.ox + x / CELLSIZE, -self.oy + y / CELLSIZE
end

-- Get self.selected cell
function editor:getcell(x, y)
    local cx = math.floor(-self.ox + x / CELLSIZE)
    local cy = math.floor(-self.oy + y / CELLSIZE)
    return cx, cy
end

-- Select objects and fields
function editor:mousePressed(x, y, button)
    local mx, my = self:mouseToField(x, y)

    if button == "l" then
        -- Did we select an object?
        for i, o in pairs(objects) do
            if (math.abs(mx - o.cx) < o.xrad and math.abs(my - o.cy) < o.yrad) then
                print("FOUND", o.img)
                self.sobject = o
                self.dx = o.cx - mx
                self.dy = o.cy - my
                return
            end
        end
    
        --print(self:getcell(x, y))
        self.selectx, self.selecty = self:getcell(x, y)
    end
end

-- Move object
function editor:mouseMoved(x, y)
    print("Move")
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