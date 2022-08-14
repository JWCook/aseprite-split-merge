-- Usage:
-- src-sprite: sprite to copy from; otherwise use active sprite
-- dest-sprite: sprite to copy to; otherwise create new sprite
-- start-frame: Frame to start copying from; default: 1
-- end-frame: Frame to stop copying from; default: last frame of src-sprite
--
-- Example:
-- aseprite -b sprites/Animals.aseprite \
--    --script-param dest-sprite=sprites/Animals_selection.png \
--    --script-param start-frame=1 \
--    --script-param end-frame=10 \
--    --script scripts/export.lua


-- Get source sprite, either from CLI or from active sprite
local function get_src_sprite()
  if app.activeSprite then
    return app.activeSprite
  elseif app.params['src-sprite'] then
    return Sprite { fromFile = app.params['src-sprite'] }
  else
    error('No sprite selected')
  end
end

-- Get destination sprite, either from CLI or new sprite
local function get_dest_sprite(src_sprite, start_frame, end_frame)
  if app.params['dest-sprite'] then
    return Sprite { fromFile = app.params['dest-sprite'] }
  else
    -- Create new sprite, using source sprite name + frame range as the filename
    local dest_sprite = Sprite(src_sprite.spec)
    local path, basename = src_sprite.filename:match("^(.+[/\\])(.-).([^.]*)$")
    dest_sprite.filename = path .. basename .. '_' .. start_frame .. '-' .. end_frame .. '.aseprite'
    return dest_sprite
  end
end

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

-- Copy layers and associated metadata to new sprite
local function copy_layers(src_sprite, dest_sprite)
  for _, layer in ipairs(src_sprite.layers) do
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
  end

  return dest_sprite
end

-- Copy selected cels to new sprite
local function copy_cels(src_sprite, dest_sprite, start_frame, end_frame)
  local frame_offset = start_frame - 1

  -- Index layers by name
  local layer_idx = {}
  for _, layer in ipairs(dest_sprite.layers) do
    layer_idx[layer.name] = layer
  end

  -- Copy cels
  for _, cel in ipairs(src_sprite.cels) do
    if cel.frameNumber >= start_frame and cel.frameNumber <= end_frame then
      -- Create new frame, if needed
      local dest_frame = cel.frameNumber - frame_offset
      if dest_frame > #dest_sprite.frames then
        dest_sprite:newFrame()
      end

      -- Look up layer by name and add new cel
      local dest_layer = layer_idx[cel.layer.name]
      dest_sprite:newCel(dest_layer, dest_frame, cel.image, cel.position)
    end
  end

  return dest_sprite
end

-- Copy tags and associated metadata for selected frames to new sprite
local function copy_tags(src_sprite, dest_sprite, start_frame, end_frame)
  local frame_offset = start_frame - 1

  for _, tag in ipairs(src_sprite.tags) do
    local src_start = tag.fromFrame.frameNumber
    local src_end = tag.toFrame.frameNumber

    if src_start <= end_frame and src_end >= start_frame then
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

  return dest_sprite
end

-- Gather inputs from CLI (or defaults)
local src_sprite = get_src_sprite()
local start_frame = tonumber(app.params['start-frame']) or 1
local end_frame = tonumber(app.params['end-frame']) or len(src_sprite.frames)
local dest_sprite = get_dest_sprite(src_sprite, start_frame, end_frame)


local n_frames = end_frame - start_frame + 1
print('Copying ' .. n_frames .. ' frames')
print('  From: ' .. src_sprite.filename)
print('  To:   ' .. dest_sprite.filename)

-- TODO: Dialog for GUI usage?
-- local data =
--   Dialog():entry{ id="start_frame", label="Start:", text="1" }
--           :entry{ id="end_frame", label="End:", text="10" }
--           :button{ id="confirm", text="Confirm" }
--           :button{ id="cancel", text="Cancel" }
--           :show().data
-- if data.confirm then
--   app.alert("The given value is '" .. data.user_value .. "'")
-- end

-- Copy selected data and save new sprite
dest_sprite:deleteLayer('Layer 1')
dest_sprite = copy_layers(src_sprite, dest_sprite)
dest_sprite = copy_cels(src_sprite, dest_sprite, start_frame, end_frame)
dest_sprite = copy_tags(src_sprite, dest_sprite, start_frame, end_frame)
dest_sprite:saveAs(dest_sprite.filename)
