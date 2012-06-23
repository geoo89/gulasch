require 'shortcut'
require 'render'
require 'textures'
require 'vector'
require 'field'
require 'object'
require 'editor'
require 'text'
require 'archiver'

RESX=1024
RESY=768

MODE = {
    RENDER = 0,
    EDITOR = 1
}

-- Global frame counter
global_frame = 1
frame_accum = 0
ANIM_DT = 0.01

mode = MODE.EDITOR

function love.load()
    -- print("Test")
    assert(gr.setMode(RESX, RESY, false, false), "Could not set screen mode")

    textures:init()
    editor:init()
    text:init()
    isPaused = false
    
    --ps = gr.newParticleSystem(textures["particle.png"], 32)
    --ps:setEmissionRate(100)
    --ps:setParticleLife(0.5,5)
    --ps:setRadialAcceleration(100,500)
    --ps:setTangentialAcceleration(100,400)
    --ps:setSizeVariation(1)
    --ps:setSpread(2*math.pi)
    --ps:setSpeed(1,5)
    --ps:setSpin(0,2*math.pi,1)
    --ps:start()
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
    text:print(timer.getFPS() .. ' fps')
    text:print(editor.level_list[editor.level_idx])
    --text:print(timer.getFPS(), 100, 100, 50)
    text:print("Move crate to goal", 20, {255, 255, 255, 255})
    if WON==true then 
        text:print("A winner is you!", 20) 
    end
    
    text:draw()
end

cnt = 0
dt = 0

function love.update(dt_local)
    dt = dt_local
    if isPaused then
        return
    end
    
    if (dt > 0.05) then dt = 0.05 end

    frame_accum = frame_accum + dt
    if (frame_accum > ANIM_DT) then
        global_frame = global_frame + math.floor(frame_accum / ANIM_DT)
        frame_accum = frame_accum % ANIM_DT
    end
    
    if mode == MODE.RENDER then
        player:move(dt)

        objects = map(objects, function(o) return o:update(dt) end)
        
--        for i1,v1 in pairs(objects) do
--            for i2,v2 in pairs(objects) do
--                if (i1 < i2) then collide(v1,v2) end
--            end
--        end

--        for i1,v1 in pairs(objects) do
--            collidewall(v1)
--        end

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

    if (key == 'p') then
        if mode == MODE.RENDER then
            isPaused = not isPaused
        end
    end
    
    if (key == 'e') then
        if mode == MODE.RENDER then
            import('current.txt')
            mode = MODE.EDITOR
        else
            editor.half_open = nil
            export('current.txt')
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
