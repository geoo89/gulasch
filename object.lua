require 'field'
require 'constants'

function object(cx, cy, xrad, yrad, img, z)
    local o = {}
    o.typ = "object"
    o.cx = cx
    o.cy = cy
    o.xrad = xrad
    o.yrad = yrad
    o.z = z or 0
    o.mirrored = false
    o.grav = DOWN
    o.img = img
    o.phase = 10
    
    --Sekti: Objects should be able to maintain non-physical subobjects.
    --example:
        --Player has Eyes, Mouth.
        --Chest could glow when they stand on a button
        --Saw may have it's spinning blade as a different subobjects every frame
        --Saw may want to spawn blood or wood-splinter particles
        --You get the idea.
        --These objects are NOT in the object table and will therefore never be in the editor or in a savegame.
        --The effective z prio of any subobject o will be one plus the priority of the parent plus its own prio
        --Position, zprio, grav etc of any subobject will be relative to the parent.
    function o:Subobjects() return {} end
    function o:placeSubobject(relx,rely)
        local sub = object(self.cx, self.cy, self.xrad, self.yrad, nil, self.z + 1)
        sub.grav = self.grav
        sub.mirrored = self.mirrored
        
        dx, dy = dirtodxy(sub.grav)
        sub.cx, sub.cy = sub.cx + dx * rely, sub.cy + dy * rely
        
        dx, dy = dirtodxy(mirrored and -nextdir(sub.grav) or nextdir(sub.grav))
        sub.cx, sub.cy = sub.cx + dx * relx, sub.cy + dy * relx
        return sub
    end
    
    function o:update() 
        
        return self 
    end
    
    --function o:render()
    --    render:add(textures[o.img[o.frame]], (o.cx - o.xrad - 1) * 128, (o.cy - o.yrad - 1) * 128, o.z, 255)
    --end
    
    return o
end

function rigidbody(cx, cy, xrad, yrad, img, z, velx, vely, weight, grav)
    local o = object(cx, cy, xrad, yrad, img, z)
    o.rigid = true
    o.typ = "rigidbody"
    o.velx = velx or 0
    o.vely = vely or 0
    o.weight = weight or 1
    o.grav = grav or DOWN
    
    o.update = function(self, dt)
        local ax, ay = dirtodxy(o.grav)
        o.velx = o.velx + GRAV_STRENGTH * ax * dt
        o.vely = o.vely + GRAV_STRENGTH * ay * dt
        
        if (o.velx < -VEL_CAP) then o.velx = -VEL_CAP end
        if (o.velx > VEL_CAP) then o.velx = VEL_CAP end
        if (o.vely < -VEL_CAP) then o.vely = -VEL_CAP end
        if (o.vely > VEL_CAP) then o.vely = VEL_CAP end
        
        o:movex(o.velx * dt)
        o:movey(o.vely * dt)
        
        self.onfloor = false;
        
--        for i1,v1 in pairs(objects) do
--            if (self ~= v1) then collide(self,v1) end
--        end

        o.tempfriction = {
            left  = 0.0,
            right = 0.0,
            above = 0.0,
            below = 0.0
        }

        collide(self)
        
        collidewall(self)
        
        return self
    end
    
    --use this routines to move objects, never modify cx and cy directly
    function o.movex(self, dx)
        if math.abs(dx) > 1 then
            dx=1
            print("warning, dx = "..dx)
        end
        o:moverel(dx,0)
    end

    function o.movey(self, dy)
        if math.abs(dy) > 1 then
            dy=1
            print("warning, dy = "..dy)
        end
        o:moverel(0,dy)
    end
    
    -- either dx or dy must be 0
    function o.moverel(self,dx,dy)
        local intx = math.floor(o.cx)
        local inty = math.floor(o.cy)
        
        o.cx = o.cx + dx
        o.cy = o.cy + dy
        
        local intx2 = math.floor(o.cx)
        local inty2 = math.floor(o.cy)
        local fx = o.cx % 1
        local fy = o.cy % 1
        
        local dx = intx2 - intx
        local dy = inty2 - inty
        
        if dx == 0 and dy == 0 then return nil end
        
        assert(dx==0 or dy == 0, "shitty direction"..dx..dy);
        assert(math.abs(dx) == 1 or math.abs(dy) == 1, "shitty direction"..dx..dy);
        
        --print("dx",dx,dy)
        --print(fx,fy)
        
        local dir = dxytodir(dx,dy)
        local ndir
        local rgtdir
        local dwndir
        local oldgrav = o.grav
        newx, newy, ndir, o.grav = field:go(intx, inty, dir, o.grav)
        if math.abs(oldgrav) ~= math.abs(o.grav) then
            o.xrad, o.yrad = o.yrad, o.xrad
        end
        newx, newy, ndir, rgtdir = field:go(intx, inty, dir, RIGHT)
        newx, newy, ndir, dwndir = field:go(intx, inty, dir, DOWN)
        --print(dir, rgtdir, dwndir)
        if (rgtdir ~= nextdir(dwndir)) then o.mirrored = not o.mirrored end
        
        fx,fy = transformOffset(fx,fy,dwndir,rgtdir)
        --print(fx,fy)
        o.cx = newx + fx
        o.cy = newy + fy
        
        local vx = o.velx
        local vy = o.vely
        vx,vy = transformOffset(vx+0.5,vy+0.5,dwndir,rgtdir)
        o.velx = vx - 0.5
        o.vely = vy - 0.5
        
        return ndir
    end

    return o
