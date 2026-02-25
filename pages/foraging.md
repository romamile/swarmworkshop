---
layout: default
title:  "Foraging"
num: 2
---


Foraging is the sum of multiple behavior. We saw the basis about navigation, but we need still to polish it, and to add other building blocks in order to be able for our lovely robots to forage.

## A better control over our experiments
One file you have been using but we haven't talked much about is the **expSetup.argos** configuration file. If your lua code is all about your robot, that file is all about the arena and what is inside.

We won't go through an exhaustive description of it, but show you how it looks like, and pinpoint some usefull modifications. First, always keep a copy of it to revert back any modification (if you didn't, you can get the original [here](http://romamile.com/swlang/assets/setup/expSetup.argos)).

The file follows an XML format, and is seperated in sections:
* **framework** defines global conditions of the experience;
* **controllers** defines the kind of controller we will use, and which sensor and actuators they have access to;
* **arena** defines the physical elements in the arena: floor, walls, lights, and what robots to instantiate.
* **physic engines** and **media** defines what engine to use, as well as what communication channels are permitted in this space (light, range and bearing, etc etc)
* **visualization** defines the positions of camera, as well as other visual parametres

In our case, we will mostly touch the **arena** section. One exeptions to that is to search for **show_rays** in the controller section, and to switch it values from *false* to *true*. This can be usefull for debugging the perception and range of the robot's sensors.

As for the **arena**, you can change the position and size of the walls, and in partiular .... the number of robots! It is time for our swarm to be more than just one robot. For that, search for the line : `<entity quantity="1" max_trials="100">` in the **arena** section, and change the value of **quantity** by any number of robot you want. Run your past code with various amount of robot, and see how the overall behavior is affected. In the following course, we expect a number around 20.


## The third way to move around: forces
While the previous page's way to move around were functional, they were not the easiest to get a feel of or to work with. In this section, we will use forces to control our robot. This will make for a more natural looking behavior, and an easier one to control, to build upon and to modulate.

The underlying idea is simple: you apply one, or multiple, force to a robot, and they should react to it and move in that direction. We coul imagine force controlling not only the direction of the robot but also its speed. In most cases, we just simplify that to a direction, and move the robots to its maximum speed. You are welcomed to play with speed as well, and see how this impact the overall behavior.

The most common way to represent a force is to do so as a vector. Lua doesn't have much knowledge of what a vector is, but ARGoS does. You can have a look of the various ways you can use a vector in the documentation [here](./ref_vector.html)



So, we start from a force (a 2D vector) that we want to transform into a speed value for both left and right wheels. I warm you in advance, there will be a bit of trigonometry! Any idea how to make it happen? You can see bellow an exemple of an implementation

```lua

``` 


Here, we will encounter yet another formalise to help moving the robot around, this time using forces. The results are often more naturalistic, and more organic


vectors
and proximity
more generic as a reaction


<!-- could be better for language games
## Reaching out
range and bearing
avoiding robot with grace
-->


## Random walk
just using a random number on top of just peroximity, easier to use together
more generic with others


## odometry
robots don t remember their nest, so hard to come back.
Odometry, plus coming back with a probability pNest


## Finite state machine
diagram
Remembering two zones, nest and resource, and going back and force
Exploration / Exploitation loop



