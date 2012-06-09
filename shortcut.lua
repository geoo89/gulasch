gr = love.graphics
font = love.font
audio = love.audio
fs = love.filesystem
img = love.image
thread = love.thread
timer = love.timer
kb = love.keyboard
mouse = love.mouse

function map(tbl, f)
  for k,v in pairs(tbl) do tbl[k] = f(v,k) end
  return tbl
end

function table.find(l, e) -- find element v of l satisfying f(v)
  for i, v in ipairs(l) do
    if v == e then
      return i
    end
  end
  return nil
end