end

function makeplayer(cx, cy)
    local p = rigidbody(cx, cy, 0.25, 0.25, "player.png", 999, 0, 0, 2, DOWN);
    p.typ = "makeplayer"
    
    p.onfloor = true
    --p.cx, p.cy = 2.5, 2.5
    --p.xrad, p.yrad = 0.25, 0.25
    --p.velx, p.vely = 0,0
    --p.weight = 2
    --p.grav = DOWN
    --p.z = 999
    --p.img = "player.png"
    
    --player eyes and mouth
    
    p.Subobjects = function(self)
        local pupils = p:placeSubobject(0, 0)
        pupils.img = "pupils_centered.png"
        local mouth = p:placeSubobject(0, 0)
        
        local dx, dy = 0, 0
        local downx, downy = dirtodxy(p.grav)
        
        fact = math.sqrt(p.velx*p.velx + p.vely*p.vely)
        if (math.abs(fact) > 0.0001) then
            dx   = 0.025 * p.velx / fact
            dy   = 0.025 * p.vely / fact
            
            pupils.cx, pupils.cy = pupils.cx + dx, pupils.cy + dy
        end
        
        if (p.onfloor or (dx == 0 and dy == 0)) then
            mouth.img = "mouth_standing.png"
        elseif (downx ~= 0 and downx * dx > 0) or (downy * dy > 0) then
            mouth.img = "mouth_worried.png"
        else
            mouth.img = "mouth_excited.png"
        end
            
        return {pupils, mouth}
    end
    
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

        --if self.onfloor then 
        --    self.velx = (1 - x_floor) * self.velx
        --    self.vely = (1 - y_floor) * self.vely
        --end

        if kb.isDown('left') then
            if self.onfloor then
                if x_floor ~= 0 then
                    --self.velx = -FLOOR_SPEED * x_floor
                    self.velx = -x_floor*math.min(FLOOR_SPEED, math.abs(self.velx) + dt * FLOOR_ACCEL)
                end
                if y_floor ~= 0 then
                    --self.vely = -FLOOR_SPEED * y_floor
                    self.vely = -y_floor*math.min(FLOOR_SPEED, math.abs(self.vely) + dt * FLOOR_ACCEL)
                end
            else 
                self.velx = self.velx - dt * AIR_ACCEL * x_floor
                self.vely = self.vely - dt * AIR_ACCEL * y_floor
            end
        elseif kb.isDown('right') then
            if self.onfloor then 
                if x_floor ~= 0 then
                    --self.velx = FLOOR_SPEED * x_floor
                    self.velx = x_floor*math.min(FLOOR_SPEED, math.abs(self.velx) + dt * FLOOR_ACCEL)
                end
                if y_floor ~= 0 then
                    --self.vely = FLOOR_SPEED * y_floor
                    self.vely = y_floor*math.min(FLOOR_SPEED, math.abs(self.vely) + dt * FLOOR_ACCEL)
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

