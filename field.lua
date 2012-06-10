TOP   =  1
UP    =  TOP
BOTTOM= -1
DOWN  = BOTTOM
LEFT  =  2
RIGHT = -2

DIRS = { UP, DOWN, LEFT, RIGHT }

CELLSIZE = 128
WALLSIZE =   8
WALLPERC =  WALLSIZE / CELLSIZE
PRIO_BACK =   10
PRIO_WALL =  300
PRIO_PORTAL = 400
MARKER_PRIO = 900
SIGHT_RANGE = 4
PORTAL_FONT_SIZE = 30

DEFAULT_WIDTH = 64
DEFAULT_HEIGHT = 32

function transformOffset(x,y,downdir,rightdir)
    assertValidDir(rightdir)
    assertValidDir(downdir)
    assert(downdir ~= rightdir and downdir ~= -rightdir)
   
    if(downdir == DOWN) then
        x = rightdir == RIGHT and x or 1 - x
    elseif(downdir == UP) then
        y = 1 - y
        x = rightdir == RIGHT and x or 1 - x
    elseif(downdir == RIGHT) then
        if (rightdir == UP) then
            x, y = y, 1-x
        else
            x, y = y, x
        end
    else
        assert(downdir == LEFT)
       
        if(rightdir == DOWN) then
            x, y = 1-y, x
        else
            x, y = 1 - y, 1 - x
        end
    end
    return x,y
end

function drawTileInCell(cellx,celly,xmin,ymin,xmax,ymax,img,downdir,rightdir,brightness,zprio, objgrav,objmirr)
    objgrav = objgrav or DOWN
    objmirr = objmirr or false

    if not img or img == "" then
        return
    end
    
    local dimx = (xmax - xmin) * CELLSIZE
    local dimy = (ymax - ymin) * CELLSIZE
    xmin,ymin = transformOffset(xmin,ymin,downdir,rightdir)
    xmax,ymax = transformOffset(xmax,ymax,downdir,rightdir)
    
    --Now I have the actual screen position the top left corner of the image is mapped to
    local sx = nextdir(downdir) == rightdir and 1 or -1
    if(objmirr) then sx = -sx end
    
    physminx = cellx + CELLSIZE * math.min(xmin,xmax)
    physminy = celly + CELLSIZE * math.min(ymin,ymax)
    
    local angle -- (* PI/2)
    if (downdir == DOWN) then
        angle = 0
    elseif (downdir == UP) then
        angle = 2
    elseif (downdir == RIGHT) then
        angle = 3
    else
        angle = 1
    end
    
    while(objgrav ~= DOWN) do
        objgrav = nextdir(objgrav)
        angle = (angle + 1) % 4
    end
    
    if sx == 1 then
        if (angle == 3) then
            physminy = physminy + dimx
        elseif (angle == 2) then
            physminx = physminx + dimx
            physminy = physminy + dimy
        elseif (angle == 1) then
            physminx = physminx + dimy
        end
    else
        if (angle == 2) then
            physminy = physminy + dimy
        elseif (angle == 1) then
            physminy = physminy + dimx
            physminx = physminx + dimy
        elseif (angle == 0) then
            physminx = physminx + dimx
        end
    end
        
    angle = angle * math.pi / 2;
    
    --print(img, " px", physminx, " py", physminy, " z", zprio, " br", brightness, " ", sx, " ", 1, " ang", angle)
    render:add(textures[img], physminx, physminy, zprio, brightness, sx, 1, angle)
end

cellCount = 0

function DefaultCell()
    local cell = {}
    cell.background = "NONE.png";
    cell.colTop    = false
    cell.colLeft   = false
    cell.portals = {};
    cell.objects = {};
    cellCount = cellCount + 1
    cell.counter = cellCount    
    return cell;
end

function Portal()
    local portal = {}
    --[[properties:
        xout,yout,
        sideout
        upin,upout]]
    return portal;
end

function assertValidDir(dir)
    assert(dir == LEFT or dir == RIGHT or dir == UP or dir == DOWN, "Invalid direction: "..dir)
end

function dirtodxy(dir)
    assertValidDir(dir)
    if (dir == LEFT) then
        return -1,0
    elseif (dir == RIGHT) then
        return 1,0
    elseif (dir == TOP) then
        return 0,-1
    elseif (dir == BOTTOM) then
        return 0,1
    end
