local IMG_DIR = "img/"
textures = {}

-- Preloads images from IMG_DIR
function loadTextures() 
    for i,v in ipairs(fs.enumerate(IMG_DIR)) do
        local file = IMG_DIR .. "/" .. v
        if fs.isFile(file) then
            textures[v] = gr.newImage(file)
        end
    end
end
