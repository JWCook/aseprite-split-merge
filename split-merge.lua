-- Split and merge frames from one or more sprites to another.
-- It preserves any associated tags, layers, and other metadata.

--
-- Test if an array contains a value
--
local function contains(array, value)
  for _, v in ipairs(array) do
    if v == value then
      return true
    end
  end
  return false
end

--
-- Get a default filename using source sprite name + either a given suffix or frame range
--
local function get_default_dest_filename(src_sprite, suffix, start_frame, end_frame)
  local path, basename = src_sprite.filename:match('^(.+[/\\])(.-).([^.]*)$')
  if not suffix then
    suffix = start_frame .. '-' .. end_frame
  end
  return path .. basename .. '_' .. suffix .. '.aseprite'
end

--
-- Get inputs from GUI dialog
--
local function get_dialog_inputs(src_sprite)
  local total_frames = #src_sprite.frames or 1
  local default_dest_filename = get_default_dest_filename(src_sprite, 'split')

  -- Build dialog
  local dialog = Dialog { title = 'Split frame range' }
      :label { text = 'Copy a range of frames to a separate sprite' }
      :number { id = 'start_frame', label = 'Start:', text = '1' }
      :number { id = 'end_frame', label = 'End:', text = tostring(total_frames) }
      :file { id = 'dest_path',
        label = 'Destination file',
        save = true,
        filename = default_dest_filename,
        filetypes = { 'aseprite' } }
      :check { id = 'overwrite',
        text = 'Overwrite existing file (otherwise append)',
        selected = false }
      :button { id = 'confirm', text = 'Confirm' }
      :button { id = 'cancel', text = 'Cancel' }
  local data = dialog:show().data
  if not data.confirm then
    return nil
  end

  -- Validate inputs
  data.start_frame = tonumber(data.start_frame)
  data.end_frame = tonumber(data.end_frame)
  if not data.start_frame or data.start_frame < 1 then
    app.alert('Invalid start frame')
  elseif not data.end_frame
      or data.end_frame > total_frames
      or data.end_frame < data.start_frame then
    app.alert('Invalid end frame')
  else
    return data
  end
end

--
-- Get source sprite, either from CLI or from active sprite
--
local function get_src_sprite()
  if app.activeSprite then
    return app.activeSprite
  elseif app.params['src-sprite'] then
    return Sprite { fromFile = app.params['src-sprite'] }
  else
    return nil
  end
end

--
-- Get destination sprite, either from CLI or new sprite
--
local function get_dest_sprite(src_sprite, dest_path, overwrite, start_frame, end_frame)
  dest_path = dest_path or app.params['dest-sprite']
  if app.params['overwrite'] then
    overwrite = app.params['overwrite']:lower() == 'true'
  end

  if dest_path and app.fs.isFile(dest_path) and not overwrite then
    return Sprite { fromFile = dest_path }
  else
    local dest_sprite = Sprite(src_sprite.spec)
    dest_sprite.filename = dest_path or get_default_dest_filename(src_sprite, nil, start_frame, end_frame)
    dest_sprite:deleteLayer('Layer 1')
    return dest_sprite
  end
end

