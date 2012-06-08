function object()
    local o = {}
    --[[
    o.cx
    o.cy
    o.xrad
    o.yrad
    o.img
    o.z]]
    
    return o
end

function rigidBody()
    local object = entity()
    --[[
    object.velx
    object.vely
    object.weight
    object.grav --enum
    ]]
    return object
end

function player()
    local player = rigidBody();
    player.
    player.px, player.py = 0.5, 0.5
    player.
    
    return player
end

