require 'field'

JUMP_STRENGTH = 4
GRAV_STRENGTH = 1
AIR_ACCEL = 1
FLOOR_SPEED = 1
VEL_CAP = 4
FRICTION = 4

function object(cx, cy, xrad, yrad, img, z)
    local o = {}
    o.typ = "object"
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
        
        return self
    end
    
    --use this routines to move objects, never modify cx and cy directly
    function o.movex(self, dx)
        o:moverel(dx,0)
    end

    function o.movey(self, dy)
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
        
        if dx==0 and dy == 0 then return self end
        
        --print("dx",dx,dy)
        --print(fx,fy)
        
        local dir = dxytodir(dx,dy)
        local wurst = 0
        local rgtdir
        local dwndir
        
        newx, newy, wurst, o.grav = field:go(intx, inty, dir, o.grav)
        newx, newy, wurst, rgtdir = field:go(intx, inty, dir, RIGHT)
        newx, newy, wurst, dwndir = field:go(intx, inty, dir, DOWN)
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
        
        return self
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

o1 = rigidbody(3.5, 2.5, 0.125, 0.125, "crate.png", 50, 0, 0, 1, DOWN)
o2 = rigidbody(3.5, 3.5, 0.0625, 0.0625, "crate.png", 1, 0, 0, 1, UP)
o3 = object(2.5, 1.5, 0.0625, 0.0625, "crate.png", 1)

objects = {player, o1}

function transformcollide(r1,r2,dx,dy)
    r2:movex(dx)
    r2:movey(dy)
    if math.floor(r1.cx) == math.floor(r2.cx) and math.floor(r1.cy) == math.floor(r2.cy) then
    r2.cx = r2.cx - dx
    r2.cy = r2.cy - dy
        collide1(r1,r2)
    r2.cy = r2.cy + dy
    r2.cx = r2.cx + dx
    end
    r2:movey(-dy)
    r2:movex(-dx)
end

function collide(r1,r2)
    transformcollide(r1,r2, 0, 0)
    transformcollide(r1,r2, 1, 0)
    transformcollide(r1,r2, 0, 1)
    transformcollide(r1,r2,-1, 0)
    transformcollide(r1,r2, 0,-1)
    transformcollide(r1,r2, 1, 1)
    transformcollide(r1,r2,-1, 1)
    transformcollide(r1,r2,-1,-1)
    transformcollide(r1,r2, 1,-1)
end

-- assumes both items are in the same coordinate system
function collide1(r1, r2)
    if (r1.rigid and r2.rigid) then
        
        local intx1 = math.floor(r1.cx)
        local inty1 = math.floor(r1.cy)
        local intx2 = math.floor(r2.cx)
        local inty2 = math.floor(r2.cy)
        
--        if intx1 ~= intx2 or inty1 ~= inty2 then return end
    
        if (math.abs(r1.cx - r2.cx) <= r1.xrad + r2.xrad and math.abs(r1.cy - r2.cy) <= r1.yrad + r2.yrad) then

            local xoffset = (math.abs(r1.cx - r2.cx) - (r1.xrad + r2.xrad))/2 -- is negative
            local yoffset = (math.abs(r1.cy - r2.cy) - (r1.yrad + r2.yrad))/2 -- is negative
            
            local dt = 0.02

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
                        if (r1.weight < 99999) then friction = friction + r1.weight end
                    end
                    r2:movex(-xoffset) -- cx gets increased (r2 moves right)
                    if r2.grav == LEFT then
                        r2.onfloor = true
                        if (r2.weight < 99999) then friction = friction + r2.weight end
                    end
                else -- like this: [r2][r1]
                    r1:movex(-xoffset) -- cx gets decreased (r1 moves right)
                    if r1.grav == LEFT then
                        r1.onfloor = true
                        if (r1.weight < 99999) then friction = friction + r1.weight end
                    end
                    r2:movex(xoffset) -- cx gets increased (r2 moves left)
                    if r2.grav == RIGHT then
                        r2.onfloor = true
                        if (r2.weight < 99999) then friction = friction + r2.weight end
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
                        if (r1.weight < 99999) then friction = friction + r1.weight end
                    end
                    r2:movey(-yoffset) -- cy gets increased (r2 moves down)
                    if r2.grav == UP then
                        r2.onfloor = true
                        if (r2.weight < 99999) then friction = friction + r2.weight end
                    end
                else -- like this: [r2]
                     --            [r1]
                    r1:movey(-yoffset) -- cy gets decreased (r1 moves down)
                    if r1.grav == UP then
                        r1.onfloor = true
                        if (r1.weight < 99999) then friction = friction + r1.weight end
                    end
                    r2:movey(yoffset) -- cy gets increased (r2 moves up)
                    if r2.grav == DOWN then
                        r2.onfloor = true
                        if (r2.weight < 99999) then friction = friction + r2.weight end
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