--
-- Workaroud for some unwanted behavior: The last tag of an existing sprite will
-- automatically extend to new frames. Tag frame range can't (yet?) be directly
-- modified, so it needs to be deleted and added again.
--
local function fix_first_frame(dest_sprite)
  if #dest_sprite.tags == 0 then
    return dest_sprite
  end

  -- Copy and remove last tag, and add new frame
  local last_tag = dest_sprite.tags[#dest_sprite.tags]
  local fromFrame = last_tag.fromFrame
  local toFrame = last_tag.toFrame
  local aniDir = last_tag.aniDir
  local color = last_tag.color
  local data = last_tag.data
  local name = last_tag.name
  dest_sprite:deleteTag(last_tag)
  dest_sprite:newEmptyFrame()

  -- Add last tag back with original frame range and data
  local new_tag = dest_sprite:newTag(fromFrame.frameNumber, toFrame.frameNumber)
  new_tag.aniDir = aniDir
  new_tag.color = color
  new_tag.data = data
  new_tag.name = name

  return dest_sprite
end

--
-- Copy layers and associated metadata to new sprite if they do not already exist;
-- assume unique layer names
--
local function copy_layers(src_sprite, dest_sprite)
  local existing_layer_names = {}
  for i, layer in ipairs(dest_sprite.layers) do
    existing_layer_names[i] = layer.name
  end

  for _, layer in ipairs(src_sprite.layers) do
    if not contains(existing_layer_names, layer.name) then
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
  end

  return dest_sprite
end

--
-- Copy selected cels to new sprite
--
local function copy_cels(src_sprite, dest_sprite, start_frame, end_frame, frame_offset)
  -- Index any existing layers by name
  local layer_idx = {}
  for _, layer in ipairs(dest_sprite.layers) do
    layer_idx[layer.name] = layer
  end

  -- Copy cels
  for _, cel in ipairs(src_sprite.cels) do
    if cel.frameNumber >= start_frame and cel.frameNumber <= end_frame then
      -- Create new frame, if needed
      local dest_frame = cel.frameNumber + frame_offset
      if dest_frame > #dest_sprite.frames then
        dest_sprite:newEmptyFrame()
      end

      -- Look up layer by name and add new cel
      local dest_layer = layer_idx[cel.layer.name]
      dest_sprite:newCel(dest_layer, dest_frame, cel.image, cel.position)
    end
  end

  return dest_sprite
end

--
-- Copy tags and associated metadata for selected frames to new sprite
--
local function copy_tags(src_sprite, dest_sprite, start_frame, end_frame, frame_offset)
  for _, tag in ipairs(src_sprite.tags) do
    local src_start = tag.fromFrame.frameNumber
    local src_end = tag.toFrame.frameNumber

    if src_start <= end_frame and src_end >= start_frame then
      -- Adjust tag frame range to be within selection frame range
      local dest_start = math.max(1, src_start + frame_offset)
      local dest_end = math.min(#dest_sprite.frames, src_end + frame_offset)

      -- Copy tag + metadata to adjusted range
      local new_tag = dest_sprite:newTag(dest_start, dest_end)
      new_tag.aniDir = tag.aniDir
      new_tag.color = tag.color
      new_tag.data = tag.data
      new_tag.name = tag.name
    end
  end

  return dest_sprite
end

--
-- Run main script from either CLI or GUI
--
local function run()
  local src_sprite = get_src_sprite()
  if not src_sprite then
    return
  end
  local start_frame = tonumber(app.params['start-frame']) or 1
  local end_frame = tonumber(app.params['end-frame']) or #src_sprite.frames
  local dest_sprite = nil

  -- Gather inputs from GUI, if available
  if app.isUIAvailable then
    local input_data = get_dialog_inputs(src_sprite)
    if not input_data then
      return
    end
    start_frame = input_data.start_frame
    end_frame = input_data.end_frame
    dest_sprite = get_dest_sprite(src_sprite, input_data.dest_path, input_data.overwrite)

    -- Otherwise gather inputs from CLI (or defaults)
  else
    dest_sprite = get_dest_sprite(src_sprite, nil, nil, start_frame, end_frame)
    print('Copying ' .. end_frame - start_frame + 1 .. ' frames')
    print('  From: ' .. src_sprite.filename)
    print('  To:   ' .. dest_sprite.filename)
  end

  -- If this is an existing sprite, adjust offset by number of existing frames
  local frame_offset = -1 * (start_frame - 1)
  if #dest_sprite.layers > 0 then
    frame_offset = frame_offset + #dest_sprite.frames
  end

  -- Copy selected data and save new sprite
  dest_sprite = copy_layers(src_sprite, dest_sprite)
  dest_sprite = fix_first_frame(dest_sprite)
  dest_sprite = copy_cels(src_sprite, dest_sprite, start_frame, end_frame, frame_offset)
  dest_sprite = copy_tags(src_sprite, dest_sprite, start_frame, end_frame, frame_offset)
  dest_sprite:saveAs(dest_sprite.filename)
end

--
-- Initialize plugin, if installed
--
IsPlugin = false
function init(plugin)
  IsPlugin = true
  plugin.preferences.overwrite = false

  plugin:newCommand {
    id = 'SplitMerge',
    title = 'Split/Merge Frames',
    group = 'cel_new',
    onclick = run,
    onenabled = function()
      return app.activeSprite
    end
  }
end

--
-- Run as a standalone script, if not installed as a plugin
--
if not IsPlugin then
  run()
end
