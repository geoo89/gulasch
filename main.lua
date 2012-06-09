require 'shortcut'
require 'render'
require 'textures'
require 'vector'
require 'field'
require 'object'
require 'editor'
--require 'field'

RESX=800
RESY=600

MODE = {
    RENDER = 0,
    EDITOR = 1
}

mode = MODE.EDITOR

function love.load()
    -- print("Test")
    assert(gr.setMode(RESX, RESY), "Could not set screen mode")
    loadTextures()
    fieldInit()
    isPaused = true
    
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
    gr.print("x:"..(math.floor(player.cx*100)/100).." y:"..(math.floor(player.cy*100)/100), 10, 20, 0,1,1)

    -- Draw field
    if mode == MODE.RENDER then
        field:shade()
    else
        editor:shade()
    end
    render:draw()
    
    gr.print(timer.getFPS(),10,10,0,1,1)
    gr.print("Move crate to goal",10,30,0,1,1)
    if WON==true then gr.print("A winner is you!",30,50,0,1,1) end
end

cnt = 0

function love.update(dt)
    if isPaused then
        return
    end
    
    if mode == MODE.RENDER then
        objects = map(objects, function(o) return o:update(dt) end)
        
        for i1,v1 in pairs(objects) do
            collidewall(v1)
        end
        --collidewall(player)

        for i1,v1 in pairs(objects) do
            for i2,v2 in pairs(objects) do
                if (i1 < i2) then collide(v1,v2) end
            end
        end
        
        player:move(dt)
    else
        editor:update(dt)
    end
    --if love.keyboard.isDown("up") then
    --cnt = cnt + 1
    --print(cnt)
    --end
end

function love.mousepressed(x, y, button)
    if mode == MODE.EDITOR then
        editor:mouse(x, y, button)
    end
end

function love.mousereleased(x, y, button)
end

function love.keypressed(key, unicode)
    if (key == 'q') then
        os.exit()
    end

    isPaused = false
    
    if (key == 'e') then
        mode = 1 - mode
    end
    
    if (mode == MODE.EDITOR) then
        editor:keyboard(key)
    end
end

function love.focus(f)
    isPaused = not f
end

function love.quit()
  print("Thanks for playing! Come back soon!")
end
