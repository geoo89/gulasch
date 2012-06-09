TOP   =  1
UP    =  TOP
BOTTOM= -1
DOWN  = BOTTOM
LEFT  =  2
RIGHT = -2

CELLSIZE = 128
WALLSIZE =   8
WALLPERC =  WALLSIZE / CELLSIZE
PRIO_BACK =   10
PRIO_WALL =  300
MARKER_PRIO = 900
SIGHT_RANGE = 4

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
    cell.colTop    = true
    cell.colLeft   = true
    cell.portals = {};
    cell.objects = {};
    cellCount = cellCount + 1
    cell.counter = cellCount    
    return cell;
end

function Portal()
    local portal = {}
    --[[properties:
        xin,yin,
        xout,yout,
        sidein, sideout
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
    elseif(dir == RIGHT) then return "RIGHT" end
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

function DefaultField()
    local field = {};
    field.width  = 64;
    field.height = 32;
    field._cells = {};
    field._defCell = DefaultCell();
    
    function defRow()
        local row = {};
        for i = 1,field.width do
            row[i] = DefaultCell();
        end
        return row;
    end
    
    for i = 1,field.height do
        field._cells[i] = defRow();
    end
    
    function field:get(x,y)
        if (x <= 0 or x > self.width or y <= 0 or y > self.height) then
            return self._defCell;
        end
        return self._cells[y][x];
    end
    
    function field:openPortal(x1,y1,x2,y2, side1, up1, side2, up2)
        assertValidDir(side1)
        assertValidDir(up1)
        assertValidDir(side2)
        assertValidDir(up2)
    
        local portal1   = Portal();
        portal1.xin     = x1;
        portal1.xout    = x2;
        portal1.yin     = y1;
        portal1.yout    = y2;
        portal1.sidein  = side1;
        portal1.sideout = side2;
        portal1.upin   = up1;
        portal1.upout  = up2;
        
        local portal2   = Portal();
        portal2.xin     = x2;
        portal2.xout    = x1;
        portal2.yin     = y2;
        portal2.yout    = y1;
        portal2.sidein  = side2;
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
            print("foundobject")
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
            print("x:"..x..",y="..y)
            map[#map+1] = e;
        end
    end
    
    if not markerStar then
        markerStar = object(-1, -1, 1/2, 1/2, "star.png", MARKER_PRIO)
        objects[#objects+1] = markerStar
    end
    
    function field:shadeEditor(offx, offy,hlx,hly)
        local xmin, xmax, ymin, ymax
        xmin = math.floor(math.max(1         , (-offx-WALLSIZE)     / CELLSIZE))
        xmax = math.floor(math.min(self.width, (RESX-offx-WALLSIZE) / CELLSIZE))
        ymin = math.floor(math.max(1         , (-offy-WALLSIZE)     / CELLSIZE))
        ymax = math.floor(math.min(self.height, (RESY-offy-WALLSIZE) / CELLSIZE))
    
        markerStar.cx = hlx + 0.5
        markerStar.cy = hly + 0.5
        
        self:collectObjects();
        for y = ymin,ymax do
            for x = xmin,xmax do
                self:shadeCell(x, y, x * CELLSIZE + offx, y * CELLSIZE + offy, DOWN, RIGHT,255)
            end
        end
        
        -- print star over selected image
        markerStar.cx = -1
        markerStar.cy = -1
    end
    
    function field:export(io)
        
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
        
        field:shadeEditor(-200, -200, 3, 3)
        if true then return end
        
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
    
    return field;
end

cx       = 500
cy       = 500
cellSize = 128

function fieldInit()
    
    
    field = DefaultField()
    
    testfield = 1
    
    --field:get(3,2).colLeft = false
    --field:get(3,2).colTop = false
    --field:openPortal(3,1,2,2,UP,LEFT,LEFT,UP)
    
    --self connect, right to top
    --field:openPortal(2,2,2,2,RIGHT,UP,UP,RIGHT)
    --field:get(2,2).colTop = false
    --field:get(3,2).colLeft = false
    
    if testfield == 1 then
        player.cx = 2.5
        player.cy = 2.5
    
        field:openPortal(2,2,4,2,LEFT,UP,RIGHT,DOWN)
        field:get(3,2).colLeft = false
        field:get(2,2).colLeft = false
        field:get(4,2).colLeft = false
        field:get(5,2).colLeft = false
    elseif testfield == 2 then
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
    end
    
    
    --field:get(3,3).colLeft = false
    --field:get(7,6).colLeft = false
    
    --field:openPortal(2,2,1,3,RIGHT,UP,LEFT,UP)
end
