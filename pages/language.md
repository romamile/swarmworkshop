---
layout: default
title:  "Language"
num: 3
---




## Reaching out
Range and bearing is both a recognition system between robots (giving you the range - distance, and the bearing - angle, between you and any other robots), as well as a communication system. Here, we will use it as a recognition system, and use it similarly as the proximity sensor, but at a bigger distance, hence helping better movement between robots.

```lua
function rab_to_force()
  local f = vector2(0, 0)

  for i = 1, #robot.range_and_bearing do
    local p = robot.range_and_bearing[i]

    local dir = vector2(1, 0)
    dir:rotate(p.bearing)

    local w = 1 / (p.range + 0.01)  -- avoid divide by zero
    f = f - dir * w
  end

  return f
end
```

you might want to change the repulsive force into an attraction if you want to agregate robots. Try as well to have a force that tries to force a specific distance between robots. This creates interesting crystal shapes as a swarm!




## minimal language game



First, we need to have a vocabulary. For that matter, on top of the file we define a global table: our vocabulary, which will hold our words.

```lua
voc = {}
```

Second, here are the three message sending protocol we will use, when we want to broadcast our presence, start a game, or answer.


```lua
-- 4-byte protocol:
-- Beacon:   [my_id, 0, 0, 0]
-- Start:    [my_id, other_id, 1, word]     word in 1..255
-- Answer:   [my_id, other_id, 2, 0|1]      0 fail, 1 success


local function send_beacon()
    -- the 0 in third place means we are broadcasting our presence
  robot.range_and_bearing.set_data( {tonumber(robot.id:sub(3)), 0, 0, 0} )
end


local function start_game(hearer_id, word)
    -- the 1 in third place means we want to start a game
  robot.range_and_bearing.set_data( {tonumber(robot.id:sub(3)), hearer_id, 1, word} )
end


local function send_answer(speaker_id, success)
    -- the 2 in third place means we are answering in a game
  robot.range_and_bearing.set_data( {tonumber(robot.id:sub(3)), speaker_id, 2, success} )
end
```

Last, let's implement the behavior of the game itself. For the speaker, it is about a probability of speaking, and then finding a robot in range:

```lua
function speaker_step()
    
  local pSpeak = 0.1

    -- Should we speak?
  if (math.random() < pSpeak) then
    return false
  end

    -- Build list of neighboors and their ids
  local neighboors = {}
  for i = 1, #robot.range_and_bearing do
    neighboors[#candidates + 1] = robot.range_and_bearing[i].data[1]
  end

    -- No neighboors :(
  if #neighboors == 0 then
    return false
  end

    -- pick a random neighboors
  local hearer_id = candidates[math.random(#candidates)]

    -- no known words, then invent one!
  if #voc == 0 then
    voc[1] = math.random(1,255)
  end

  local word = voc[1]

  start_game(hearer_id, word)
  return true
end

```


as for the hearer:

```lua
local function hearer_step()

  for i = 1, #robot.range_and_bearing do
    local from    = robot.range_and_bearing[i].data[1]
    local target  = robot.range_and_bearing[i].data[2]
    local type    = robot.range_and_bearing[i].data[3]
    local payload = robot.range_and_bearing[i].data[4]

    -- If I receive a message from a speaker, addressed to me then I answer
    if type == 1 and target == tonumber(robot.id:sub(3)) then
      local word = payload

      -- check if word is in vocabulary
      local success = 0
      for j = 1, #voc do
        if voc[j] == word then
          success = 1
          break
        end
      end

      if success == 1 then -- simplify vocabulary to only that word
        voc = {word}
      else -- add word to vocabulary
        voc[#voc + 1] = word
      end

      send_answer(from, success)
      return true
    end
  end

  return false
end
```


And as a whole in the step function :

```lua

  local busy = false

    -- First check if you need to act as a hearer
  busy = hearer_step()
  
    -- If not, maybe you might act as a speaker then
  if not busy then
    speaker_step()
  end

    -- If not, then broadcast about yourself
  if not busy then
    send_beacon()
  end

```


