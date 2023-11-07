-- scales
-- v0.1


--
-- LIBRARIES
--
mxsamples=include("mx.samples/lib/mx.samples")
engine.name="MxSamples"
sample=mxsamples:new()
musicutil = require 'musicutil'


--
-- DEVICES
--
g = grid.connect()


--
-- VARIABLES
--
playing_notes = {}
screen_dirty = true
grid_dirty = true
momentary = {}
for x=1,16 do
  momentary[x] = {}
  for y=1,8 do
    momentary[x][y] = false
  end
end


--
-- INIT FUNCTIONS
--
function init_parameters()
  params:add_separator("SCALES")
  params:add_group("SCALES - SCALES",22)
  params:add{
    type="number",
    id="scale",
    name="scale",
    min=1,
    max=40,
    default=1,
    formatter=function(param)
      return string.lower(musicutil.SCALES[param:get()].name)
    end,
    action=function()
      --max selected note is set to number of notes in scale
      local note_look = params.lookup["selected_note"]
      params.params[note_look].max = #musicutil.SCALES[params:get("scale")].intervals
      params:set("selected_note",1)
      --max selected chord and value is set first to 0
      for i=1,9 do
        local chord_look = params.lookup[i.."selected_chord"]
        params.params[chord_look].max = 0
        params:set(i.."selected_chord",0)
      end
      --selected chord max is set to possible amount of chords
      --default chord selection is set to basic triad form
      for i=1,#musicutil.SCALES[params:get("scale")].intervals do
        local chord_look = params.lookup[i.."selected_chord"]
        params.params[chord_look].max = #musicutil.SCALES[params:get("scale")].chords[i]
        if #musicutil.SCALES[params:get("scale")].chords[i] > 0 then
          params.params[chord_look].min = 1
          params:set(i.."selected_chord",1)
          for key, value in pairs(musicutil.SCALES[params:get("scale")].chords[i]) do
            print(i.." "..key.." "..value)
            if value == 1 then
              params:set(i.."selected_chord",key)
            elseif value == 12 then
              params:set(i.."selected_chord",key)
            elseif value == 17 then
              params:set(i.."selected_chord",key)
            elseif value == 24 then
              params:set(i.."selected_chord",key)
            end
          end
        end
      end
    grid_dirty = true
    end
  }
  params:add{
    type="number",
    id="root_note",
    name="root note",
    min=0,
    max=11,
    default=0,
    formatter=function(param)
      return musicutil.note_num_to_name(param:get(),false)
    end,
    action=function()
    end
  }
  params:add{
    type="number",
    id="selected_note",
    name="selected note",
    min=1,
    max=1,
    default=1,
    action=function()
    end
  }
  params:add{
    type="number",
    id="octave",
    name="octave",
    min=0,
    max=8,
    default=4,
    action=function()
    end
  }
  for i=1,9 do
    params:add{
      type="number",
      id=i.."selected_chord",
      name=i.." selected chord",
      min=0,
      max=0,
      default=0,
      action=function()
        grid_dirty = true
        if params:get(i.."selected_chord") > 0 then
          params:set(i.."inversion",params:get(i..params:get(i.."selected_chord").."selected_inversion"))
        end
      end
    }
    params:add{
      type="number",
      id=i.."inversion",
      name=i.." inversion",
      min=0,
      max=6,
      default=0,
      action=function(value)
        if params:get(i.."selected_chord") > 0 then
          params:set(i..params:get(i.."selected_chord").."selected_inversion",value)
        end
      end
    }
  end
  params:add_group("SCALES - INVERSIONS",144)
  for i=1,9 do
    for j=1,16 do
      params:add{
        type="number",
        id=i..j.."selected_inversion",
        name=i..j.." selected inversion",
        min=0,
        max=6,
        default=0,
        action=function()
        end
      }
    end
  end
  params:add_group("SCALES - TRIGGERS",9)
  for i=1,9 do
    params:add{
      type="binary",
      id=i.."trigger",
      name=i.." trigger",
      behavior="momentary",
      default=0,
      action=function()
        --stop_chord()
        --play_chord(i)
      end
    }
  end
  --params:add_group("SCALES - MOLLY THE POLY",46)
  --MollyThePoly.add_params()
  params:bang()
end

function init()
  init_parameters()
  redraw_metro = metro.init(redraw_event, 1/30, -1)
  redraw_metro:start()
  grid_redraw_metro = metro.init(grid_redraw_event, 1/30, -1)
  grid_redraw_metro:start()
end


