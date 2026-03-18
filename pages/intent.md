---
layout: default
title:  "Intent"
num: 2
---


In the previous log, we discovered basic ways to move your robot around. In this log, we will see how to create a coherent navigation system to guide our robot with intent, whether it is to avoid obstacles (again!), to go toward the light, or to randomly explore our arena. But first, let's take a step back. We talked a lot about robots, let's focus for a moment on our experimental setup.

## A better control over our experiments
One file you have been using but we haven't talked much about is the **expSetup.argos** configuration file. If your lua code is all about your robot, that file is all about the arena and what it contains.

We won't go through an exhaustive description of it, but show you how it looks like, and pinpoint some useful modifications. First, always keep a copy of it to revert back any modification (if you didn't, you can get the original [here](https://romamile.com/swlang/assets/setup/expSetup.argos)).

On linux and mac, you can directly open the file from command line with your favorite text editor. As for windows, we recommend to run the following line in the command line: `explorer.exe .`. This will open your working folder in the standard file explorer window, which then allows you to use easily any text editor you want.

The file follows an XML format, and is separated into sections:
* **framework** defines global conditions of the experiment such as the random seed we use or the length in time of the experiment;
* **controllers** defines the kind of controller we will use, and which sensor and actuators they have access to;
* **arena** defines the physical elements in the arena: floor, walls, lights, and what robots to instantiate.
* **physics engines** and **media** defines what engine to use, as well as what communication channels are allowed (light, range and bearing, etc etc)
* **visualization** defines the positions of cameras, as well as other visual parameters

In our case, we will mostly touch the **arena** section. One exception is the **show_rays** attribute associated with sensors, in the controller section. This will show you which sensor allows its range to be visualised inside ARGoS. You can switch any of those between *false* and *true* depending on whether you want to see the rays or not in ARGoS. This can be useful for debugging the perception and range of the robot's sensors.

As for the **arena**, you can change the name of the floor picture, the position and size of the walls, add other boxes to complexify the environment and in particular .... change the number of robots! It is time for our swarm to be more than just one robot. For that, search for the line : `<entity quantity="1" max_trials="100">` in the **arena** section, and change the value of **quantity** to any number of robots you want. Run your previous code with various numbers of robots, and see how the overall behavior is affected. In the rest of the course, we expect a number of around 20 robots. Don't hesitate as well to modify the arena itself and complexify it. One thing to note, ARGoS doesn't hot reload its configuration file. If you want it to be used, you need to close ARGoS (easiest way is to press **Ctrl** + **C** in the command line) and relaunch it.

Over this course, you are not only going to develop your robotic behavior and experimental setup, but also try various settings and behaviors. This is why we recommend having multiple configuration files you can easily switch between, as well as multiple Lua code files, depending on the behavior you want to explore. 


## The third way to navigate: with forces
As mentioned above, while the previous page's ways to move around were functional, they were not the easiest to get a feel of or to work with. In this section, we will use forces to control our robot. This will make for a more natural looking behavior, and an easier one to control, to build upon and to modulate.

The underlying idea is simple: you apply one, or multiple, force to a robot, and they should react to it and move in that direction. We could imagine force controlling not only the direction of the robot but also its speed. In most cases, we just simplify that to a direction, and move the robots to its maximum speed. You are welcome to play with speed as well, and see how this impacts the overall behavior.

The most common way to represent a force is to do so as a vector. Lua doesn't have a specific structure for vectors, but ARGoS does. To learn more about how to create and use vectores, check the documentation [here](./ref_vector.html)

So, we start from a force (a 2D vector) that we want to transform into a speed value for both left and right wheels. I warn you in advance, there will be a bit of trigonometry! Any idea how to make it happen? Here is an example of such implementation. First the function itself:

```lua

-- put this value as a global parametre on the top of your file:
MAX_SPEED = 10


function force_to_wheels(f)

    -- angle of the force through the magic of the arctan function
  local a = math.atan(f.y, f.x)

    -- strenght of the turn (ratio between angle and PI)
  local s = math.abs(a) / math.pi

    -- overall speed (from lenght of the force vector)
  local m = math.min(f:length(), 1)

  if a > 0 then -- turning direction depending on the sign of a
    left = m * MAX_SPEED * (1 - s)
    right = m * MAX_SPEED
  else
    left = m * MAX_SPEED
    right = m * MAX_SPEED * (1 - s)
  end

  robot.wheels.set_velocity(left, right)
end
``` 

and its usage in the `step` function: 

```lua
  local sumForce = vector2(1, 0)
  force_to_wheels(sumForce)
```

This is an example among many on how to compute wheel speed from a force. In this code, we get the orientation of the force, how strongly we should turn, and keep the lenght of the force as a measure of the overal speed of our robot. You might want to play with the code, and complexify it to be able to have better control over your robot. Now, let's use that system to control our robots.



## Avoidance
First, let's review our proximity avoidance code. We still want the same thing, to avoid running into walls (or any object you would have added to the arena since then!). Any idea on how to implement it on your own? As always here is a proposed solution:

```lua
function proximity_to_force()

  local f = vector2(0, 0)

  -- IMPORTANT >> the # bellow is a shortcut to access the length of a table
  for i = 1, #robot.proximity do
    -- value/angle from the proximity sensor
    local value = robot.proximity[i].value
    local angle = robot.proximity[i].angle

    -- we compute the direction vector of the sensor
    local dir = vector2(1, 0)
    dir:rotate(angle)

    -- and we add it as a repulsive force
    f = f + dir * value
  end

  return f
end
```

Congratulations, you have now your first *sensor to force* function! The aim is to formalise most of them this way around, as it will make it easier for everyone (me included). Your past code on how to use the force to control the wheel was force to actuator, so now we have a full loop!


```lua
  local fProx = proximity_to_force()

  local sumForce = fProx               -- I wonder if I am not missing something here...

  force_to_wheels(sumForce)
```

Soooo you might see an issue already: the robots are being attracted to each other and to walls, and not avoiding objects! This is because the force is used here as an attractor. You might want to put a negative sign in front of it, to use it as a repulsor: `local sumForce = - fProx`.

Obstacle avoidance is a common behavior that is used in many navigation algorithme. But ... what if robots where not repulsed by others objects, but attracted to them? How could you change your code to reflect that? And how would you name this new behavior?


## Guiding the robot
Let's add one more force, that you can somehow control too. In the arena, there is a big yellow ball, that is a light (you can modify its position from the configuration file). Let's use the light sensor, and make the robots attracted to the lights like moths. The sensor is used in a same way as above, but instead of a repulsion, it is an attraction. The sensor is `robot.light` with 8 sensors all around the robot, like the proximity sensor. Any idea how to update the code above into an attraction toward light? If not, here is a proposed solution:

```lua
function light_to_force()

  local f = vector2(0, 0)

  for i = 1, #robot.light do
    local value = robot.light[i].value
    local angle = robot.light[i].angle

    local dir = vector2(1, 0)
    dir:rotate(angle)

    -- attraction: pull toward the light direction
    f = f + dir * value
  end

  return f
end
```

So now, you have multiple forces of various lengths (and hence influences). The way you combine forces determines what your robot prioritises. Should you add both forces just as is? Normalise them first, and then make a weighted sum? Many variations, fitting different contexts. You are free (and encouraged) to explore your own ways, below is one possibility among many:


```lua
local proxF = proximity_to_force()
local lightF = light_to_force()

local sumForce = 0.7* proxF + 0.3 * lightF

force_to_wheels(sumForce)

```


Finding the correct weights for the behavior you want to achieve can be finicky, especially when each functions does not return a normalized force (you might want to explore that direction). We do have a coherent system, but that doesn't mean that everything about it is obvious. Which is good in the end, because this is where we have room to modify the behavior, giving more importance to one force (and hence one sub-behavior) than to another.

Similarly to our previous obstacle avoidance force, how would you change your code so that robots are not attracted to the light, but try to hide from it? Try to play around with those forces, and their intensity. You have everything in your hand already to create [Braitenberg vehicle](https://en.wikipedia.org/wiki/Braitenberg_vehicle.)

## Random walk
And last, let's create the basis of all exploratory behaviors: a random walk. Because sometimes, you can't rely on bumping in walls for exploring an area.


```lua
-- global variable to be put at the root
angle = 0

function random_walk_force()

    -- measure of the drift
  local k = math.pi

    -- adding at each step a variation on our current angle
  angle = angle + k * (math.random() - 0.5) * 0.5

  local f = vector2(1, 0)
  f:rotate(angle)

  return f
end
```


## Simple Finite State Machine


A finite state machine (FSM) is a collection of states (the local behaviours your robot can execute) and transitions (the conditions that trigger a change from one state to another). It is a convenient way to combine several sub-behaviours into a larger behaviour, especially when these behaviours should not run in parallel.

While force-based control and FSMs can sometimes be used interchangeably, they can also be combined in a complementary way.

Let’s look at an example of how to implement a simple FSM, in which our robot explores the arena but switches to following a light source when it becomes strong enough.



```lua
-- First, we define our states at the root of our file
EXPLORE = 1
GO_TO_LIGHT = 2

state = EXPLORE


function step()

  if state == EXPLORE then -- we check in which state we are
    -- and then run the code (could have been a function)


    -- behaviour
    local f = random_walk_force()
    force_to_wheels(f)


    -- transition
    local lightF = light_to_force()
    if lightF:length() > 0.5 then
      state = GO_TO_LIGHT
      return
    end

  elseif state == GO_TO_LIGHT then

    -- behaviour
    local lightF = light_to_force()
    force_to_wheels(lightF)

    -- transition condition
    if lightF:length() <= 0.5 then
      state = EXPLORE
    end

  end

end


```


## Exploration -- Connecting lights

This exploration will give you an opportunity to reuse most of the elements introduced in this section and the previous one. It is divided into three parts.

First, modify your configuration file so that there is a single light placed in the center of the arena, with multiple robots present. Your goal, using only a single state, is to make all the robots aggregate around the light.

Second, update your configuration file again and place two lights in the arena, positioned at some distance from each other. The new objective is for your robots to spread out along the segment defined by these two lights. As a starting point, you might try making the robots move toward the midpoint between the two lights. In practice, this means that the robots should detect two peaks in their light sensors and align themselves so that these peaks are opposite each other.

Finally, if you want an additional challenge, try extending this idea with even more lights: three, four, five... and see what kinds of behaviours emerge.

Good luck!

<!--
## odometry
robots don t remember their nest, so hard to come back.
Odometry, plus coming back with a probability pNest


## Finite state machine
diagram
Remembering two zones, nest and resource, and going back and force
Exploration / Exploitation loop


-->
