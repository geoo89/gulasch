require 'field'

JUMP_STRENGTH = 4
GRAV_STRENGTH = 1
AIR_ACCEL = 1
FLOOR_SPEED = 1

function object(cx, cy, xrad, yrad, img, z)
    local o = {}
    o.cx = cx
    o.cy = cy
    o.xrad = xrad
    o.yrad = yrad
    o.img = img
    o.z = z or 0
    o.mirrored = false
    
    function o:update() return self end
    
    function o:render()
        render:add(textures[o.img], (o.cx - o.xrad - 1) * 128, (o.cy - o.yrad - 1) * 128, o.z, 255)
    end
    
    return o
end

function rigidbody(cx, cy, xrad, yrad, img, z, velx, vely, weight, grav)
    local o = object(cx, cy, xrad, yrad, img, z)
    o.rigid = true
    o.velx = velx or 0
    o.vely = vely or 0
    o.weight = weight or 1
    o.grav = grav or DOWN
    
    o.update = function(self, dt)
        local ax, ay = dirtodxy(o.grav)
        o.velx = o.velx + GRAV_STRENGTH * ax * dt
        o.vely = o.vely + GRAV_STRENGTH * ay * dt
        
        -- TODO: CHECK HERE IF WE TRAVERSE THROUGH A PORTAL
        local intx = math.floor(o.cx)
        local inty = math.floor(o.cy)
        
        o.cx = o.cx + o.velx * dt
        o.cy = o.cy + o.vely * dt
        
        local intx2 = math.floor(o.cx)
        local inty2 = math.floor(o.cy)
        local fx = o.cx % 1
        local fy = o.cy % 1
        
        local dx = intx2 - intx
        local dy = inty2 - inty
        
        -- TODO: FIX IF BOTH VALUES ARE NONZERO
        if dx==0 and dy == 0 then return self end
        
        print("dx",dx,dy)
        print(fx,fy)
        
        local dir = dxytodir(dx,dy)
        local wurst = 0
        local rgtdir
        local dwndir
        
        newx, newy, wurst, o.grav = field:go(intx, inty, dir, o.grav)
        newx, newy, wurst, rgtdir = field:go(intx, inty, dir, RIGHT)
        newx, newy, wurst, dwndir = field:go(intx, inty, dir, DOWN)
        print(dir, rgtdir, dwndir)
        if (rgtdir ~= nextdir(dwndir)) then o.mirrored = not o.mirrored end
        
        print("mirrored", self.mirrored)
        
        fx,fy = transformOffset(fx,fy,dwndir,rgtdir)
        print(fx,fy)
        o.cx = newx + fx
        o.cy = newy + fy
        
        local vx = o.velx
        local vy = o.vely
        vx,vy = transformOffset(vx+0.5,vy+0.5,dwndir,rgtdir)
        o.velx = vx - 0.5
        o.vely = vy - 0.5
        
        return self
    end

    return o
end

function makeplayer(cx, cy)
    local p = rigidbody(cx, cy, 0.25, 0.25, "player.png", 999, 0, 0, 2, DOWN);
    
    p.onfloor = true
    --p.cx, p.cy = 2.5, 2.5
    --p.xrad, p.yrad = 0.25, 0.25
    --p.velx, p.vely = 0,0
    --p.weight = 2
    --p.grav = DOWN
    --p.z = 999
    --p.img = "player.png"
    
    
    -- TODO: KEY TO GRAB CRATE
    function p:move(dt)
        --print("Move: ", self.cx, self.cy)
        
        
        -- ugly cases
        local x_air = 0
        local y_air = 1
        local x_floor = self.mirrored and -1 or 1
        local y_floor = 0
        if(self.grav == UP) then
            x_air = 0
            y_air = -1
            x_floor = self.mirrored and 1 or -1
            y_floor = 0
        elseif (self.grav == LEFT) then
            x_air = -1
            y_air = 0
            x_floor = 0
            y_floor = self.mirrored and -1 or 1
        elseif (self.grav == RIGHT) then
            x_air = 1
            y_air = 0
            x_floor = 0
            y_floor = self.mirrored and 1 or -1
        end    
        
        --print(self.onfloor)
        
        if kb.isDown('up') and self.onfloor then
            self.velx = self.velx - JUMP_STRENGTH/self.weight * x_air
            self.vely = self.vely - JUMP_STRENGTH/self.weight * y_air
            self.onfloor = false
        end 

        if self.onfloor then 
            self.velx = (1 - x_floor) * self.velx
            self.vely = (1 - y_floor) * self.vely
        end

        if kb.isDown('left') then
            if self.onfloor then
                if x_floor ~= 0 then
                    self.velx = -FLOOR_SPEED * x_floor
                end
                if y_floor ~= 0 then
                    self.vely = -FLOOR_SPEED * y_floor
                end
            else 
                self.velx = self.velx - dt * AIR_ACCEL * x_floor
                self.vely = self.vely - dt * AIR_ACCEL * y_floor
            end
        elseif kb.isDown('right') then
            if self.onfloor then 
                if x_floor ~= 0 then
                    self.velx = FLOOR_SPEED * x_floor
                end
                if y_floor ~= 0 then
                    self.vely = FLOOR_SPEED * y_floor
                end
            else 
                self.velx = self.velx + dt * AIR_ACCEL * x_floor
                self.vely = self.vely + dt * AIR_ACCEL * y_floor
            end
        else
            if self.onfloor then
                if x_floor ~= 0 then
                    self.velx = 0
                end
                if y_floor ~= 0 then
                    self.vely = 0
                end
            end
        end
    end

    return p
