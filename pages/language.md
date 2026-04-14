---
layout: default
title:  "Language"
num: 5
---

By now you are getting used to Lua, ARGoS, and creating simple artificial behavior. In this session, we will introduce [language games](https://langev.com/pdf/steels01languageGames.pdf). While it would be easy to see it as just code for a single experiment, this is more of an occasion for you to rethink every step you have made so far. How would this language game play if the robots were static, or just a few spread around the arena, or foraging, or leading each other, etc. etc. You are going to see how to implement the simplest language game and it will then be up to you to test it in the numerous ecological contexts you have already created in the past sessions, as well as to tweak it and explore variations.

For the sake of simplicity, you can find [here](romamile.com/swlang/assets/setup/swarm_lang.zip) a zipped folder with all the sub-functions in a simple code file, as well as the different behaviors from this course.

## Minimal Naming  Game

The Minimal Naming Game (MNG) is a simplified version of the broader Naming Game, one of the classic language games used to study language evolution.

In simple terms (for a more in-depth explanation, see [here](https://openaccess.city.ac.uk/id/eprint/16245/1/Baronchelli_2.pdf), each robot has a small vocabulary and occasionally interacts with another robot. During an interaction, one robot becomes the speaker and tries to send a word to a hearer.

* If the speaker has no word to send yet, it invents one at random.
* If the hearer already knows that word, the interaction is a success. The hearer then keeps only that word in its vocabulary.
* If the hearer does not know the word, the interaction is a failure. The hearer adds the new word to its vocabulary.

This very simple mechanism is enough to produce surprisingly rich collective dynamics.


### A minimal vocabulary

First, we need words. In this workshop, words will simply be numbers between 1 and 255. We also need a vocabulary. For now, we will store it as a global Lua table at the beginning of the controller:

```lua
voc = {}
```


### Communication protocol

We will use three message types to implement the Minimal Naming Game:

* `send_beacon` the default behavior, used to broadcast our presence and signal that we are available to play;
* `start_game` used when acting as a speaker, to initiate a game with a specific robot;
* `send_answer` used when acting as a hearer, to reply to a game addressed to us.

We will use the range-and-bearing sensor to send messages. Since it allows us to transmit 4 bytes, we need to use them carefully. In our case, these 4 bytes will encode (ithough not always all at the same time) the sender’s ID, the ID of the robot the message is addressed to, the word being sent, and the message type, so that the receiving robot can distinguish between the three kinds of messages introduced above.

The 4-byte protocol is the following:

```lua
-- 4-byte protocol:
-- Beacon:   [my_id, 0, 0, 0]
-- Start:    [my_id, other_id, 1, word]     word in 1..255
-- Answer:   [my_id, other_id, 2, 0|1]      0 fail, 1 success

my_id = tonumber(robot.id:sub(3))

function send_beacon()
    -- the 0 in third place means we are broadcasting our presence
  robot.range_and_bearing.set_data( {my_id, 0, 0, 0} )
end


function start_game(hearer_id, word)
    -- the 1 in third place means we want to start a game
  robot.range_and_bearing.set_data( {my_id, hearer_id, 1, word} )
end


function send_answer(speaker_id, success)
    -- the 2 in third place means we are answering in a game
  robot.range_and_bearing.set_data( {my_id, speaker_id, 2, success} )
end
```

### Speaker behavior

The speaker first decides whether it wants to speak (with a probability of `pSpeak`), then looks for a nearby robot to interact with.

```lua
function speaker_step()
    
  local pSpeak = 0.1

    -- Should we speak?
  if (math.random() > pSpeak) then
    return false
  end

    -- Build list of neighbors and their ids
  local neighbors = {}
  for i = 1, #robot.range_and_bearing do
    neighbors[#neighbors + 1] = robot.range_and_bearing[i].data[1]
  end

    -- No neighbors :( >> leave the function, and return false
  if #neighbors == 0 then
    return false
  end

    -- pick a random neighbors
  local hearer_id = neighbors[math.random(#neighbors)]

    -- if no known words, then invent one!
  if #voc == 0 then
    voc[1] = math.random(1,255)
  end

  local word = voc[1]

  -- Send a message to the picked neighbor
  start_game(hearer_id, word)

  -- return true to indicate you are now busy
  return true
end

```

In this simple version, the speaker always sends the first word in its vocabulary. Later on, you could make this more interesting by choosing words differently, for example randomly, by frequency, or depending on context.


### Hearer behavior

The hearer checks incoming messages. If it receives a game request addressed to itself, it decides whether the word is already in its vocabulary.

```lua
local function hearer_step()

  -- parsing through all messages received
  for i = 1, #robot.range_and_bearing do
    local from    = robot.range_and_bearing[i].data[1]
    local target  = robot.range_and_bearing[i].data[2]
    local type    = robot.range_and_bearing[i].data[3]
    local payload = robot.range_and_bearing[i].data[4]

    -- If I receive a message from a speaker, addressed to me then I answer
    if type == 1 and target == my_id then
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

### Putting it together

At each simulation step, a robot first checks whether it must act as a hearer. If not, it may decide to act as a speaker. If neither happens, it simply broadcasts its presence.

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

### Observing what happens

With the code above, your robots can already play a Minimal Naming Game.

A little visualisation code has been added to the global zipped folder mentioned above. Unfortunately, for now it works only on Linux and Windows machines :( A Mac version is coming soon (especially if someone can help me test it...). In order to run it, follow these instructions:


```bash
# Getting the files
wget http://romamile.com/swlang/assets/setup/swarm_lang.zip
unzip swarm_lang.zip
cd swarm_lang

# Reaching the code and compiling
cd lualoop/build/
cmake ..
make
cd ..

# Testing if all works!

argos3 -c expSetup.argos

```

Open the file `luaDebug.lua`, you will see in the code three global variables: two vectors (`targetRed` and `targetGreen`) as well as a numeric variable (`word`). The two targets are vectors that will be displayed in the arena with their specific colors, and words will define the color of a disk below the robot (hence the possiblity of representing the word it holds, if you link it with the vocabulary).

Feel free to use that code base to visualise the evolution of the words within your robots. Or if you prefer a simpler version, you can inspect robots with **Shift**+**click** to see the vocabulary table, or print it at each step, with:


```lua
log("---")
for i = 1, #voc do
    log(voc[i] .. " ")
end
```

Even with this minimal setup, you can already start experimenting. You can change how often robots speak, modify how they choose words, or embed the game inside another task such as navigation or foraging. This is where things become interesting: once language is coupled to behavior and interaction constraints, the collective dynamics can change dramatically.



## Exploration - Grounded Game, Category Game, any kind of games...
In the Grounded Game, the word isn't just abstract, but linked to a specific meaning, anchored in the environment. In our context, a default meaning could be the position of something. Unfortunately, this would often mean either more complex communication, or even worse... the social odometry of the previous session, which was out of scope for this course (for now...).

Hence, the idea here is to play with the MNG, and to test out its limits. Maybe the robots only communicate when they are at the resource, and this way, they  can associate a specific position with the word, since they only hear about the resource at the correct position. Maybe robots should follow other robots when they are broadcasting a word they already know. Maybe robots shouldn't always forget other words, or always be truthful about the word they are sharing... Even with such a simple game, you can already try out multiple variations. If you lack ideas, pick one from the list above, but even better if you find your own idea to explore!




