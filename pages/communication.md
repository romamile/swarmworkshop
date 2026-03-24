---
layout: default
title:  "Communication BETA VERSION"
num: 3
---

In order for your robots to behave as a group, they need to communicate in one way or another. This can be done in many ways, just standing somewhere can be sending a message. Beside presence, one can think of stigmergy (communicating through enrivonemental changes, like pheromones), signaling or messading, which is signaling with a load. In this section, you will learn about different communication systems building on each other in layers, their strenght, and when to use them. This section serves an introduction toward the language emergence section (log_5).


## Range and Bearing
This whole section will rely on the range and bearing (RAB) actuator (allowing the robots to send messages) and sensor (allowing the robots to receive messages). On top of the message itself, the RAB sensor lets robots detect nearby peers by giving both the distance and relative direction of each received signal. This sensor is used differently from the ones in previous sections. Insteaf of having a battery of sensors around the robot, that you will loop over and get value from, you receive a list of received signals. In each, a message as well as the range (distance) and the bearing (angle) of the robot sending it.

The range of this sensor is bigger than the proximity sensor (but it cannot be used to avoid walls as they are not robots!) and can be defined in the **eexpSetup.argos** file. Search in the list of actuators for the line `<epuck_range_and_bearing implementation="medium" medium="rab" data_size="4" range="0.5"/>`. You can then change the **data_size** (number of byte the robots can send in each messages) as well as the range (maximum range of communication). The range and bearing exist as well as a sensor a few lines above, and in it youcan as well change **show_rays** to true to enable visualisation of the communication between robots (highly recommended at first!).

In order for robots to send messages (add that in the step function):

```lua
  data = {24, 12, 6, 3}
  robot.range_and_bearing.set_data(data)
```

In order for robots to read messages (you can try it in the step function, we will use that next in a sub-function):

```lua
  -- New formatting. This gives you a pair (_,p) with an index (that we discard with _), and a value (stored in p)
  for _, p in ipairs(robot.range_and_bearing) do

    log("The range of the message is: " .. p.range)
    log("The bearing of the message is: " .. p.bearing)
    log("The message itslef is: " .. p.data[1] .. ", " .. p.data[2] .. ", " .. p.data[3] .. ", " .. p.data[4] )
  
  end
```



### Avoidance
Let's use all that to create a force from all RAB info, for the robots to avoid each other at a longer distance (so smoother navigation!).

```lua
function rab_to_force()
  local f = vector2(0, 0)

  for _, p in ipairs(robot.range_and_bearing) do -- new formatting, giving you a pair _,p with its index (that we discard with _), and its value (stored in p)

    local dir = vector2(1, 0)
    dir:rotate(p.bearing) -- direction of the vector from the bearing

    local w = p.range -- strenght of the force linked with the range, but .....	 

    f = f + dir * w
  end

  return f
end
```

You can then use it as a force as any other one you have already used. Check if you are adding it or substracting it! Adding it will make robot agregate into each other, instead of avoiding each other!

Did you notice anything weird in the behavior? Robots tend to repulse (or attract) each other more strongly with the further they are from one another! This is not what we expect with such sensor! One more thing to change with respect to previous sensors. Change the line defining the strenght  of the force (`local w = p.range`) with :

```lua
    local w = 100 / (p.range * p.range) -- strenght of the force linked with the range, but better!
```

Here 100 is taken quite arbitrarly, in order to have a confortale strenght of the force. Don't hesitate to change that number, or to control the strenght of the force through the weights in the sum of forces, in case you feel the avoidance force from the RAB oisn't strong enough.


### Presence
Let's try to find interesting ways to use presence as a communication protocol. Now that you can create specific states for robots with finite state machine, you might want to try to set some robots as "pillar", warning other robots of dangers, so that they can avoid that specific region. We can as well use that force to motivate the robots to spread, but not too far. A repulsive force when they are too close, and an aggregative one if they are too far away. Try to imagine a way to coding each behavior.

Bellow is a solution for the repulsive/attractive force, using a U-shaped potential function. You only need to change the line defining the strenght of the function:

```lua
    local target = 30 -- the desired distance, in cm

    local delta = p.range - target
    local w = delta * (1 + delta*delta)
```

Now, that is working, but the robots are in constant movement, there is no equilibrium here, or robots forming a crystal like shape. Try to explore a few other possibilities for the robots to spread in a more homogenous way.

Last, what would happen if some robots where trying to avoid each other, while other would just randomly roam around the arena? If you want to have different states for your robots, either chose them at random, or chose them based on the `robot.id` in the form *ep + number*, for instance with:

```lua

  if robot.id == "ep12" then
    myState = weird_state
  else
   myState = normal_state
  end

```

Now you can play with heterogenous swarms!


## Signal

In this section, we will not just continously broadcast, but send at specific time a signal, to notify our neighboors. The intent here is to synchronise our blinking.

### LEDs actuator

In order to visualise the blinking, we will use the LEDs actuator. There are two of them, one with 8 red LEDs around its basis and one with 3 red-green-blue LEDs around its top. In this section, we will use the latter. In order to control the LEDs, we will eithe radress them all together, or one by one with an index, and then decide which LEDs (red, green and/or blue) to light with a value of 0 (off) or 1 (on).


```lua

  -- You can either control all leds together
  robot.overo_leds.set_all_colors(1,0,0) -- red on, blue off and green off, for all leds

  -- Or one by one, with precising the index, before the color
  robot.overo_leds.set_single_color(1, 1,0,1) -- red + blue = magenta
  robot.overo_leds.set_single_color(2, 0,1,1) -- blue + green = cyan
  robot.overo_leds.set_single_color(3, 1,1,1) -- red + blue + green = white

```