function transformcollide(r1,dx,dy)
    local dirx = r1:moverel(dx,0)
    local diry = r1:moverel(0,dy)
    --r1:movex(dx)
    --r1:movey(dy)
    for i2,r2 in pairs(objects) do
        if (r1 ~= r2) then
            if math.floor(r1.cx) == math.floor(r2.cx) and math.floor(r1.cy) == math.floor(r2.cy) then
                r1.cx = r1.cx - dx
                r1.cy = r1.cy - dy
                collide1(r1,r2)
                r1.cy = r1.cy + dy
                r1.cx = r1.cx + dx
            end
        end
    end

    --r1:movey(-dy)
    --r1:movex(-dx)
    if diry ~= nil then
        ndx, ndy = dirtodxy(diry)
        r1:moverel(-ndx,-ndy)
    end
    if dirx ~= nil then
        ndx, ndy = dirtodxy(dirx)
        r1:moverel(-ndx,-ndy)
    end
end

function collide(r1)
    local intx, inty = math.floor(r1.cx), math.floor(r1.cy);
    local cell = field:get(intx,inty)
    
    transformcollide(r1, 0, 0)
    
    for _,dir in pairs(DIRS) do
        if (not field:hasWall(intx,inty,dir)) then
            local dx,dy = dirtodxy(dir)
            transformcollide(r1, dx, dy);
            
            if(dir == LEFT or dir == RIGHT) then
                local intx2,inty2,newdir,up = field:go(intx,inty,dir,UP);
                if (not field:hasWall(intx2,inty2,up)) then
                    transformcollide(r1, dx, 1)
                end    
                if (not field:hasWall(intx2,inty2,-up)) then
                    transformcollide(r1, dx, -1)
                end
            end
        end
    end
end

-- assumes both items are in the same coordinate system
-- r2 will not be moved, its velocities may be affected though
-- r1 may be moved out of the range of r2
function collide1(r1, r2)
    if (r1.rigid and r2.rigid) then
        
        local intx1 = math.floor(r1.cx)
        local inty1 = math.floor(r1.cy)
        local intx2 = math.floor(r2.cx)
        local inty2 = math.floor(r2.cy)
        
--        if intx1 ~= intx2 or inty1 ~= inty2 then return end
    
        if (math.abs(r1.cx - r2.cx) <= r1.xrad + r2.xrad and math.abs(r1.cy - r2.cy) <= r1.yrad + r2.yrad) then

            local xoffset = math.abs(r1.cx - r2.cx) - (r1.xrad + r2.xrad) -- is negative
            local yoffset = math.abs(r1.cy - r2.cy) - (r1.yrad + r2.yrad) -- is negative
            
            --local dt = 0.02

            --print(xoffset, yoffset)
            -- adding offset should check whether a border is crossed and should be done last

            if math.abs(xoffset) < math.abs(yoffset) then       
                -- like this: [][]
                local friction = 0
                local v = (r1.weight * r1.velx + r2.weight * r2.velx) / (r1.weight + r2.weight)
                if r1.weight > 99999 or r2.weight > 99999 then v=0 end
                r1.velx = v
                r2.velx = v

                if r1.cx < r2.cx then -- like this: [r1][r2]
                    r1:movex(xoffset) -- cx gets decreased (r1 moves left)
                    if r1.grav == RIGHT then
                        r1.onfloor = true
                        if (r1.weight < 99999) then friction = math.max(0, r1.weight-r1.tempfriction.right) end
                        r1.tempfriction.right = friction
                    end
                    --r2:movex(-xoffset) -- cx gets increased (r2 moves right)
                    if r2.grav == LEFT then
                        r2.onfloor = true
                        if (r2.weight < 99999) then friction = r2.weight end
                    end
                else -- like this: [r2][r1]
                    r1:movex(-xoffset) -- cx gets decreased (r1 moves right)
                    if r1.grav == LEFT then
                        r1.onfloor = true
                        if (r1.weight < 99999) then friction = math.max(0, r1.weight-r1.tempfriction.left) end
                        r1.tempfriction.left = friction
                    end
                    --r2:movex(xoffset) -- cx gets increased (r2 moves left)
                    if r2.grav == RIGHT then
                        r2.onfloor = true
                        if (r2.weight < 99999) then friction = r2.weight end
                    end
                end

                --apply friction 1
                local accel1 = FRICTION * friction / r1.weight
                if (r1.vely > 0) then
                    r1.vely = r1.vely - accel1 * dt
                    if r1.vely < 0 then r1.vely = 0 end
                else
                    r1.vely = r1.vely + accel1 * dt
                    if r1.vely > 0 then r1.vely = 0 end
                end
                
                --apply friction 2
                local accel2 = FRICTION * friction / r2.weight
                if (r2.vely > 0) then
                    r2.vely = r2.vely - accel2 * dt
                    if r2.vely < 0 then r2.vely = 0 end
                else
                    r2.vely = r2.vely + accel2 * dt
                    if r2.vely > 0 then r2.vely = 0 end
                end

            else
                -- like this: []
                --            []
                local friction = 0
                local v = (r1.weight * r1.vely + r2.weight * r2.vely) / (r1.weight + r2.weight)
                if r1.weight > 99999 or r2.weight > 99999 then v=0 end
                r1.vely = v
                r2.vely = v

                if r1.cy < r2.cy then -- like this: [r1]
                                      --            [r2]
                    r1:movey(yoffset) -- cy gets decreased (r1 moves up)
                    if r1.grav == DOWN then
                        r1.onfloor = true
                        if (r1.weight < 99999) then friction = math.max(0, r1.weight-r1.tempfriction.below) end
                        r1.tempfriction.below = friction
                    end
                    --r2:movey(-yoffset) -- cy gets increased (r2 moves down)
                    if r2.grav == UP then
                        r2.onfloor = true
                        if (r2.weight < 99999) then friction = r2.weight end
                    end
                else -- like this: [r2]
                     --            [r1]
                    r1:movey(-yoffset) -- cy gets decreased (r1 moves down)
                    if r1.grav == UP then
                        r1.onfloor = true
                        if (r1.weight < 99999) then friction = math.max(0, r1.weight-r1.tempfriction.above) end
                        r1.tempfriction.above = friction
                    end
                    --r2:movey(yoffset) -- cy gets increased (r2 moves up)
                    if r2.grav == DOWN then
                        r2.onfloor = true
                        if (r2.weight < 99999) then friction = r2.weight end
                    end
                end

                --apply friction 1
                local accel1 = FRICTION * friction / r1.weight
                if (r1.velx > 0) then
                    r1.velx = r1.velx - accel1 * dt
                    if r1.velx < 0 then r1.velx = 0 end
                else
                    r1.velx = r1.velx + accel1 * dt
                    if r1.velx > 0 then r1.velx = 0 end
                end
                
                --apply friction 2
                local accel2 = FRICTION * friction / r2.weight
                if (r2.velx > 0) then
                    r2.velx = r2.velx - accel2 * dt
                    if r2.velx < 0 then r2.velx = 0 end
                else
                    r2.velx = r2.velx + accel2 * dt
                    if r2.velx > 0 then r2.velx = 0 end
                end
            end
        end
    end
