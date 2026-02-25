---
layout: default
title:  "Foraging"
num: 2
---


Foraging is the sum of multiple behaviors. We saw the basis about navigation, but we need still to polish it, and to add other building blocks in order to be able for our lovely robots to forage. But first, let's take a step back.

## A better control over our experiments
One file you have been using but we haven't talked much about is the **expSetup.argos** configuration file. If your lua code is all about your robot, that file is all about the arena and what is inside.

We won't go through an exhaustive description of it, but show you how it looks like, and pinpoint some usefull modifications. First, always keep a copy of it to revert back any modification (if you didn't, you can get the original [here](http://romamile.com/swlang/assets/setup/expSetup.argos)).

The file follows an XML format, and is seperated in sections:
* **framework** defines global conditions of the experience such as the random seed we use (good for repetability) or the lenght in time of the experiment;
* **controllers** defines the kind of controller we will use, and which sensor and actuators they have access to;
* **arena** defines the physical elements in the arena: floor, walls, lights, and what robots to instantiate.
* **physic engines** and **media** defines what engine to use, as well as what communication channels are permitted in this space (light, range and bearing, etc etc)
* **visualization** defines the positions of camera, as well as other visual parametres

In our case, we will mostly touch the **arena** section. One exeptions to that is to search for **show_rays** in the controller section, and to switch it values from *false* to *true*. This can be usefull for debugging the perception and range of the robot's sensors.

As for the **arena**, you can change the name of the floor picturem, the position and size of the walls, add other boxes to complexify the environment and in partiular .... modify the number of robots! It is time for our swarm to be more than just one robot. For that, search for the line : `<entity quantity="1" max_trials="100">` in the **arena** section, and change the value of **quantity** by any number of robot you want. Run your past code with various amount of robot, and see how the overall behavior is affected. In the following course, we expect a number around 20. Don't hesitate as well to modify the arena itself and complexify it.


## The third way to navigate: using forces
While the previous page's way to move around were functional, they were not the easiest to get a feel of or to work with. In this section, we will use forces to control our robot. This will make for a more natural looking behavior, and an easier one to control, to build upon and to modulate.

The underlying idea is simple: you apply one, or multiple, force to a robot, and they should react to it and move in that direction. We coul imagine force controlling not only the direction of the robot but also its speed. In most cases, we just simplify that to a direction, and move the robots to its maximum speed. You are welcomed to play with speed as well, and see how this impact the overall behavior.

The most common way to represent a force is to do so as a vector. Lua doesn't have much knowledge of what a vector is, but ARGoS does. You can have a look of the various ways you can use a vector in the documentation [here](./ref_vector.html)



So, we start from a force (a 2D vector) that we want to transform into a speed value for both left and right wheels. I warm you in advance, there will be a bit of trigonometry! Any idea how to make it happen? Here is an exemple of such implementation. First the function itself:

```lua
function force_to_wheels(f)
    -- if no force is applied, then don't move!
  if f:length() == 0
	 then robot.wheels.set_velocity(0, 0) 
  end

    -- we get the angle of the force through the magic of the arctan function
  local a = math.atan(f.y, f.x)

    -- we then find the amount of turning we should do
  local s = math.abs(a) / math.pi
  local slow = (1 - s) * MAX_SPEED

    -- how this transition to left and right speed
  if a >= 0 then
    -- turning left → slow left wheel
    left = slow
    right = MAX_SPEED
  else
    -- turning right → slow right wheel
    left = MAX_SPEED
    right = slow
  end

    -- and we apply it to our wheels
  robot.wheels.set_velocity(left, right)
end

end
``` 

and its usage in the `step` function: 

```lua
  local sumForce = vector2(1, 0)
  force_to_wheels(sumForce)
```

This way is not the only way to apply a force to a robot, and absolutely not the best one. We sacrificed a lot for the sake of brievty. For instance, we cannot modulate the speed of our robot with the force, or change how strongley robots can turn on their own axis. You might want to play with the code, and complexify it to be able to have better control over your robot. Now, let's use that system to control our robots.



## Avoidance
First, let's review our proximity avoidance code. We still want the same thing, to avoid running into walls (or any object you would have added to the arena since then!). Any idea on how to implement it on your own? As always here is a proposed solution:

```lua
function proximity_to_force()

  local f = vector2(0, 0)

  for i = 1, #robot.proximity do
        -- We get the value and angle for each proximity sensor
    local value = robot.proximity[i].value
    local angle = robot.proximity[i].angle

        -- we compute the direction vector of the sensor
    local dir = vector2(1, 0)
    dir:rotate(angle)

        -- and we add it as a repulsive force
    f = f - dir * value
  end

  return f
end
```

Now you just have to call that function, and use that force to our previous force to wheel function.


## Controling the robot
Let's add one more force, that you can somehow control too. In the arena, there is a big yellow ball, that is a light (you can control it by clicking on it with shift pressed, and then move it around with controle plus click. Just be careful to not select the ground, it crashes ARGoS!). Let's use the light sensor, and make the robots attracted to the lights like moth. The sensor is used in a same way than above, but instead of a repulsion, it is an attraction. The sensor is `robot.lights` with 8 sensors all around the robot, like the proximity sensor. Any idea how to update the code above into an attraction toward light? If not, here is a proposed solution:

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

So now, you have multiple forces. You can add them in many ways, but the most standard is a weighted sum, to regulate what behavior is the most important one. For instance :


```lua
local proxF = proximity_to_force()
local lightF = light_to_force()

local sumF = 10 * proxF + 3 + lightF
sumF:normalise()

force_to_wheels(sumF)

```


## Random walk
just using a random number on top of just peroximity, easier to use together
more generic with others

And last, let's create the basis of all exploratory behaviors: a random walk. Because some times, you can't rely on bumping in walls for exploring an area.


```lua
function random_walk_force()

  -- random angle between -pi and pi
  local a = -math.pi + 2 * math.pi * math.random()

  local f = vector2(1, 0)
  f:rotate(a)

  return f
end
```


<!--
## odometry
robots don t remember their nest, so hard to come back.
Odometry, plus coming back with a probability pNest


## Finite state machine
diagram
Remembering two zones, nest and resource, and going back and force
Exploration / Exploitation loop


-->
