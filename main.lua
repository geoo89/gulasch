require 'shortcut'
require 'render'
require 'textures'
require 'vector'
require 'object'

RESX=800
RESY=600

function love.load()
    -- print("Test")
    assert(gr.setMode(RESX, RESY), "Could not set screen mode")
    loadTextures()
    --fieldInit()
    isPaused = false
    
    ps = gr.newParticleSystem(textures["particle.png"], 32)
    ps:setEmissionRate(100)
    ps:setParticleLife(0.5,5)
    ps:setRadialAcceleration(100,500)
    ps:setTangentialAcceleration(100,400)
    ps:setSizeVariation(1)
    ps:setSpread(2*math.pi)
    ps:setSpeed(1,5)
    ps:setSpin(0,2*math.pi,1)
    ps:start()
    
    local v = vector.new(1, 2)
    local w = vector.new(3, 5)
    print(v .. w .. (v + w) .. (v - w) .. (v * w) .. (2 * v) .. (v * 3) .. v.length() .. v.ortho() .. v.dot(w))
end

function love.draw()
    gr.setBackgroundColor(0, 0, 0)
    gr.clear()
    gr.print(timer.getFPS(),10,10,0,1,1)
    --print(timer.getFPS())
    --gr.print("Hello World", 400, 300)
    --gr.draw(ps, 100, 100)
   
    render:add(textures["particle.png"], 90, 90, -1, 255, -1, 1)
    render:add(textures["particle.png"], 90, 90, -1, 255, -1, 1, math.rad(45))
    --render:add(textures["particle.png"], 90, 90, -1, 255, 1, 1)
    render:add(textures["particle.png"], 100, 100, 0, 150, 1, 1)
    render:add(textures["particle.png"], 110, 110, 1, 255, 1, 1)
    for i,v in pairs(objects) do
        v:render()
    end
    --render:add(textures[player.img], (player.cx - player.xrad) * 128, (player.cy - player.yrad) * 128, player.z, 255)
    --render:add(ps, 200, 200, 0, 10)
    --field:shade()
    render:draw()
end

cnt = 0

function love.update(dt)
    if isPaused then
        return
    end
    
    ps:update(dt)
    
    objects = map(objects, function(o) return o:update(dt) end)
    
    for i1,v1 in pairs(objects) do
        for i2,v2 in pairs(objects) do
            if (i1 < i2) then collide(v1,v2) end
        end
    end
    
    
    player:move(dt)
    
    --if love.keyboard.isDown("up") then
    --cnt = cnt + 1
    --print(cnt)
    --end
end

function love.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
end

function love.keypressed(key, unicode)

end

function love.focus(f)
    isPaused = not f
end

function love.quit()
  print("Thanks for playing! Come back soon!")
end