end

function collidecell(r, nx, ny)
    
    local curcell = field:get(nx,ny)
    
    if field:hasWall(nx,ny,TOP) then
        local wall = rigidbody(nx+0.5, ny, 0.5+WALLPERC, WALLPERC, "crate.png", 0, 0, 0, 99999999, DOWN)
        collide1(r,wall)
    end
    
    if field:hasWall(nx,ny,RIGHT) then
        local wall = rigidbody(nx + 1, ny+0.5, WALLPERC, 0.5 + WALLPERC, "crate.png", 0, 0, 0, 99999999, DOWN)
        collide1(r,wall)
    end

    if field:hasWall(nx,ny,LEFT) then
        local wall = rigidbody(nx, ny+0.5, WALLPERC, 0.5+WALLPERC, "crate.png", 0, 0, 0, 99999999, DOWN)
        collide1(r,wall)
    end
    
    if field:hasWall(nx,ny,DOWN) then
        local wall = rigidbody(nx+0.5, 1+ny, 0.5+WALLPERC, WALLPERC, "crate.png", 0, 0, 0, 99999999, DOWN)
        collide1(r,wall)
    end
end

function collidewall(r)
    local wx = math.floor(r.cx)
    local wy = math.floor(r.cy)
    
    -- TODO: TAKE NEW ORIENTATION INTO ACCOUNT
    collidecell(r, wx, wy)
    
    if(not field:hasWall(wx,wy,DOWN)) then
        nx,ny = field:go(wx,wy,DOWN)
        collidecell(r, nx, ny)
    end
    
    if(not field:hasWall(wx,wy,UP)) then
        nx,ny = field:go(wx,wy,UP)
        collidecell(r, nx, ny)
    end
    
    if(not field:hasWall(wx,wy,LEFT)) then
        nx,ny = field:go(wx,wy,LEFT)
        collidecell(r, nx, ny)
    end
    
    if(not field:hasWall(wx,wy,RIGHT)) then
        nx,ny = field:go(wx,wy,RIGHT)
        collidecell(r, nx, ny)
    end
end
