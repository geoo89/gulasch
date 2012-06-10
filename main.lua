require 'shortcut'
require 'render'
require 'textures'
require 'vector'
require 'field'
require 'object'
require 'editor'
require 'text'
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
    editor:init()
    text:init()
    --isPaused = true
    
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

    -- Draw field
    if mode == MODE.RENDER then
        field:shade()
    else
        editor:shade()
    end
    render:draw()
    
    text:print("x:"..(math.floor(player.cx*100)/100).." y:"..(math.floor(player.cy*100)/100))
    text:print(timer.getFPS())
    text:print(timer.getFPS(), 100, 100, 50)
    text:print("Move crate to goal", 20)
    if WON==true then 
        text:print("A winner is you!", 20) 
    end
    
    text:draw()
end

cnt = 0

function love.update(dt)
    if isPaused then
        return
    end
    
    if (dt > 0.05) then dt = 0.05 end

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
        editor:mouseMoved(mouse.getX(), mouse.getY())
        editor:update(dt)
    end
    --if love.keyboard.isDown("up") then
    --cnt = cnt + 1
    --print(cnt)
    --end
end

function love.mousepressed(x, y, button)
    if mode == MODE.EDITOR then
        editor:mousePressed(x, y, button)
    end
end

function love.mousereleased(x, y, button)
    if mode == MODE.EDITOR then
        editor:mouseReleased(x, y, button)
    end
end

function love.keypressed(key, unicode)
    if (key == 'q') then
        os.exit()
    end

    isPaused = false
    
    if (key == 'e') then
        if mode == MODE.RENDER then
            import('current.txt')
            mode = MODE.EDITOR
        else
            field:export('current.txt')
            mode = MODE.RENDER
        end
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
