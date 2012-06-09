TOP   =  1
UP    =  TOP
BOTTOM= -1
DOWN  = BOTTOM
LEFT  =  2
RIGHT = -2

CELLSIZE = 128
WALLSIZE =  16
PRIO_BACK = 10
PRIO_WALL =  9
SIGHT_RANGE = 5

function transformOffset(x,y,downdir,rightdir)
    if(downdir == DOWN) then
        x = rightdir == RIGHT and x or 1 - x
    elseif(downdir == UP) then
        y = 1 - y
        x = rightdir == RIGHT and x or 1 - x
    elseif(downdir == RIGHT) then
        if (rightdir == UP) then
            x, y = 1 - y, x
        else
            x, y = y, x
        end
    else
        assert(downdir == LEFT)
        
        if(rightdir == DOWN) then
            x, y = y, 1 - x
        else
            x, y = 1 - y, 1 - x
        end
    end
    return x,y
end

function drawTileInCell(cellx,celly,xmin,ymin,xmax,ymax,img,downdir,rightdir,brightness,zprio)
    local dimx = xmax - xmin
    local dimy = ymax - ymin
    xmin,ymin = transformOffset(xmin,ymin,downdir,rightdir)
    xmax,ymax = transformOffset(xmax,ymax,downdir,rightdir)
    
    --Now I have the actual screen position the top left corner of the image is mapped to
    local mirrored = nextdir(downdir) == rightdir
    
    if (mirrored) then
        dimx = -dimx
    end

    physminx = cellx + math.min(xmin,xmax)
    physminy = celly + math.min(ymin,ymax)
    
    local angle
    if (downdir == DOWN) then
        angle = 0
    elseif (downdir == UP) then
        angle = math.pi
    else
        if (downdir == RIGHT) then
            angle = math.pi * 3 / 2
        else
            angle = math.pi / 2
        end
    end
    
    render:add(textures[img], physminx, physminy, zprio, brightness, dimx, dimy, angle)
end

cellCount = 0

function DefaultCell()
    local cell = {}
    cell.background = "NONE.png";
    cell.topImg     = "NOBAR_H.png";
    cell.leftImg    = "NOBAR_V.png";
    cell.colTop = false;
    cell.colLeft = false;
    cell.portals = {};
    cell.objects = {};
    cellCount = cellCount + 1
    cell.counter = cellCount
    
    
    function cell:shade(xmin,ymin,downdir,rightdir,brightness)
        drawTileInCell(xmin,ymin,0,0,1,1,self.background,downdir,rightdir,brightness,PRIO_BACK)
        local wallPerc = WALLSIZE / CELLSIZE
        
        --Hack to have well ordered walls
        drawTileInCell(xmin,ymin,-wallPerc,-wallPerc,1+wallPerc,  wallPerc, self.topImg,  downdir,rightdir, brightness, PRIO_WALL + cell.counter / 1000)
        drawTileInCell(xmin,ymin,-wallPerc,-wallPerc,  wallPerc,1+wallPerc, self.leftImg, downdir,rightdir, brightness, PRIO_WALL + (cell.counter + 0.5) / 1000)
        
        for k,o in cell.objects do
            drawTileInCell(xmin,ymin, o.cx - o.xrad, o.cy - o.yrad, o.cx + o.xrad, o.cy + o.yrad, o.img, downdir,rightdir, brightness, o.z)
        end
    end
    
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

function dirtodxy(dir)
    if (dir == LEFT) then
        return -1,0
    elseif (dir == RIGHT) then
        return 1,0
    elseif (dir == TOP) then
        return 0,-1
    elseif (dir == BOTTOM) then
        return 0,1
    else
        assert(false, "dirtodxy: SHITTY INPUT");
    end
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

function nextdir(dir)
    if (dir == DOWN) then
        return RIGHT
    elseif(dir == RIGHT) then
        return UP
    elseif(dir == UP) then
        return LEFT
    else
        assert(dir == LEFT)
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
        local dx, dy
        dx, dy = dirtodxy(dir)
        local thisCell = self:get(x,y)
        
        if (not thisCell.portals[dir]) then
            print("nope");
            return x+dx,y+dy,dx,dy
        end
        
        --there is a portal
        local portal = thisCell.portals[dir]
        local newx = portal.xout
        local newy = portal.yout
        local otherCell = self:get(newx,newy)
        
        return newx,
                newy,
                -portal.sideout,
                portal.upin == dirup and portal.upout or -portal.upout;
    end;
    
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
            map[#map+1] = e;
        end
    end
    
    function field:shade()
        self:collectObjects();
    
        local px = RESX / 2;
        local py = RESY / 2;
        local cellx = math.floor(player.cx)
        local celly = math.floor(player.cy)
        
        px = px - (player.cx % 1) * CELLSIZE
        py = py - (player.cy % 1) * CELLSIZE
        
        function toDoNode(screenx, screeny, logx, logy, stepsleft,downdir,rightdir)
            local node = {}
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
        toDo[0] = toDoNode(0, 0, cellx, celly, SIGHT_RANGE, player.grav, nextdir(player.grav))
        local next   = 0
        local writer = 1
        
        while(toDo[i]) do
            node = toDo[i]
            next = next + 1
            
            local continue = true
            
            if(not done[screenx]) then
                done[screenx] = { [node.screeny] = true }
            elseif (done[screenx][screeny]) then
                continue = false
            else
                done[screenx][screeny] = true
            end
            
            if (continue) then
                self:get(node.logx,node.logy):shade(px + node.screenx * CELLSIZE, py + node.screeny * CELLSIZE, node.downdir, node.rightdir,255 * stepsleft / SIGHT_RANGE)
                
                -- insert surrounding elements into toDo queue
                if(node.stepsleft > 1) then
                    local newx;
                    local newy;
                    local newdir;
                    local newother;
                    newx, newy, newdir, newother = field:go(node.logx,node.logy, -node.rightdir,node.downdir)
                    toDo[writer] = toDoNode(node.screenx - 1, node.screeny, newx, newy, node.stepsleft - 1, newother, -newdir)
                    writer = writer + 1
                    newx, newy, newdir, newother = field:go(node.logx,node.logy,  node.rightdir,node.downdir)
                    toDo[writer] = toDoNode(node.screenx + 1, node.screeny, newx, newy, node.stepsleft - 1, newother,  newdir)
                    writer = writer + 1
                    newx, newy, newdir, newother = field:go(node.logx,node.logy,  node.downdir, node.rightdir)
                    toDo[writer] = toDoNode(node.screenx, node.screeny + 1, newx, newy, node.stepsleft - 1, newdir,  newother)
                    writer = writer + 1
                    newx, newy, newdir, newother = field:go(node.logx,node.logy, -node.downdir, node.rightdir)
                    toDo[writer] = toDoNode(node.screenx, node.screeny + 1, newx, newy, node.stepsleft - 1, -newdir,  newother)
                    writer = writer + 1
                end
            end
        end
    end
    
    return field;
end

cx       = 500
cy       = 500
cellSize = 128

objects = {}

function fieldInit()
    field = DefaultField()
    field:openPortal(1,1,4,3,RIGHT,UP,LEFT,UP)
    print(field:go(1,1,RIGHT,UP,LEFT,UP))
    print("lol")
end
