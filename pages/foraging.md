---
layout: default
title:  "Foraging"
num: 4
---




## Remembering where you came from: Odometry

```lua
function update_vector_with_odometry(v)
  local dl = robot.wheels.distance_left
  local dr = robot.wheels.distance_right
  local L  = robot.wheels.axis_length

  local dtheta = (dr - dl) / L
  local d = (dr + dl) / 2

  v = v - vector2(d, 0)
  v:rotate(-dtheta)

  return v
end
```

```lua

target = vector2(0,0)
t = 0


function step()

  -- Possible issue with gliding ! Like into walls or other robots, then encoder info isn t accurate anymore! Like walking in a wall, and continuously walking, thinking we are advancing
  t = t+1
  target = update_vector_with_odometry(target)
  
  if(t%700 < 500) then
    wRand = 1
    wTarg = 0
    robot.overo_leds.set_all_colors(0,0,0)
	else 
    robot.overo_leds.set_all_colors(1,0,0)
    wRand = 0
    wTarg = 1
	end

  f = wRand * random_walk_force() + wTarg * target
  force_to_wheels(f)

end

```

## Simulating real life: Noise

Can be added to and with:



```xml
<sensors>
    <epuck_range_and_bearing implementation="medium" medium="rab" show_rays="false" data_size="2" noise_std_dev="0.0" real_range_noise="false" max_packets="UINT32_MAX" loss_probability="0.0"/>
    <epuck_proximity implementation="default" noise_level="0.1"/>
    <epuck_light implementation="default" noise_level="0.1"/>
    <epuck_ground implementation="rot_z_only" noise_level="0.1"/>
<sensors/>

<actuators>
    <epuck_wheels implementation="default" noise_std_dev="1"/>
    <differential_steering implementation="default"
                       vel_noise_range="-0.1:0.2"
                       dist_noise_range="-10.5:13.7" />
<actuators/>
```

Attribute 'vel_noise_range' regulates the noise range on the velocity returned by the sensor. Attribute 'dist_noise_range' sets the noise range on the distance covered by the wheels.


## Foraging alone, sad

black is the nest, grey is the resource. Good luck.


need to add the new floor file.

Working but .... robots seem to lose too quickly their past info when reaching it... 
Should add : if reached, then continue with inertia (or just continue...) and if in 2 seconds, haven t seen something, then you forget

```lua

BLACK_THRESHOLD = 0.3
GREY_THRESHOLD = 0.6
REACHING_RANGE = 1
MAX_SPEED = 10

-- put an _ in front of the name of the variable you want to appear on top of the inspector, so you can see them live !
_state = "EXPLORE"

resource = nil
nest = nil
target = nil

angle = 0




function step()

-- update all stored vectors with odometry
  if resource then resource = update_vector_with_odometry(resource) end
  if nest then nest = update_vector_with_odometry(nest) end
  if target then target = update_vector_with_odometry(target) end

  -- detect zones
  local on_resource = robot.ground.center > GREY_THRESHOLD and robot.ground.center < 0.7
  local on_nest     = robot.ground.center < BLACK_THRESHOLD

  if on_resource then
    resource = vector2(0,0)
  end

  if on_nest then
    nest = vector2(0,0)
  end


  if _state == "EXPLORE" then
    robot.overo_leds.set_all_colors(0,0,0)
    if resource then robot.overo_leds.set_single_color(1, 1,0,0) end
    if nest     then robot.overo_leds.set_single_color(2, 0,0,1) end

    if resource and nest then
    	if on_nest then
        _state = "TO_RESOURCE"
        target = resource
      end

    	if on_resource then
        _state = "TO_NEST"
        target = nest
      end
    end

  elseif _state == "TO_RESOURCE" then
    robot.overo_leds.set_all_colors(1,0,0)
    target = resource
	 
    if on_resource then
      _state = "TO_NEST"
      target = nest
    end

    if resource:length() < REACHING_RANGE then
      resource = nil
      target = nil
      _state = "EXPLORE"
  	 end

  elseif _state == "TO_NEST" then
    robot.overo_leds.set_all_colors(0,0,1)
    target = nest

    if on_nest then
      _state = "TO_RESOURCE"
      target = resource
    end

    if nest:length() < REACHING_RANGE then
      nest = nil
      nest = nil
      _state = "EXPLORE"
  	 end

  end


  wProx = -10
  wRand = 1
  wTarg = 1
  wRAB = -1

  f = vector2(0,0)

  if _state == "EXPLORE" then
  	 f = wProx * proximity_to_force() + wRAB * rab_to_force() + wRand * random_walk_force()
  else
    targ = vector2(target.x, target.y)
	 targ:normalize()
    f = wProx * proximity_to_force() + wRAB * rab_to_force() + wTarg * targ
  end

  force_to_wheels(f)

end
```






## Social Odometry

## Exploration - Social Foraging & Decision
