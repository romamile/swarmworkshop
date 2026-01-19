---
layout: default
title:  "Setting up"
num: 0
---

## The ARGoS Simulator
As mentioned in the introduction, in order to simulate both our robots and their environment, we'll use [ARGoS](http://www.argos-sim.info/), a multi-physics robot simulator easily customizable by adding new plug-ins. It can efficiently simulate large-scale swarms of robots. Its accuracy aims to be as close as possible to real simulation. It's a tool created with research in mind and used all around the world in laboratories. While we will use it as an educational tool, its constrains & quality are the same as those that would be required in a professional and research environment. In short: whatever you will create here will have real sense. If your behaviour is getting amazing result on a task, be ready to publish about it!

In order to run an experiment in ARGoS, you need three things:

* the code for the behavior of the robot(s),  either in C++ or in Lua;
* the environment code (optional, and only in C++), either to update the environment (e.g., adding and moving objects) or to add a visualization layer (very practical for debugging);
* the .argos (XML format) file describing the experimental conditions, in particular, what robot code and environment code to use, and a description of the arena and robots.

The environment code will be provided, as well as the .argos file. While we don't recommend altering the C++ environment code, you can open the .argos experiment file, and make modifications (number of robots, initial positioning, size of the area... more info about it [here](./ref_setup.html)). That being said, you will focus on the robot's behavior code, and in this workshop you will use the Lua language. While slightly slower, it is easier learn, and iterate with.


### Setting Up ARGoS & Lua
ARGoS is developed for Linux first, but can also be installed on Mac and Windows. For Linux and Mac, please go [here](http://www.argos-sim.info/core.php). For windows, please go [here](./ref_install.html). If instead, for any particular reasons, you prefere to install it from source, or are curious to have a look at the source code, ARGoS is hosted on github [here](https://github.com/ilpincy/argos3/).

In order to check if ARGoS is well installed, just run `argos3 --version` in your favorite command line, and a green text should appear with the version name of currently installed ARGoS. If you are curious about all the possibilities of ARGos, run `argos3 -q all` in the command line, it will returns you all the module that are installed. To learn more about a specific module, you can then run `argos3 -q *name-of-the-module*`.

### Running ARGoS
First, create a working directory for the workshop (we recommend as well one directory per page for this workshop), download [here](./assets/setup/setup.tar.gz) the assets you will use in this workshop, and unpack them in your working directory. In it, you will find the environment code and experimental setup we will use, as well as some pictures we will put on the floor of the arena. Now, to run ARGoS, go in your command line, in your working directory, and run: `argos3 -c expSetup.argos`. The `-c` is a flag, telling argos that the file right of it will be used as a configuration file.

<a href="./assets/argosUI.png"><img class="img-right" src="./assets/argosUI.png" alt="picture of ARGoS UI"/></a>

You should see two windows appearing. The small one is a text editor (where you will type your Lua code), the other is the ARGoS simulator itself (where you will see the robots moving and behaving erratically).

So, your simulation is set, ready to be run. To do this, use the buttons at the top: the Play button plays the simulation, the Stop button stops it, the Forward button makes it quicker by only drawing every X frame (the number on its right). The button mixing pause and play makes the simulation step by step, perfect for debugging. In the center of the software, a view of your arena, and on its right, two text area for logging purposes. And the camera movement? Done in a not so classic (but workable) way using the mouse, you'll get the hang of it...


### Your first code
In the Lua code editor, you will find that there are already some functions defined, giving your code a structure. Already well explained in the comments, they are:

* **init** called once at the creation of the robots
* **step** called at each step of the experiment
* **reset** called when the reset button is pressed
* **destroy** called at the end of the experiment

On top of Lua's syntax and libraries, ARGoS provide you with a specific container, adequately called `robot`. Anything robot related (sensor & actuator) will go through it. We will also use as a control for further visualisation. Another thing to keep in mind: the classic `print` Lua function doesn't work here, you need to use the ARGoS log function, which redirects output to the logging text areas of the simulator.

Let's fill up  our experimentation with some code. Type inside the step function the following line, where `robot.id` refers to the robot own identification number.

```Lua
log("Hello, my name is " .. robot.id)
```

Apart from the classic text editor functionality, you'll see on the right end a little gear icon. Click on it (or press **Ctrl-E**) to execute/load your code. The code is then loaded in the ARGoS simulator, and you just have to press play to run it. On the right side, you'll see time steps and logging information. In ARGoS, the simulation is executed steps by steps. At each steps (or ticks), the function `step` is called for each robot, and is resolved.

## Reference Material
Lua is a quick straight forward scripting language. If you know python, you're in good hands. If you don't want python, you're still in good hands. There is scope for variables. If you want a variable to work as some global memory of your robot, you need to make it global by defining it at the top of your code (outside of any function). You'll see that Lua has only one data structure  type, *tables*, behaving as associative arrays, they store a set of key/value pairs. As mentioned earlier, to (re?)discover Lua and/or better understand this notion of table, you might want to check our [Lua reference page](./ref_lua.html), in combination with the other [ARGoS reference page](./ref_argos.html).
