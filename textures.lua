local IMG_DIR = "img/"
textures = {}

-- Preloads images from IMG_DIR
function textures:init() 
    for i,v in ipairs(fs.enumerate(IMG_DIR)) do
        local file = IMG_DIR .. "/" .. v
        if fs.isFile(file) then            
            local base, cnt, ext = string.match(v, "(.+)_([0-9]+)\.(.+)")
            --print(v, " base: ", base, " cnt: ", cnt, " ext: ", ext)        

            -- Is it an animation?
            if base then
                cnt = tonumber(cnt)
                local name = base .. "." .. ext
                local o = self[name]
                if (not o) then
                    self[name] = {}
                    o = self[name]
                    o.cur = 1
                    o.frame = cnt
                    o.last = cnt
                    o.img = {}
                end
                
                print("Adding animation: " .. name)
                o.last = math.max(o.last, cnt)
                o.img[cnt] = gr.newImage(file)
            else
                self[v] = {}
                local o = self[v]
                o.cur = 1
                o.frame = 1
                o.last = 1
                o.img = {}
                o.img[1] = gr.newImage(file)
            end
        end
    end
    
    -- Fill remaining frames with corresponding images
    for _, o in pairs(self) do
        if (type(o) == 'table') then
            local cur = o.img[o.last]
            for i = 1, o.last do
                if o.img[i] then
                    cur = o.img[i]
                else
                    o.img[i] = cur
                end
            end
        end
    end
end
