---
layout: default
title:  "Communication"
num: 3
---

For robots to behave as a group, some form of information exchange is needed. This can be done in many ways, as even simply being present in a location can act as a signal. Beyond presence, one can think of stigmergy (communicating through environmental modifications, such as pheromone-like traces), signaling, or messaging (where signals carry explicit information). In this section, you will learn about different communication systems that build on one another in layers, their strengths, and when to use them. This section serves an introduction to the language emergence section (log_5).


## Range and Bearing
This whole section will rely on the range and bearing (RAB) actuator (which allows robots to send messages) and sensor (which allows them to receive messages). In addition to the message itself, the RAB sensor lets robots detect nearby peers by giving both the distance and relative direction of each received signal. This sensor is used differently from those in previous sections. Instead of having a battery of sensors around the robot, which you would loop over to retrieve values, you instead receive a list of incoming signals. Each entry contains a payload (message) as well as the range (distance) and the bearing (angle) of the robot sending it.

The range of this sensor is greater than that of the proximity sensor (but it cannot be used to avoid walls as these are not robots!) and can be defined in the **expSetup.argos** configuration file. Search in the list of actuators for the following line `<epuck_range_and_bearing implementation="medium" medium="rab" data_size="4" range="0.5"/>`. You can then change the **data_size** (number of bytes the robots can send in each message) as well as the range (maximum range of communication). The range and bearing also exists as a sensor a few lines above, and in it you can also set **show_rays** to true to enable visualization of the communication between robots (highly recommended when starting out!).

To enable robots to send messages, add this to the step function:

```lua
  data = {24, 12, 6, 3}
  robot.range_and_bearing.set_data(data)
```

To enable robots to read messages, you can try this in the step function, we will reuse it later in a sub-function:

```lua
  -- New formatting. This gives you a pair (_,p) with an index (which we discard with _), and a value (stored in p)
  for _, p in ipairs(robot.range_and_bearing) do

    log("The range of the message is: " .. p.range)
    log("The bearing of the message is: " .. p.bearing)
    log("The message itself is: " .. p.data[1] .. ", " .. p.data[2] .. ", " .. p.data[3] .. ", " .. p.data[4] )
  
  end
```



### Avoidance
Let's use this to create a force from the RAB information, allowing robots to avoid each other at a greater distance (resulting in a smoother navigation!).

```lua
function rab_to_force()
  local f = vector2(0, 0)

  for _, p in ipairs(robot.range_and_bearing) do 

    local dir = vector2(1, 0)
    dir:rotate(p.bearing) -- direction of the vector based on the bearing

    local w = p.range -- strength of the force related to the range, but .....	 

    f = f + dir * w
  end

  return f
end
```

You can then use it as a force, just like the ones you have previously implemented. Double check if you are adding it or subtracting it in the sum of forces line! Adding it will cause robots to aggregate, rather than avoid each other.

Did you notice anything unusual in the behavior? Robots tend to repel (or attract) each other more strongly as the distance between them increases! This is not what we expect with this type of sensor. This is another difference compared to how previous sensors were implemented. Change the line defining the strength  of the force (`local w = p.range`) with :

```lua
    local w = 100 / (p.range * p.range) -- strength of the force related to the range, but better!
```

Here 100 is chosen somewhat arbitrarily, to obtain a comfortable force magnitude. You can adjust this value if needed, or control the strength of the force through the weights in the sum of forces, if you find that the  avoidance force from the RAB isn't strong enough.


### Presence
Let's explore different ways to use presence as a communication protocol. Now that you can define specific robot states using a finite state machine, you can assign some robots as *pillars*, which would signal dangerous areas to others, allowing them to avoid these regions. This force can also be used to make the robots spread out, while maintaining cohesion. For instance, a repulsive force when robots are too close, and an attractive one when they are too far apart. Try to imagine a way to implement such behaviors.

Below is a solution for the repulsive/attractive force, using a U-shaped potential function. You only need to change the line defining the strength of the function:

```lua
    local target = 30 -- the desired distance (in cm)

    local delta = p.range - target
    local w = delta * (1 + delta*delta)
```

This works, but the robots remain in constant motion, without any equilibrium or structure emerging. Try exploring other approaches for the robots to spread in a more homogeneous manner.

Finally, what would happen if some robots were trying to avoid each other, while others simply roam around the arena? If you want to assign different roles to your robots, you can either choose them at random, or assign them based on the `robot.id` (in the form *ep + number*).

```lua

  if robot.id == "ep12" then
    myState = weird_state
  else
   myState = normal_state
  end

```

Feel free to experiment with heterogeneous swarms!


## Signal

In this section, we will not just continuously broadcast, but send at specific times a signal, to notify our neighbors. The end goal in this section is to synchronize blinking across robots.

### LED actuator

In order to visualize the blinking, we use an LED actuator. There are two of them, one with 8 red LEDs around the base of the robot, and one with 3 red-green-blue LEDs around its top. In this section, we use the latter. In order to control the LEDs, we either address them all at once, or individually using an index. Then, we specify which colored LED (red, green and/or blue) to light using a value of 0 (off) or 1 (on).


```lua

  -- You can either control all leds together
  robot.overo_leds.set_all_colors(1,0,0) -- red on, blue off and green off, for all leds

  -- Or individually, by specifying the index, before the color values
  robot.overo_leds.set_single_color(1, 1,0,1) -- red + blue = magenta
  robot.overo_leds.set_single_color(2, 0,1,1) -- blue + green = cyan
  robot.overo_leds.set_single_color(3, 1,1,1) -- red + blue + green = white

```

