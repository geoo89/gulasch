require 'field'

function object(cx, cy, xrad, yrad, img, z)
    local o = {}
    o.cx = cx
    o.cy = cy
    o.xrad = xrad
    o.yrad = yrad
    o.img = img
    o.z = z or 0
    
    function o:update() return self end
    
    function o:render()
        render:add(textures[o.img], (o.cx - o.xrad) * 128, (o.cy - o.yrad) * 128, o.z, 255)
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
        o.velx = o.velx + ax * dt
        o.vely = o.vely + ay * dt
        
        o.cx = o.cx + o.velx * dt
        o.cy = o.cy + o.vely * dt
        
        return self
    end

    return o
end

function makeplayer(cx, cy)
    local p = rigidbody(cx, cy, 0.25, 0.25, "player.png", 0, 0, 0, 2, DOWN);
    --p.cx, p.cy = 2.5, 2.5
    --p.xrad, p.yrad = 0.25, 0.25
    --p.velx, p.vely = 0,0
    --p.weight = 2
    --p.grav = DOWN
    --p.z = 999
    --p.img = "player.png"
    
    function p:move(dt)
        if kb.isDown('up') then self.cy = self.cy - dt end 
        if kb.isDown('down') then self.cy = self.cy + dt end
        if kb.isDown('left') then self.cx = self.cx - dt end
        if kb.isDown('right') then self.cx = self.cx + dt end
    end

    return p
end

player = makeplayer(2.5, 2.5)

o1 = rigidbody(3.5, 1.5, 0.0625, 0.0625, "crate.png", 1, 0, 0, 1, DOWN)
o2 = rigidbody(3.5, 3.5, 0.0625, 0.0625, "crate.png", 1, 0, 0, 1, UP)
o3 = object(2.5, 1.5, 0.0625, 0.0625, "crate.png", 1)

objects = {player, o1, o2, o3}

function collide(r1, r2)
    if (r1.rigid and r2.rigid) then
    
        if (math.abs(r1.cx - r2.cx) <= r1.xrad + r2.xrad and math.abs(r1.cy - r2.cy) <= r1.yrad + r2.yrad) then
            local v = (r1.weight * r1.velx + r2.weight * r2.velx) / (r1.weight + r2.weight)
            r1.velx = v
            r2.velx = v
            
            local offset = math.abs(r1.cx - r2.cx) - (r1.xrad + r2.xrad)
            if r1.cx < r2.cx then
                r1.cx = r1.cx + offset
                r2.cx = r2.cx - offset
            end

            local v = (r1.weight * r1.vely + r2.weight * r2.vely) / (r1.weight + r2.weight)
            r1.vely = v
            r2.vely = v
    
            local offset = math.abs(r1.cy - r2.cy) - (r1.yrad + r2.yrad)
            if r1.cy < r2.cy then
                r1.cy = r1.cy + offset
                r2.cy = r2.cy - offset
            end
        end
    end
end