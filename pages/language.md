---
layout: default
title:  "Language"
num: 5
---

## Minimal Naming  Game

The Minimal Naming Game (MNG) is a simplified version of the Naming Game, which is one of the many language game that are used for the study of language evolution and emmergence.

A simplified exlpanation would be (for a more indepth explanation, see REF) that all robot have a vocabulary, and will talk to each other. To do so, first a speaker needs to be selected, that will send a word to a hearer. If the hearer know of the word, then the game is a success, and it keeps in its memory only that word. If the hearer doesn't know the word, then the game is a failure, and the robot add this new word to its current vocabulary. If the speaker doesn't have any word to send, then it will randomly create one.

So, first of all, we needs words. They are going to be numbers, between 1 and 255. And we need a vocabulary, defines a global table at the begining of our Lua code file:

```lua
voc = {}
```

Second, here are the three message sending protocols we will use that encompass the MNG:
* `send_beacon` as our default behavior, to broadcast our presence and that we are eager to play a MNG;
* `start_game` to behave as a speaker, and start a game with a specific robot;
* `send_answer` to behave as a hearer, and answer a game played with us.


```lua
-- 4-byte protocol:
-- Beacon:   [my_id, 0, 0, 0]
-- Start:    [my_id, other_id, 1, word]     word in 1..255
-- Answer:   [my_id, other_id, 2, 0|1]      0 fail, 1 success


function send_beacon()
    -- the 0 in third place means we are broadcasting our presence
  robot.range_and_bearing.set_data( {tonumber(robot.id:sub(3)), 0, 0, 0} )
end


function start_game(hearer_id, word)
    -- the 1 in third place means we want to start a game
  robot.range_and_bearing.set_data( {tonumber(robot.id:sub(3)), hearer_id, 1, word} )
end


function send_answer(speaker_id, success)
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
    neighboors[#neighboors + 1] = robot.range_and_bearing[i].data[1]
  end

    -- No neighboors :(
  if #neighboors == 0 then
    return false
  end

    -- pick a random neighboors
  local hearer_id = neighboors[math.random(#neighboors)]

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
    busy = speaker_step()
  end

    -- If not, then broadcast about yourself
  if not busy then
    send_beacon()
  end

```

Now, all the above will allow you to run an experimentation with your robots playing a MNG. Ideally, you would have graphical representation on top of the robots for the words being used (coming soon!), but for now, you can probe the brain of any robots either by clickig on them with Shift pressed, and looking into their memory, or more globally, output in ARGoS at each tick the vocabulary of all robots:

```lua
log("---")
for i = 1, #voc do
    log(voc[i] .. " ")
end
```


With all code, the robots can now play a MNG, and it is up to you to change their behavior, would it be giving them a task to do, and to see how it impact the language dymanics, or make changes to the MNG and see what happens then!