--
-- CLOCK FUNCTIIONS
--
function redraw_event()
  if screen_dirty then
    redraw()
    screen_dirty = false
  end
end

function grid_redraw_event()
  if grid_dirty then
    grid_redraw()
    grid_dirty = false
  end
end

--
-- AUDIO FUNCTIONS
--
function play_chord(note)
  if note <= #musicutil.SCALES[params:get("scale")].intervals then
    chords = musicutil.chord_types_for_note(musicutil.SCALES[params:get("scale")].intervals[note]+params:get("root_note"), params:get("root_note"), params:get("scale"))
    chord_notes = musicutil.generate_chord(musicutil.SCALES[params:get("scale")].intervals[note]+params:get("root_note"),chords[params:get(note.."selected_chord")],params:get(note..params:get(note.."selected_chord").."selected_inversion"))
  
    for i=1,#chord_notes do
      table.insert(playing_notes,chord_notes[i])
      print(chord_notes[i])
      sample:on({name="steinway model b",midi=chord_notes[i]+12*params:get("octave"),velocity=100})
    end
  end
end

function stop_chord()
  for i=1,#playing_notes do
    sample:off({name="steinway model b",midi=playing_notes[i]})
  end
  playing_notes = {}
end


--
-- UI FUNCTIONS
--
function key(n,z)
  if n == 1 then
    shifted = z == 1
  elseif n == 2 and z == 1 and shifted then
    --play_chord()
  elseif n == 3 and z == 1 and shifted then
    --stop_chord()
  elseif n == 2 and z == 1 then
    stop_chord()
    play_chord(params:get("selected_note"))
  elseif n == 3 and z == 1 then
    stop_chord()
  end
  screen_dirty = true
end

function enc(n,d)
  if n == 1 then
    params:delta("scale",d)
  elseif n == 2 then
    params:delta("selected_note",d)
  elseif n == 3 and shifted then
    params:delta(params:get("selected_note").."inversion",d)
  elseif n == 3 then
    params:delta(params:get("selected_note").."selected_chord",d)
  end
  screen_dirty = true
end

function g.key(x,y,z)
  if z == 1 then
    if y <= #musicutil.SCALES[params:get("scale")].intervals then
      if x <= #musicutil.SCALES[params:get("scale")].chords[y] then
        params:set("selected_note",y)
        params:set(y.."selected_chord",x)
        play_chord(y)
        momentary[x][y] = true
      end
    end
  else
    stop_chord()
    momentary[x][y] = false
  end
  screen_dirty = true
  grid_dirty = true
end


--
-- REDRAW FUNCTIONS
--
function redraw()
  screen.clear()
  screen.level(15)
  h = 6
  for i=1,#musicutil.SCALES[params:get("scale")].intervals do
    --print(musicutil.SCALES[params:get("scale")].intervals[i])
    screen.move(5,h*i)
    screen.text(i..":")
    screen.move(0,h*i)
    if i == params:get("selected_note") then
      screen.text("O")
    end
    screen.move(15,h*i)
    screen.text(musicutil.note_num_to_name(musicutil.SCALES[params:get("scale")].intervals[i]+params:get("root_note")), false)
    chords = musicutil.chord_types_for_note(musicutil.SCALES[params:get("scale")].intervals[i]+params:get("root_note"), params:get("root_note"), params:get("scale"))
    chord_notes = musicutil.generate_chord(musicutil.SCALES[params:get("scale")].intervals[i]+params:get("root_note"),chords[params:get(i.."selected_chord")])
    screen.move(27,h*i)
    --w = 14
    if params:get(i.."selected_chord") > 0 then
      if params:get(i.."inversion") == 0 then
        screen.text(chords[params:get(i.."selected_chord")])
      else
        screen.text(chords[params:get(i.."selected_chord")].." inv"..params:get(i.."inversion"))
      end

    --  for j=2,#chord_notes do
    --    screen.move(15+w,h*i)
    --    screen.text(musicutil.note_num_to_name(chord_notes[j]),false)
    --    w = w+14
    --  end
    end
  end
  screen.move(0,63)
  screen.text("scale: "..params:string("scale"))
  screen.update()
end

function grid_redraw()
  g:all(0)
  for y=1,#musicutil.SCALES[params:get("scale")].intervals do
    for x=1,#musicutil.SCALES[params:get("scale")].chords[y] do
      if momentary[x][y] then
        g:led(x,y,15)
      elseif x == params:get(y.."selected_chord") then
        g:led(x,y,8)
      else
        g:led(x,y,4)
      end
    end
  end
  g:refresh()
end
