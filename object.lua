function object(cx, cy, xrad, yrad, img, z)
    local o = {}
    o.cx = cx
    o.cy = cy
    o.xrad = xrad
    o.yrad = yrad
    o.img = img
    o.z = z or 0
    
    return o
end

function rigidbody(cx, cy, xrad, yrad, img, z, velx, vely, weight, grav)
    local o = object(cx, cy, xrad, yrad, img, z)
    o.velx = velx or 0
    o.vely = vely or 0
    o.weight = weight or 1
    o.grav = grav or DOWN

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

    return p
end

player = makeplayer(2.5, 2.5)

objects = {player}