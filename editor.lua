require 'field'

editor = {
    ox = 0, oy = 0, -- offsets
    selectx = 0, selecty = 0,
    types = {"NONE.png", "goal.png"},
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
        local cur = table.find(self.types, field:get(self.selectx, self.selecty).background)
        local next = self.types[cur % #self.types + 1]
        field:get(self.selectx, self.selecty).background = next
    end
end

-- Get self.selected cell
function editor:getcell(x, y)
    local cx = math.floor(-self.ox + x / CELLSIZE)
    local cy = math.floor(-self.oy + y / CELLSIZE)
    return cx, cy
end

-- self.select field
function editor:mouse(x, y, button)
    if button == "l" then
        --print(self:getcell(x, y))
        self.selectx, self.selecty = self:getcell(x, y)
    end
end

-- Draw fields
function editor:shade()
    field:shadeEditor(CELLSIZE * self.ox, CELLSIZE * self.oy, self.selectx, self.selecty)
end