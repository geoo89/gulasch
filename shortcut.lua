gr = love.graphics
font = love.font
audio = love.audio
fs = love.filesystem
img = love.image
thread = love.thread
timer = love.timer
kb = love.keyboard

function map(tbl, f)
  for k,v in pairs(tbl) do tbl[k] = f(v,k) end
  return tbl
end