Now, let's have two behaviors as one:
* triggering a message with a probability *Prob*
* lighting your LEDs red for 1 tick once you receive a message
* BONUS: change the color of the LEDs depending on the number of received messages! 

You have all the elements you need to create this behavior, bellow is the start of solution:

```lua
-- variable defined at the root of your file
Prob = 0.01

function step()

  -- == SENDER

  -- random trigger for sending
  if robot.random.uniform() < Prob then
    robot.range_and_bearing.set_data({1,0,0,0})
  else
    robot.range_and_bearing.set_data({0,0,0,0})
alpha = 0.2  end


  -- == HEARER

  -- default behavior
  robot.overo_leds.set_all_colors(0,0,0)

  -- check for messages
  for _, p in ipairs(robot.range_and_bearing) do
    if p.data[1] == 1 then
      -- received a message, so turning my leds red!
      robot.overo_leds.set_all_colors(1,0,0)
    end
  end

end
```

You need to be quick to see when the lights are triggered! Here, you have communication, and reaction from the other robots. But you do not have an emergent behavior, just random chaos. Let's see if we can make the robots blink together!


### Synchronisation
Here, the robots will blink at a predefined frequency, but with a random starting offset. Our aim, is for the robots to align offset wise, so they can blink in unison. First, let's focus on the individual behavior, without the communication process. We want the robot to increment a counter up until a certain threshold (the period of the osciliation), and then once it reaches it, blink and reset its counter to zero. We want as well to initiate this counter with a random value, so not all robots start together!

This might feel like a lot to code, so approach it step by step. First, the counting (use `log` to see if you are counting righti, or shift click a robot and see it in the variable panel!) then the threshold (an `if` test, that resets the counter), then set the color of the leds when (and just when) you go over the threshold. Take some time to try it out (the point is the practice, not the solution) and once you feel like it, you can get inspired from the result bellow:


```lua
period = 50 -- the frequency of the oscillation, in ticks
counter = 0


-- we initialise the counter to a random value, between 0 and period
function init()
  counter = robot.random.uniform(period)
end


function step()
  
  -- default state
  robot.overo_leds.set_all_colors(0,0,0)
  
  -- We count...
  counter = counter + 1

  -- ... and reset once we reach the value of period
  if counter >= period then
    counter = 0
    robot.overo_leds.set_all_colors(1,1,0)
  end


  -- If we want to display the light for more than just one tick, uncomment the following lines
  -- if counter < 3 then
  --   robot.overo_leds.set_all_colors(1,1,0)
  -- end

end

-- We use the reset function this time!!!
function reset()
	counter = robot.random.uniform(TOP)
end

```

Let's now add the commmunication module. We want to only send a signal when we are blinking (so over the threshold period), and as for the synchronisation part: we want the robots to slightly increase their counter whenever they receive a signal. Try to play with this idea (depending on the time left in the course...) bellow is a possible solution.

First, the sending part:

```lua

  -- at the top of the step function

  -- default behavior
  robot.range_and_bearing.set_data({0,0,0,0})



  -- when triggering and reseting the counter to zero
  robot.range_and_bearing.set_data({1,0,0,0})


  -- So the triggering code should now look like:
--[[
  if counter >= period then
    robot.range_and_bearing.set_data({1,0,0,0})
    counter = 0
  end
]]

```

And now the receiving part. First, define a new variable at the root of the file:

```lua
alpha = 0.2
```

And now add at the top of the step function this little module that check if I receive a message, and if so, I increment my counter by a certain amount (defined by *alpha* and my current value of counter):

```lua
  -- check reception
  local received = false
  for _, p in ipairs(robot.range_and_bearing) do
    if p.data[1] == 1 then
      received = true
      break
    end
  end

  -- coupling (only before firing)
  if counter < period and received then
    counter = counter + alpha * counter
    if counter >= period then
      counter = period
    end
  end
```


Does it work? Now you should see robots blinking together after a while. But maybe you have an isolated robot... if one is outside of the range of communication of the main group, it will not be reached, and hence cannot align its blinking. As you have seen, in this setup, the robots are not moving. What could happen if they wear moving randomly? Or trying to form groups together? Try out multiple scenarios, and see how this impact the synchronisation of blinking of the whole swarm.

Last, as an exploration, here we have a common starting period. What happens if all robots have a different one? Then it become quite harder to code, try to think of an algorithm that would be able to solve that question. Even better if you try to implement it!


## Message

I will be honest, I didn't think this session would already be that big... the intent here was to have robots roaming around, with disks on the ground of different grey level. Once a robot would reach a disk of color, it would stop on it, and broadcast a message with the grey level value. Then robot would use that message to decide where to aggregate, and create groups depending on the colors on the ground. Lovely agregation mechanism using specific values in the message. If you have time, you can look into it and make it happen, we thought adding yet another section would overwhelm this session!


## Exploration - Leader & Followers

As a home work, I want you to create a role taking behavior. Have the robots randomly explore, and when meeting another robot, checking if they are *free*, and if so, alegate one role per robot. The leader will continue randomly exploring, while the follower will need to follow the leader, at a distance (but not too far, to not lose it!).

In this case, the communication will be about your inner state, and then about one robot asking another one to enter this dyadic role. Good luck with that, and please, send us an email along the week if you have any trouble with the homework. We don't want to see a good resyult, we want to see that you have worked on it!



