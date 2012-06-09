TOP   =  1
UP    =  TOP
BOTTOM= -1
DOWN  = BOTTOM
LEFT  =  2
RIGHT = -2

CELLSIZE = 128

function DefaultCell()
    local cell = {}
    cell.background = "NONE.png";
    cell.topImg     = "NOBAR_H.png";
    cell.leftImg    = "NOBAR_V.png";
    cell.colTop = false;
    cell.colLeft = false;
    cell.portals = {};
    cell.objects = {};
    
    function cell:shade(xmin,ymin,updir)
        render:add(textures[cell.background], xmin, ymin, 1, 255)
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
    end;
    
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
        for i in 1,width do
            for j in 1,height do
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
        --[[ local px = RESX / 2;
        local py = RESY / 2;
        
        px = px - (player.cx % 1) * CELLSIZE
        py = py - (player.cy % 1) * CELLSIZE
        
        
        
        
        self:collectObjects();
        
        RESX, RESY
        x, y = math.floor(px), math.floor(py)
        
        
        field:get(1,1):shade(cx,cy,RIGHT)]]
        
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