end

function dirToStr(dir)
    assertValidDir(dir)
    if(dir == UP) then return "UP"
    elseif(dir == DOWN) then return "DOWN"
    elseif(dir == LEFT) then return "LEFT"
    else return "RIGHT" end
end

function dirFromStr(dirstr)
    if(dirstr == "UP") then
        return UP
    elseif(dirstr == "DOWN") then
        return DOWN
    elseif(dirstr == "LEFT") then
        return LEFT
    elseif(dirstr == "RIGHT") then
        return RIGHT
    end
    
    error("dirFromStr: Invalid direction string ("..dirstr..")")
end

function dxytodir(dx,dy)
    if (dx == 1) then
        return RIGHT
    elseif (dx == -1) then
        return LEFT
    elseif (dy == 1) then
        return BOTTOM
    elseif (dy == -1) then
        return TOP
    else
        assert(false, "dxyToDir: SHITTY INPUT");
    end
end

function invertPair(dirdown,dirright)
    local downarrow
    local rightarrow
    
    if (dirdown == DOWN or dirdown == UP) then
        downarrow = dirdown
        rightarrow = dirright
    else
        downarrow  = dirright == DOWN and RIGHT or LEFT
        rightarrow = dirdown == RIGHT and DOWN  or UP
    end
    
    return downarrow, rightarrow
end

function nextdir(dir)
    assertValidDir(dir)
    if (dir == DOWN) then
        return RIGHT
    elseif(dir == RIGHT) then
        return UP
    elseif(dir == UP) then
        return LEFT
    else
        return DOWN
    end
end

