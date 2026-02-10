---
layout: default
title:  "Navigation"
num: 1
---

Interstingly, once life appeared, it took ages for navigation to be (if not solved) at least tackled enough for life to move around. Once that was done, the rest followed pretty quickly relatively. A bird doesn't navigate as a human, or as a toddler. Different hardware comes with different software solutions, and different learning mechanisms. In other word, and more specific to our cases: you don't control a car, a four leg robot or a rocket the same way. In this section, we will teach our robots how to move, hopefully quicker than life used to.

<img src="./assets/images/epuck_1.jpg" alt="picture of the epuck2" style="height:300px; float:right; margin:1em;">

## One robot, two wheels, three ways to navigate

The epuck2 has two massive wheels (relative to its small size) equipped with a differential drive (so both wheels can rotate at different speeds). Moving your robot is as direct as setting up the speed of each of those wheels. In order to connect with anything related to our robot, ARGoS provide an easy table, called `robot` that encompass all variables and function, mirroring all sensors and actuators of the robot. In this specific case, to set the speed of each wheels, we use  the `robot.wheels.set_velocity` function which accept two values (left and right speed) as parameters, both measured in cm/s. Positive values make the wheels roll forward, negative make them roll backward. For instance, to go straight:

```lua
-- You will most of the time modify the step function
function step()
  robot.wheels.set_velocity(20,20)
end
```
In this tutorial, I will sometime explicitely show where the code should go (here in the `step` function). Don't add each time the lines defining the `step` function, just add the new code inside the function. Often I will just show the code to be added, and it will be up to you to guess where it should go!

The code above is the bare metal way of controlling your robot, we will see better ways to do so. But before that, try out various speed for each wheels to get a feeling of how the robots is moving. For instance:

* moving straight and frontward is *leftSpeed = rightSpeed*. Try `robot.wheels.set_velocity(20,20)`.
* turning continously right is *leftSpeed > rightSpeed*. Try `robot.wheels.set_velocity(10,20)`.
* turning on your self is *leftSpeed = -rightSpeed*. Try `robot.wheels.set_velocity(20,-20)`.

While your moving is aimless for now, you can already create simple behaviors, like making your robot form specific shapes as they move. Try to draw a triangle. To do so, you might want to create a global variable that is incremented by 1 at the beginning of the function **step**, measuring time elapsing. Once you do that, every N ticks, turn, and move forward.

While setting directly the wheels' speed does the job, it's not really practical. This controle function makes sense to the robot, but we need to create one that makes more sense to us, the behaqior designer. For instance, it would be easier to think in terms of moving forward/backward and turning, like when driving a car. So, instead of left wheel speed and right wheel speed, we want a moving function that accepts forward speed and angular speed as parametres, and that translates them to left wheel speed and right wheel speed. Any idea on how to code that? Try to imagine if you have only forward or angular, and then compose the two of them. Below is a possible solution, don't look at it before you've tried out a little bit by yourself! To make it easier to use, we formalized it as a function. A good time as any to see how they are formated in Lua.

<img src="./assets/robot_wheels.png" alt="picture of the differential drive" style="float:right; margin:10px;">

```lua
function driveAsCar(forwardSpeed, angularSpeed)

  -- We have a component going in the same direction, and one opposed one   
  leftSpeed  = forwardSpeed - angularSpeed
  rightSpeed = forwardSpeed + angularSpeed

  robot.wheels.set_velocity(leftSpeed,rightSpeed)
end
```

Both ways of controlling your robot are equally fair, and would end up in a similar result. The point here is to find a formalism that is coherent with your overall behvior, so that it is  easier on you to implement, update and tweak it. Can you imagine other input you could give your robot in order to control it? We will see later a third and final way to controle it. For now, let's focus on stopping him bumping in the walls.

## Proximity sensor

<!--img src="./assets/robot_proximity.png" alt="proximity sensor" style="float:right; margin:10px;"-->

Coupling sensors and actuators in a behvior loop is the basis for any behaviors, this is the difference between controling your robot and it having a life of its own. Sensing your physical suroundings can be done in different ways, and often done with different sensors in paralell on the same robot. For instance, one might want to have better detection of robots in your surroundings than wooden blocks, and to have a further detection in front of you that around you. The default detection is often a battery of cheap proximity sensors all around your robot. A way for your robot to stop, or change course, when it is about to bump into a physical object.

This is exactly what the epuck have: 8 infra-red sensors measuring ambient light and proximity of objects up to 6 cm, ouputing a value between 0 and 1, 0 being no object detected, and 1 being contact with the object. In practice, and because how noisy and unreliable those sensors are, we use them as presence detection system. 0 for nothing, 1 for presence. If you react quick enough to information coming out of the sensors, it should be presence without direct contact! The eight sensors are spread around the robot in a circle. You can access their value and angle in ths `robot.proximity` table:

```lua
log("--Proximity Sensors--")
for i = 1,8 do
    log("Angle: " .. robot.proximity[i].angle .. " - Value: " .. robot.proximity[i].value)
end
```

Text log are pretty greate (they are), but are lacking a bit when you prefere overall view over precision. When you want the later, you might want to display the rays of the sensors. How? Well it's explained in the [setup ref material](./ref_setup.html#debug)!

On of the most common usage for the proximity sensors is to avoid obstacles (object, walls, other robots...). We will see in next section a better way to use such information, but we can already make something simple out of it. Can you imagine what you need to do if you want to avoid obstacles, or at least react and turn in the right direction when encountering them? Try out by yourself, and once satisfied with the result you can compare your code to the following proposition:

```lua

sensingLeft = robot.proximity[1].value + robot.proximity[2].value +
              robot.proximity[3].value + robot.proximity[4].value

sensingRight = robot.proximity[5].value + robot.proximity[6].value +
               robot.proximity[7].value + robot.proximity[8].value

if( sensingLeft ~= 0 ) then
  driveAsCar(7,-3)
elseif( sensingRight ~= 0 ) then
  driveAsCar(7,3)
else
  driveAsCar(10,0)
end
```

Great, now your robot can behave as brownian particle. You must (or at least should) be so proud of it. Well, anyway, if love is blind, so is your robot right now. Let's change that. A bit. A liiiiitle bit.

## c) Sensing: ground color
Don't expect 20/20 vision right from the start. Especially that our robots are meant to work as a team. As such, they are not pumped up with sensors all around and heavy computing power. They are simple (who said stupid?!) robots, with local sensing. And we'll get as local as one can get: watching the ground under your own feet (well, treels). Or more precisely, detecting gray level of the ground's color. This is very useful for reading marks on the ground, would that be for communication purpose, to emphasize areas of purpose, to guide robot over a path...

<img src="./assets/robot_motor_ground.png" alt="ground sensor" style="float:right; margin:10px;">

The robot have 4 grounds sensors on its lower part, each reading the brightness of the ground under them. They output a value between 0 and 1; 0 for black and 1 for white, shades of gray for values in between. Each readings is a table composed of *value* an *offset*. The value refers to the brightness and the offset to a vector for the position of the specific sensor stemming from the center of the robot. Since we have 4 sensors, we have 4 of those readings. They are all contained in the `robot.motor_ground` table and can be accessed as follow:

```lua
log("--Ground Sensors--")
log(robot.ground.center)
log(robot.ground.left)
log(robot.ground.right)
```

In this section's area are a few patterns on the ground, any idea on how to make your robot avoid them? Or get to them and stop? First you'll need a robot that will explore a bit by itself. We'll study this point better in next section, but you can already mash up something together with the `robot.random.uniform(min, max)` function. Try to implement one of both algorithm by yourself. Below is a solution for the stopping one:

```lua
onSpot = true
for i = 1,4 do
    if( robot.ground.center < 0.90 ) then -- not on a white spot
      onSpot = false
    end
end

if(onSpot) then
  driveAsCar(0,0)
else
  driveAsCar(robot.random.uniform(10,20), robot.random.uniform(-10,10))
end
```

Ok, this is working but we have definitely too many robots trying to form platonic relationships with the arena walls. If not done already, you should mix that behavior with the avoiding one. Hard to mix both of them? Damn right it is, but lucky us, we'll see in next section a glorious way to do so.

## d) Behaving: Follow the line
Ok, that is great. You can move, you can see where you are moving. What about coupling both and making you move following marks on the ground? This is actually a very classic algorithm which is solved both by first learners and highly skilled engineers, depending on the environment and precision/speed required. Our job is simple: we have a line, we want to follow it, when it's straight (simple!) and when it's turning (ergh...).


```lua
-- OK, weirdly, for that one, left and right speed was more practical...
-- Try to redo it with the car metaphor!

leftSpeed = 5
rightSpeed = 5

if(robot.ground.left < 0.40) then -- something on my left
  rightSpeed = -3
end

if(robot.ground.right < 0.40) then -- something on my rightsetup.tar.gz
  leftSpeed = -3
end

robot.wheels.set_velocity(leftSpeed, rightSpeed)
```

Neato but ... hey, this is a rip off, it's only working if the shape is convex! Well, all intelligence has its down. But why not giving a perfect solution? :( Well, first of all, you could say please. Second, I got something better: a game (or research, if you find it more sexy). Sometimes there is not one clear solution and that's when there is competition. Which is super good for the bettering of the human knowledge. And also great to watch while getting some pop corn. Your job now is actually to better this behavior. 