Now, let's combine two behaviors. Let's have each robot:
* trigger a message with probability *prob*
* light its  LEDs red for one tick upon receiving a message
* bonus: change the color of the LEDs depending on the number of received messages! 

You now have all the elements needed to create this behavior. Below is the beginning of a solution:

```lua
-- variable defined at the root of your file
prob = 0.01

function step()

  -- == SENDER

  -- random trigger for sending
  if robot.random.uniform() < prob then
    robot.range_and_bearing.set_data({1,0,0,0})
  else
    robot.range_and_bearing.set_data({0,0,0,0})
  end


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

You need to pay close attention to see when the lights are triggered! At this stage, you have communication and reactive behavior between robots. However, this does not yet produce emergent behavior, only random activity. Let's now see if we can make the robots synchronize their blinking.


### Synchronisation
In this section, the robots will blink at a predefined frequency (defined as a *period* of time between blinks, counted in ticks), but with a random starting *phase* offset (in ticks, as well). Our aim is for the robots to align in terms of their *phase* offsets, so they can blink in unison. First, let's focus on the individual behavior, without communication. We want each robot to increment a counter until it reaches a certain threshold (the *period* of the oscillation), and once it reaches it, trigger a blink and reset the counter to zero. This counter is initialised with a random value, so that not all robots start together!

This may feel like a lot to code at first, so approach it step by step. First, the counting, use `log` to check the counter, or **Shift-Click** on a robot to inspect the counter from the variable panel. Then the threshold, an `if` test that resets the counter. And finally  setting the color of the LEDs when (and only when) the counter goes over the threshold. Take some time to try it out (the goal here is to practice, more than the result itself) and once you feel ready, you can draw inspiration from the solution below:


```lua
period = 50 -- the period of the oscillation, in ticks
counter = 0


-- we initialize the counter to a random value, between 0 and period
function init()
  counter = robot.random.uniform(period)
end


function step()
  
  -- default state (LEDs off)
  robot.overo_leds.set_all_colors(0,0,0)
  
  -- We increment the counter...
  counter = counter + 1

  -- ... and reset once the counter reaches the period
  if counter >= period then
    counter = 0
    robot.overo_leds.set_all_colors(1,1,0)
  end


  -- To display the light for more than just one tick, uncomment the following lines
--[[
  if counter < 3 then
    robot.overo_leds.set_all_colors(1,1,0)
  end
]]

end

-- We use the reset function this time!!!
function reset()
	counter = robot.random.uniform(period)
end

```

Let's now add the communication layer. Robots should only send a signal when they are blinking (i.e., when the threshold period is reached). Now the key for phase alignment: when receiving at least one signal from a neighbor, robots will slightly increase their counter (on top of the usual counting). Try experimenting with this idea (depending on the remaining time in the course...). Below is a possible solution, in two parts.

First, the sending part:

```lua

  -- Add the following line at the beginning of the step function
  robot.range_and_bearing.set_data({0,0,0,0}) -- default behavior (no information shared)


  -- Add the following line when triggering and resetting the counter to zero
  robot.range_and_bearing.set_data({1,0,0,0})


  -- The triggering code should now look like this:
--[[
  if counter >= period then
    robot.range_and_bearing.set_data({1,0,0,0})
    counter = 0
  end
]]

```

As for the receiving part, we first define a new variable at the root of the file:

```lua
alpha = 0.2
```

Now add the following block of code at the top of the step function, which checks whether or not a message has been received, and if so, increments the counter by an amount defined by *alpha* and its current value:

```lua
  -- check for incoming messages
  local received = false
  for _, p in ipairs(robot.range_and_bearing) do
    if p.data[1] == 1 then -- check that the load has a 1, and not the default 0
      received = true
      break
    end
  end

  -- coupling
  if counter < period and received then
    counter = counter + alpha * counter
    if counter >= period then
      counter = period
    end
  end

  -- TODO might be simplified in
  -- new coupling
  if received then
    counter = counter + alpha * counter
  end
```


Does it work? You should see the robots gradually begin to blink together. However, you may have robots isolated from the main group... if a robot is outside of the communication range of the main group, it cannot receive any signal and hence cannot align its blinking with the others.

In this setup, the robots are not moving. What could happen if they were moving randomly? Or were trying to form groups? Explore some possible scenarios, and see how this impacts the synchronization of blinking across the whole swarm.

Another design choice: while having a different phase offset, all robots have the same *period*. What would happen if all robots have a different one? This becomes more challenging to implement, as you have to update both phase and period across the swarm. Try to design an algorithm that addresses that problem. Even better if you try to implement it!


## Message

I'll be honest, I didn't expect at the beginning for this session to become that extensive...

The initial idea was to have robots roaming around, with disks on the ground of different grey levels. When a robot reaches a disk of color, it would stop on it, and broadcast a message containing the grey level value. Other robots would then use this message to decide where to aggregate, forming groups based on the colors present in the environment. This would have been an aggregation mechanism using message-encoded values. If you have time, you can explore this idea further and implement it.


## Exploration - Leader & Followers

As a homework assignment (please do it...), you will code a role-taking behavior. First, have the robots explore randomly the arena, and when  they encounter another robot, check whether it is available (no  previous roles), and if so, assign one role to each robot (yourself, and send a signal to the other robot to update its role). The leader will continue exploring randomly, while the follower will track the leader at a distance (close enough to maintain contact, but not too close).

In this case, the communication encodes the robot's internal state, as well as requests for role assignment.

Good luck with this task, and please, send us an email during the week if you have any trouble with the homework. We are not expecting a perfect result, we want to see that you have engaged with the problem!