function DefaultField(w,h)
    w = w or DEFAULT_WIDTH
    h = h or DEFAULT_HEIGHT

    local field = {};
    field.width  = w;
    field.height = h;
    field._cells = {};
    field._defCell = DefaultCell();
    
    --one cell more to the left and bottom for the walls
    function defRow()
        local row = {};
        for i = 1,field.width+1 do
            row[i] = DefaultCell();
        end
        return row;
    end
    
    for i = 1,field.height+1 do
        field._cells[i] = defRow();
    end
    
    for x = 1,field.width+1 do
        field._cells[1][x].colTop = true
        field._cells[field.height+1][x].colTop = true
    end
    
    for y = 1,field.height+1 do
        field._cells[y][1].colLeft = true
        field._cells[y][field.width+1].colLeft = true
    end
    
    function field:get(x,y)
        if (x <= 0 or x > self.width + 1 or y <= 0 or y > self.height + 1) then
            return self._defCell;
        end
        return self._cells[y][x];
    end
    
    function field:isBadPortalPosition(x,y,dir)
        return (x == 1 and dir == LEFT)
        or(x == field.width and dir == RIGHT)
        or(y == 1 and dir == UP)
        or(y == field.height and dir == BOTTOM)
    end
    
    function field:openPortal(x1,y1,x2,y2, side1, up1, side2, up2)
        assertValidDir(side1)
        assertValidDir(up1)
        assertValidDir(side2)
        assertValidDir(up2)
        
        if(self:isBadPortalPosition(x1,y1,side1))
        or(self:isBadPortalPosition(x2,y2,side2)) then
            return
        end
        
        field:destroyPortal(x1,y1,side1)
        field:destroyPortal(x2,y2,side2)
        
        if(field:hasWall(x1,y1,side1)) then
            field:toggleWall(x1,y1,side1)
        end
        if(field:hasWall(x2,y2,side2)) then
            field:toggleWall(x2,y2,side2)
        end
        
        local portal1   = Portal();
        portal1.xout    = x2;
        portal1.yout    = y2;
        portal1.sideout = side2;
        portal1.upin   = up1;
        portal1.upout  = up2;
        
        local portal2   = Portal();
        portal2.xout    = x1;
        portal2.yout    = y1;
        portal2.sideout = side1;
        portal2.upin    = up2;
        portal2.upout   = up1;
        
        self:get(x1,y1).portals[side1] = portal1;
        self:get(x2,y2).portals[side2] = portal2;
    end
    
    function field:go(x,y,dir,dirup)
        assertValidDir(dir)
        
        if(dirup) then
            assertValidDir(dirup)
        else
            dirup = nextdir(dir)
        end
        
        local dx, dy
        dx, dy = dirtodxy(dir)
        local thisCell = self:get(x,y)
        
        if (not thisCell.portals[dir]) then
            return x+dx,y+dy,dir,dirup
        end
        
        --there is a portal
        local portal = thisCell.portals[dir]
        local newx = portal.xout
        local newy = portal.yout
        local otherCell = self:get(newx,newy)
        
        local newdir   = -portal.sideout
        local newdirup;
        if(dirup == dir) then newdirup = newdir
        elseif(dirup == -dir) then newdirup = -newdir
        else
            newdirup = portal.upin == dirup and portal.upout or -portal.upout
        end
        
        assertValidDir(newdir)
        assertValidDir(newdirup)
        
        return  newx,
                newy,
                newdir,
                newdirup;
    end
    
    function field:shadeCell(x,y,xmin,ymin,downdir,rightdir,brightness)
        -- rightdir: Direction the physically right side of the cell is faced to
        -- downdir:  Direction the physically down  side of the cell is faced to
        local cell = self:get(x,y)
        
        drawTileInCell(xmin,ymin,0,0,1,1,cell.background,downdir,rightdir,brightness,PRIO_BACK)
        local wallPerc = WALLSIZE / CELLSIZE
        
        --Hack to have well ordered walls
        if(self:hasWall(x,y,UP)) then
            drawTileInCell(xmin,ymin,-wallPerc,-wallPerc,1+wallPerc,  wallPerc, "barh.png",  downdir,rightdir, brightness, PRIO_WALL + brightness + cell.counter / 1000)
        end
        
        if(self:hasWall(x,y,LEFT)) then
            drawTileInCell(xmin,ymin,-wallPerc,-wallPerc,  wallPerc,1+wallPerc, "barv.png", downdir,rightdir, brightness, PRIO_WALL + brightness + (cell.counter + 0.5) / 1000)
        end
        
        if(self:hasWall(x,y,DOWN)) then
            drawTileInCell(xmin,ymin, -wallPerc,1-wallPerc,1+wallPerc, 1+wallPerc, "barh.png",  downdir,rightdir, brightness, PRIO_WALL + brightness + cell.counter / 1000)
        end
        
        if(self:hasWall(x,y,RIGHT)) then
            drawTileInCell(xmin,ymin,1-wallPerc,-wallPerc, 1+wallPerc,1+wallPerc, "barv.png", downdir,rightdir, brightness, PRIO_WALL + brightness + (cell.counter + 0.5) / 1000)
        end
        
        for k,o in pairs(cell.objects) do
            drawTileInCell(xmin,ymin, o.cx % 1 - o.xrad, o.cy % 1 - o.yrad, o.cx % 1 + o.xrad, o.cy % 1 + o.yrad, o.img, downdir,rightdir, brightness, o.z, o.grav, o.mirrored)
        end
    end
    
    function field:hasWall(x,y,dir)
        assertValidDir(dir)
        local cell = self:get(x,y)
        
        if(cell.portals[dir]) then
            return false
        end
        
        if (dir == TOP) then
            return cell.colTop
        elseif (dir == LEFT) then
            return cell.colLeft
        elseif (dir == RIGHT) then
            if (cell.portals[RIGHT]) then return false end
            return self:get(x+1,y).colLeft
        else
            if(cell.portals[DOWN]) then return false end
            return self:get(x,y+1).colTop
        end
    end
    
    function field:toggleWall(x,y,dir)
        assertValidDir(dir)
        
        if(x == 1 and dir == LEFT)
        or(y == 1 and dir == UP)
        or(x == self.width and dir == RIGHT)
        or(y == self.height and dir == DOWN) then
            -- denied. You may not delete the border of the level
            return
        end
        
        
        --destroy portals if there are any
        field:destroyPortal(x,y,dir)
        local cell = self:get(x,y)
        
        if (dir == TOP) then
            cell.colTop = not cell.colTop
        elseif (dir == LEFT) then
            cell.colLeft = not cell.colLeft
        elseif (dir == RIGHT) then
            cell = self:get(x+1,y)
            cell.colLeft = not cell.colLeft
        else
            cell = self:get(x,y+1)
            cell.colTop = not cell.colTop
        end
    end
    
    function field:destroyPortal(x,y,dir)
        local cell   = self:get(x,y)
        local portal = cell.portals[dir]
        if(portal) then
            cell.portals[dir] = nil
            self:get(portal.xout,portal.yout).portals[portal.sideout] = nil
        end
    end
    
    function field:togglePortal(x,y,dir)
        local portal = self:get(x,y).portals[dir]
        if portal then
            portal.upin = -portal.upin
            local other = self:get(portal.xout,portal.yout).portals[portal.sideout]
            other.upout = -other.upout
        end
    end
    
    function field:toggleWallStrip(x,y,dir,...)
        if not dir then return end
        
        assertValidDir(dir)
        if(dir == TOP) then
            field:toggleWall(x,y-1,LEFT)
            y = y - 1
        elseif(dir == DOWN) then
            field:toggleWall(x,y,LEFT)
            y = y + 1
        elseif(dir == RIGHT) then
            field:toggleWall(x,y,TOP)
            x = x + 1
        elseif(dir == LEFT) then
            field:toggleWall(x-1,y,TOP)
            x = x - 1
        end
        self:toggleWallStrip(x,y,...)
    end
    
    function field:collectObjects()
        for i = 1,self.width do
            for j = 1,self.height do
                self:get(i,j).objects = {}
            end
        end
        
        for k,e in pairs(objects) do
            
            local x = math.floor(e.cx)
            local y = math.floor(e.cy)
            
            local map = self:get(x,y).objects;
            --print("x:"..x..",y="..y)
            map[#map+1] = e;
        end
    end
    
    function field:shadeEditor(offx, offy,hlx,hly,halfopen)
        local xmin, xmax, ymin, ymax
        xmin = math.floor(math.max(1          , (-offx-WALLSIZE)     / CELLSIZE))
        xmax = math.floor(math.min(self.width , (RESX-offx-WALLSIZE) / CELLSIZE))
        ymin = math.floor(math.max(1          , (-offy-WALLSIZE)     / CELLSIZE))
        ymax = math.floor(math.min(self.height, (RESY-offy-WALLSIZE) / CELLSIZE))
        
        self:collectObjects();
        
        if not markerStar then
            markerStar = object(-1, -1, 1/2, 1/2, "star.png", MARKER_PRIO)
        end
        
        markerStar.cx = hlx + 0.5
        markerStar.cy = hly + 0.5
        local list = self:get(hlx,hly).objects
        list[#list+1] = markerStar
        
        if(halfopen) then
            local halfopenmarker = object(halfopen.xin+0.5, halfopen.yin+0.5, 0.5, 0.5, "portalmarker.png", PRIO_PORTAL)
            halfopenmarker.grav = halfopen.side
            local cell = self:get(halfopen.xin,halfopen.yin)
            cell.objects[#cell.objects+1] = halfopenmarker
        end
        
        function numberAt(num,x,y,dir,color)
            local dx, dy = dirtodxy(dir)
            x = (dx / 3 + x+0.5)*CELLSIZE + offx - PORTAL_FONT_SIZE / 2
            y = (dy / 3 + y+0.5)*CELLSIZE + offy - PORTAL_FONT_SIZE / 2
            
            text:print(tostring(num), x, y, PORTAL_FONT_SIZE, color)
        end
        
        local portalNumber = 1
        
        for y = 1,field.height do
            for x = 1,field.width do
                local cell = self:get(x,y)
                for _,dir in pairs(DIRS) do
                    if(cell.portals[dir]) then
                        local portal = cell.portals[dir]
                        local img = "portalin.png"
                        local mirrored = false
                        if  portal.yout > y
                        or (portal.yout == y and portal.xout > x)
                        or (portal.yout == y and portal.xout == x and portal.sideout >= dir) then
                            img = "portalout.png"
                            
                            numberAt(portalNumber, x, y, dir, {0,0,0,255})
                            numberAt(portalNumber, portal.xout, portal.yout, portal.sideout, {255, 255, 255,255})
                            portalNumber = portalNumber + 1
                        end
                    
                        local portalObj = object(x+0.5, y+0.5, 0.5, 0.5, img, PRIO_PORTAL + dir)--avoid ambiguities
                        portalObj.grav = dir
                        
                        if nextdir(dir) == portal.upin then
                            mirrored = not mirrored
                        end
                        portalObj.mirrored = mirrored
                        cell.objects[#cell.objects+1] = portalObj
                    end
                end
                
                --shading is expensive. The part above has to be done for consistent portal numbering
                if (ymin <= y and y <= ymax)
                and(xmin <= x and x <= xmax) then
                    self:shadeCell(x, y, x * CELLSIZE + offx, y * CELLSIZE + offy, DOWN, RIGHT,255)
                end
            end
        end
        
    end
    
    function field:shade()
        --local OFFSET = CELLSIZE + 40
        --field:shadeCell(5,5,0*OFFSET,OFFSET,DOWN,RIGHT,255)
        --field:shadeCell(5,5,1*OFFSET,OFFSET,RIGHT,UP,255)
        --field:shadeCell(5,5,2*OFFSET,OFFSET,UP,LEFT,255)
        --field:shadeCell(5,5,3*OFFSET,OFFSET,LEFT,DOWN,255)
        --
        --field:shadeCell(5,5,0*OFFSET,2*OFFSET,RIGHT,DOWN, 255)
        --field:shadeCell(5,5,1*OFFSET,2*OFFSET,UP,   RIGHT,255)
        --field:shadeCell(5,5,2*OFFSET,2*OFFSET,LEFT, UP,   255)
        --field:shadeCell(5,5,3*OFFSET,2*OFFSET,DOWN, LEFT, 255)
        
        --drawTileInCell(CELLSIZE,  CELLSIZE,  0,  0,1,1,"NONE.png",DOWN, RIGHT, 255,1)
        --drawTileInCell(2*CELLSIZE,CELLSIZE,  0,  0,1,1,"NONE.png",RIGHT,UP,    255,1)
        --drawTileInCell(3*CELLSIZE,CELLSIZE,  0,  0,1,1,"NONE.png",UP,   LEFT,  255,1)
        --drawTileInCell(4*CELLSIZE,CELLSIZE,  0,  0,1,1,"NONE.png",LEFT, DOWN,  255,1)
        --
        --drawTileInCell(CELLSIZE,  2*CELLSIZE,  0,  0,1,1,"NONE.png",RIGHT, DOWN, 255,1)
        --drawTileInCell(2*CELLSIZE,2*CELLSIZE,  0,  0,1,1,"NONE.png",UP,    RIGHT,255,1)
        --drawTileInCell(3*CELLSIZE,2*CELLSIZE,  0,  0,1,1,"NONE.png",LEFT,  UP,   255,1)
        --drawTileInCell(4*CELLSIZE,2*CELLSIZE,  0,  0,1,1,"NONE.png",DOWN,  LEFT, 255,1)
                
        self:collectObjects();
        
        local px = RESX / 2;
        local py = RESY / 2;
        local cellx = math.floor(player.cx)
        local celly = math.floor(player.cy)
        
        function toDoNode(screenx, screeny, logx, logy, stepsleft,downdir,rightdir)
            local node = {}
            assertValidDir(downdir)
            assertValidDir(rightdir)
            node.logx     = logx
            node.logy     = logy
            node.screenx   = screenx
            node.screeny   = screeny
            node.stepsleft = stepsleft
            node.downdir   = downdir
            node.rightdir  = rightdir
            return node
        end
        
        local toDo = {}
        local done = {}
        
        local playerright = player.mirrored and -nextdir(player.grav) or nextdir(player.grav)
        
        local downarrow
        local rightarrow
        downarrow, rightarrow = invertPair(player.grav, playerright)
        
        local ox
        local oy
        ox, oy = transformOffset(player.cx % 1, player.cy % 1, downarrow,rightarrow)
        
        px = px - ox * CELLSIZE
        py = py - oy * CELLSIZE
        
        toDo[0] = toDoNode(0, 0, cellx, celly, SIGHT_RANGE, player.grav, playerright)
        
        local next   = 0
        local writer = 1
        
        while(toDo[next]) do
            node = toDo[next]
            next = next + 1
            
            local continue = true
            
            if(not done[node.screenx]) then
                done[node.screenx] = { [node.screeny] = true }
            elseif (done[node.screenx][node.screeny]) then
                continue = false
            else
                done[node.screenx][node.screeny] = true
            end
            
            if (continue) then
                -- screen right is physical node.rightdir
                -- screen down is physical node.downdir
                -- where does the downarrow of the cell point?
                downarrow, rightarrow = invertPair(node.downdir, node.rightdir)
                
                self:shadeCell(node.logx, node.logy, px + node.screenx * CELLSIZE, py + node.screeny * CELLSIZE, downarrow, rightarrow,255 * node.stepsleft / SIGHT_RANGE)
                
                -- insert surrounding elements into toDo queue
                if(node.stepsleft > 1) then
                    local newx;
                    local newy;
                    local newdir;
                    local newother;
                    
                    if(not field:hasWall(node.logx,node.logy,-node.rightdir)) then
                        newx, newy, newdir, newother = field:go(node.logx,node.logy, -node.rightdir,node.downdir)
                        toDo[writer] = toDoNode(node.screenx - 1, node.screeny, newx, newy, node.stepsleft - 1, newother, -newdir)
                        writer = writer + 1
                    end
                    
                    if(not field:hasWall(node.logx,node.logy,node.rightdir)) then
                        newx, newy, newdir, newother = field:go(node.logx,node.logy,  node.rightdir,node.downdir)
                        toDo[writer] = toDoNode(node.screenx + 1, node.screeny, newx, newy, node.stepsleft - 1, newother,  newdir)
                        writer = writer + 1
                    end
                    
                    if(not field:hasWall(node.logx,node.logy,node.downdir)) then
                        newx, newy, newdir, newother = field:go(node.logx,node.logy,  node.downdir, node.rightdir)
                        toDo[writer] = toDoNode(node.screenx, node.screeny + 1, newx, newy, node.stepsleft - 1, newdir,  newother)
                        writer = writer + 1
                    end
                    
                    if(not field:hasWall(node.logx,node.logy,-node.downdir)) then
                        newx, newy, newdir, newother = field:go(node.logx,node.logy, -node.downdir, node.rightdir)
                        toDo[writer] = toDoNode(node.screenx, node.screeny - 1, newx, newy, node.stepsleft - 1, -newdir,  newother)
                        writer = writer + 1
                    end
                end
            end
        end
    end
    
    function field:export(filename)
        local f = assert(io.open(filename,"w"))
        
        function writeProp(name,value)
            f:write(name, " ", value, "\n")
        end
        
        writeProp("mapWidth",self.width)
        writeProp("mapHeight", self.height)
        
        -- print list of non-walls
        for y = 1,self.height do
            f:write("    ")
            for x = 1,self.width do
                if(self:hasWall(x,y,TOP)) then
                    f:write(x, " ", y, " ", dirToStr(TOP), " ")
                end
                
                if(self:hasWall(x,y,LEFT)) then
                    f:write(x, " ", y, " ", dirToStr(LEFT), " ")
                end
            end
            
            f:write("\n")
        end
        
        f:write(-1, " ", -1, " ", "END_OF_WALLS\n\n")
        
        f:write("PORTALS\n")
        for y = 1,self.height do
            for x = 1,self.width do
                local cell = self:get(x,y)
                for _,e in pairs(DIRS) do
                    if(cell.portals[e]) then
                        local portal = cell.portals[e]
                        
                        if  portal.yout > y
                        or (portal.yout == y and portal.xout > x)
                        or (portal.yout == y and portal.xout == x and portal.sideout >= e) then
                            f:write("    PORTAL "..x.." "..y.." "..portal.xout.." "..portal.yout.." "..e.." "..portal.upin.." "..portal.sideout.." "..portal.upout.."\n")
                        end
                    end
                end
            end
        end
        
        f:write("END_OF_PORTALS\n\n")
        
        for k,o in pairs(objects) do
            f:write(o.typ, "\n")
            
            for key,value in pairs(o) do
                if (type(value) ~= "function") then
                    f:write("    "..key.." "..type(value).." "..tostring(value).."\n")
                end
            end
            
            f:write("END_OF_OBJECT\n")
        end
        
        f:write("END_OF_MAP\n")
        f:close()
    end
    
    return field;
end

function import(filename)
    local f = io.open(filename, "r")
    
    if not f then
        field = DefaultField()
        return
    end

    function readString()
        local str
        repeat
            str = f:read(1)
        until str ~= " " and str ~= "\n"
        
        repeat
            next = f:read(1)
            
            if(next ~= " " and next ~= "\n") then
                str = str..next
            else
                break
            end
        until false
        
        return str
    end

    function expect(name)
        local str = readString()
        
        if (str ~= name) then
            error("Expected '"..name.."', but found '"..str.."'.")
        end
    end

    function readProp(name)
        expect(name)
        return f:read("*number")
    end

    local w = readProp("mapWidth")
    local h = readProp("mapHeight")
    
    field = DefaultField(w,h)
    objects = {}
    
    local x
    local y
    local dir
    repeat
        x = f:read("*number")
        y = f:read("*number")
        dir = readString()
        
        if(dir ~= "END_OF_WALLS") then
            field:toggleWall(x,y,dirFromStr(dir))
        else
            break;
        end
    until false
    
    expect("PORTALS")
    str = readString()
    while(str == "PORTAL") do
        local x = f:read("*n")
        local y = f:read("*n")
        local xout = f:read("*n")
        local yout = f:read("*n")
        local dir = f:read("*n")
        local up = f:read("*n")
        local dirout = f:read("*n")
        local upout = f:read("*n")
        
        field:openPortal(x,y,xout,yout,dir,up,dirout,upout)
        str = readString()
    end
    
    if (str ~= "END_OF_PORTALS") then
        error("Expected 'END_OF_PORTALS' but found '"..str.."'")
    end
    
    local constructor = readString()
    
    while(constructor ~= "END_OF_MAP") do
        local o  = _G[constructor]()
        local prop = readString()
        
        while(prop ~= "END_OF_OBJECT") do
            local typname = readString()
            if(typname == "string") then
                o[prop] = readString()
            elseif(typname == "boolean") then
                o[prop] = readString() == "true"
            elseif(typname =="number") then
                o[prop] = f:read("*number")
            else
                error("I dont know that type: "..typname)
            end
            
            prop = readString()
        end
        
        objects[#objects+1] = o
        
        if(constructor == "makeplayer") then
            player = o
        end
        
        constructor = readString()
    end
    
    io.close()
end

function fieldInit()
    testfield = 1

    if testfield == 1 then
        field = DefaultField(20,20,true)
        player.cx = 2.5
        player.cy = 2.5
    
        field:openPortal(2,2,4,2,LEFT,UP,RIGHT,DOWN)
        field:get(3,2).colLeft = false
        field:get(2,2).colLeft = false
        field:get(4,2).colLeft = false
        field:get(5,2).colLeft = false
    elseif testfield == 2 then
        field = DefaultField(20,20,true)
        player.cx = 2.5
        player.cy = 2.5
        field:get(4,3).colTop = false;
        field:get(4,2).colLeft = false;
        field:get(3,2).colLeft = false;
        field:get(2,3).colTop = false;
        field:get(2,4).colTop = false;
        field:get(3,4).colLeft = false;
        field:get(4,4).colLeft = false;
        field:get(4,5).colTop = false;
        field:get(4,6).colTop = false;
        field:get(4,6).colLeft = false;
        field:get(3,6).colLeft = false;
        field:get(2,6).colTop = false;
    
        field:get(5,6).colTop = false;
        field:get(5,5).colTop = false;
        field:get(6,4).colLeft = false;
        field:get(7,4).colLeft = false;
        field:get(7,4).colTop = false;
        field:get(7,3).colTop = false;
    
        field:openPortal(2,6,5,5,TOP,RIGHT,BOTTOM,RIGHT)
        field:openPortal(4,2,7,3,BOTTOM,RIGHT,TOP,RIGHT)
    else
        field = DefaultField()
    end
    
    field:export("blabla.map")
    import("blabla.map")
    
    --field:get(3,3).colLeft = false
    --field:get(7,6).colLeft = false
    
    --field:openPortal(2,2,1,3,RIGHT,UP,LEFT,UP)
end
