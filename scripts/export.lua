-- Usage:
-- aseprite -b sprites/Animals.aseprite \
--    --script-param start-frame=1 \
--    --script-param end-frame=10 \
--    --script scripts/export.lua


-- Test if an array contains a value
local function contains(array, value)
  for _, value in ipairs(array) do
    if value == value then
      return true
    end
  end
  return false
end

-- Get the length of an array
local function len(array)
  local count = 0
  for _, _ in ipairs(array) do
    count = count + 1
  end
  return count
end

local src_sprite = app.activeSprite
if not src_sprite then return print('No active sprite') end

local dest_sprite = Sprite(src_sprite.spec)
local start_frame = tonumber(app.params['start-frame']) or 1
local frame_offset = start_frame - 1

local end_frame = tonumber(app.params['end-frame']) or len(src_sprite.frames)
local path, basename = src_sprite.filename:match("^(.+[/\\])(.-).([^.]*)$")
local dest_filename = path .. basename .. '_' .. start_frame .. '-' .. end_frame .. '.aseprite'

-- local data =
--   Dialog():entry{ id="start_frame", label="Start:", text="1" }
--           :entry{ id="end_frame", label="End:", text="10" }
--           :button{ id="confirm", text="Confirm" }
--           :button{ id="cancel", text="Cancel" }
--           :show().data
-- if data.confirm then
--   app.alert("The given value is '" .. data.user_value .. "'")
-- end

local n_frames = end_frame - start_frame + 1
print('Copying ' .. n_frames .. ' frames')
print('  From: ' .. src_sprite.filename)
print('  To:   ' .. dest_filename)


dest_sprite:deleteLayer('Layer 1')

-- Copy layers
local dest_layers = {}
for _, layer in ipairs(src_sprite.layers) do

  -- Copy layer metadata
  local new_layer = dest_sprite:newLayer(layer)
  new_layer.blendMode = layer.blendMode
  new_layer.color = layer.color
  new_layer.data = layer.data
  new_layer.isCollapsed = layer.isCollapsed
  new_layer.isContinuous = layer.isContinuous
  new_layer.isEditable = layer.isEditable
  new_layer.isVisible = layer.isVisible
  new_layer.name = layer.name
  new_layer.opacity = layer.opacity

  -- Index new frame by name
  dest_layers[layer.name] = new_layer
end


-- Copy cels
for _, cel in ipairs(src_sprite.cels) do
  if cel.frameNumber >= start_frame and cel.frameNumber <= end_frame then
    -- Create new frame, if needed
    local dest_frame = cel.frameNumber - frame_offset
    if dest_frame > #dest_sprite.frames then
      dest_sprite:newFrame()
    end

    local layer = dest_layers[cel.layer.name]
    print(cel.frameNumber, dest_frame, cel.position)
    dest_sprite:newCel(layer, dest_frame, cel.image, cel.position)
  end
end

-- Copy tags
for _, tag in ipairs(src_sprite.tags) do
  local src_start = tag.fromFrame.frameNumber
  local src_end = tag.toFrame.frameNumber

  if src_start <= end_frame or src_end >= start_frame then
    -- Adjust tag frame range to be within selection frame range
    local dest_start = math.max(1, src_start - frame_offset)
    local dest_end = math.min(len(dest_sprite.frames), src_end - frame_offset)
    print('Copying tag', tag.name)

    -- Copy tag + metadata to adjusted range
    local new_tag = dest_sprite:newTag(dest_start, dest_end)
    new_tag.color = tag.color
    new_tag.data = tag.data
    new_tag.name = tag.name
  end
end

-- Save new sprite
dest_sprite:saveAs(dest_filename)
