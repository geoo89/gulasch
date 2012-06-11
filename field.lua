require 'archiver'
require 'geometry'
require 'constants'

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
    
    physminx = cellx + CELLSIZE * math.min(xmin,xmax)
    physminy = celly + CELLSIZE * math.min(ymin,ymax)
    
    local angle = 0 -- (* PI/2)
    while(downdir ~= DOWN) do
        angle = (angle + 1) % 4
        downdir = nextdir(downdir)
    end
    
    local gravAngle = 0
    while(objgrav ~= DOWN) do
        objgrav = nextdir(objgrav)
        gravAngle = (gravAngle + 1) % 4
    end
    
    --careful: Turn in opposite direction in mirrored situation
    if (sx == -1) then
        gravAngle = (-gravAngle + 4) % 4
    end
    
    angle = (angle + gravAngle) % 4
    
    --effectively not mirrored if mirrored twice 
    if(objmirr) then sx = -sx end
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

function Portal()
    local portal = {}
    --[[properties:
        xout,yout,
        sideout
        upin,upout]]
    return portal;
end

function DefaultField(w,h)
    local cellCount = 0

    function DefaultCell()
        local cell = {}
        cell.background = DEFAULT_BACKGROUND;
        cell.colTop    = false
        cell.colLeft   = false
        cell.portals = {};
        cell.objects = {};
        cellCount = cellCount + 1
        cell.counter = cellCount    
        return cell;
    end

    w = w or DEFAULT_WIDTH
    h = h or DEFAULT_HEIGHT

    local field = {};
    field.width  = w;
    field.height = h;
    field._cells = {};
    field._defCell = DefaultCell();
    
    player = makeplayer();
    player.cx = 1.5
    player.cy = 1.5
    objects = { player }
    
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
        
        print(x1,y1,x2,y2,dirToStr(side1),dirToStr(up1),dirToStr(side2),dirToStr(up2))
        
        --Prefer portals that point up, just because I
        --dont wnat the graphic to be upside down all the time
        if (up1 == DOWN or up2 == DOWN) then
            up1,up2 = -up1,-up2
        end
        
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
        local dx,dy = dirtodxy(dir)
        field:destroyPortal(x+dx,y+dy,-dir)
        
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
            local halfopenmarker = object(halfopen.xin+0.5, halfopen.yin+0.5, 0.5, 0.5, "portalmarker.png", PRIO_PORTAL + 5)
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
                        local mirrored = true --default mirror, because the graphic is drawn the wrong way
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
    
    return field;
end



function fieldInit()
    field = DefaultField()
end
