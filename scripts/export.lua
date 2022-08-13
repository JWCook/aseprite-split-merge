local src_sprite = app.activeSprite
if not src_sprite then return print('No active sprite') end

local dest_sprite = Sprite(src_sprite)
local start_frame = 1
local end_frame = 3

local path, basename = src_sprite.filename:match("^(.+[/\\])(.-).([^.]*)$")
local dest_filename = path .. basename .. '_' .. start_frame .. '-' .. end_frame .. '.aseprite'
print(dest_filename)

-- local data =
--   Dialog():entry{ id="user_value", label="User Value:", text="Default User" }
--           :button{ id="confirm", text="Confirm" }
--           :button{ id="cancel", text="Cancel" }
--           :show().data
-- if data.confirm then
--   app.alert("The given value is '" .. data.user_value .. "'")
-- end

local n_frames = end_frame - start_frame + 1
print('Copying ' .. n_frames .. ' frames')
print('From: ' .. src_sprite.filename)
print('To:   ' .. dest_filename)

-- Start with a copy of source file, and delete any frames not in range
-- (easier than copying individual frames, tags, etc.)
-- Iterate in reverse order so we can delete frames without changing indices
for i = #src_sprite.frames, 1, -1 do
  if not (i >= start_frame and i <= end_frame) then
    dest_sprite:deleteFrame(i)
  end
end

dest_sprite:saveAs(dest_filename)