end

player = makeplayer(1.5, 1.5)

o1 = rigidbody(3.5, 1.5, 0.0625, 0.0625, "crate.png", 1, 0, 0, 1, DOWN)
o2 = rigidbody(3.5, 3.5, 0.0625, 0.0625, "crate.png", 1, 0, 0, 1, UP)
o3 = object(2.5, 1.5, 0.0625, 0.0625, "crate.png", 1)

objects = {player}

function collide(r1, r2)
    if (r1.rigid and r2.rigid) then
    
        if (math.abs(r1.cx - r2.cx) <= r1.xrad + r2.xrad and math.abs(r1.cy - r2.cy) <= r1.yrad + r2.yrad) then

            local xoffset = (math.abs(r1.cx - r2.cx) - (r1.xrad + r2.xrad))/2 -- is negative
            local yoffset = (math.abs(r1.cy - r2.cy) - (r1.yrad + r2.yrad))/2 -- is negative

            --print(xoffset, yoffset)

            if math.abs(xoffset) < math.abs(yoffset) then       
                local v = (r1.weight * r1.velx + r2.weight * r2.velx) / (r1.weight + r2.weight)
                r1.velx = v
                r2.velx = v

                if r1.cx < r2.cx then -- r1 left of r2
                    r1.cx = r1.cx + xoffset -- cx gets decreased (moves left)
                    if r1.grav == RIGHT then r1.onfloor = true end
                    r2.cx = r2.cx - xoffset -- cx gets increased (moves right)
                    if r2.grav == LEFT then r2.onfloor = true end
                else
                    r1.cx = r1.cx - xoffset -- cx gets decreased (moves left)
                    if r1.grav == LEFT then r1.onfloor = true end
                    r2.cx = r2.cx + xoffset -- cx gets increased (moves right)
                    if r2.grav == RIGHT then r2.onfloor = true end
                end
            else
                local v = (r1.weight * r1.vely + r2.weight * r2.vely) / (r1.weight + r2.weight)
                r1.vely = v
                r2.vely = v

                if r1.cy < r2.cy then
                    r1.cy = r1.cy + yoffset -- cy gets decreased (moves up)
                    if r1.grav == DOWN then r1.onfloor = true end
                    r2.cy = r2.cy - yoffset -- cy gets increased (moves down)
                    if r2.grav == UP then r2.onfloor = true end
                else
                    r1.cy = r1.cy - yoffset -- cy gets decreased (moves up)
                    if r1.grav == UP then r1.onfloor = true end
                    r2.cy = r2.cy + yoffset -- cy gets increased (moves down)
                    if r2.grav == DOWN then r2.onfloor = true end
                end
            end
        end
    end
end

fieldInit()
wurstfield = field

function collidecell(r, nx, ny)
    
    local curcell = wurstfield:get(nx,ny)
    
    if curcell.colTop == true then
        local wall = rigidbody(nx+0.5, ny, 0.5+WALLPERC, WALLPERC, "crate.png", 0, 0, 0, 99999999, DOWN)
        collide(r,wall)
    end

    if curcell.colLeft == true then
        local wall = rigidbody(nx, ny+0.5, WALLPERC, 0.5+WALLPERC, "crate.png", 0, 0, 0, 99999999, DOWN)
        collide(r,wall)
    end
end

function collidewall(r)
    local wx = math.floor(r.cx)
    local wy = math.floor(r.cy)
    
    -- TODO: TAKE NEW ORIENTATION INTO ACCOUNT
    collidecell(r, wx, wy)
    nx,ny = wurstfield:go(wx,wy,DOWN)
    collidecell(r, nx, ny)
    nx,ny = wurstfield:go(wx,wy,UP)
    collidecell(r, nx, ny)
    nx,ny = wurstfield:go(wx,wy,LEFT)
    collidecell(r, nx, ny)
    nx,ny = wurstfield:go(wx,wy,RIGHT)
    collidecell(r, nx, ny)
    nx,ny = wurstfield:go(wx,wy,RIGHT)
    nx,ny = wurstfield:go(nx,ny,UP)
    collidecell(r, nx, ny)
    nx,ny = wurstfield:go(wx,wy,RIGHT)
    nx,ny = wurstfield:go(nx,ny,DOWN)
    collidecell(r, nx, ny)
    nx,ny = wurstfield:go(wx,wy,LEFT)
    nx,ny = wurstfield:go(nx,ny,DOWN)
    collidecell(r, nx, ny)
    nx,ny = wurstfield:go(wx,wy,LEFT)
    nx,ny = wurstfield:go(nx,ny,UP)
    collidecell(r, nx, ny)
    
end
