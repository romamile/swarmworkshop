-- Use Shift + Click to select a robot
-- When a robot is selected, its variables appear in this editor

-- Use Ctrl + Click (Cmd + Click on Mac) to move a selected robot to a different location



-- Put your global variables here



--[[ This function is executed every time you press the 'execute' button ]]
function init()
   -- put your code here
end



--[[ This function is executed at each time step
     It must contain the logic of your controller ]]
function step()
   -- put your code here
	driveAsCar(20, 10)

	log("--Proximity Sensors--")
	for i = 1,8 do
    	-- log("Angle: " .. robot.proximity[i].angle ..
      --  " - Value: " .. robot.proximity[i].value)
	end

	log("--Ground Sensors--")
	dump(robot.ground)
   	log(robot.ground.center)
	log(robot.ground.left)
	log(robot.ground.right)

end

--[[ This function is executed every time you press the 'reset'
     button in the GUI. It is supposed to restore the state
     of the controller to whatever it was right after init() was
     called. The state of sensors and actuators is reset
     automatically by ARGoS. ]]
function reset()
   -- put your code here
end



--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
   -- put your code here
end

function dump(o, indent)
    indent = indent or 0
    if type(o) == "table" then
        local indent_str = string.rep("  ", indent)
        log(indent_str .. "{")
        for k, v in pairs(o) do
            if type(k) ~= "number" then k = '"' .. k .. '"' end
            if type(v) == "table" then
                log(indent_str .. "  [" .. k .. "] =")
                dump(v, indent + 1)
            else
                log(indent_str .. "  [" .. k .. "] = " .. tostring(v) .. ",")
            end
        end
        log(indent_str .. "}")
    else
        log(string.rep("  ", indent) .. tostring(o))
    end
end

function driveAsCar(forwardSpeed, angularSpeed)

  -- We have an equal component, and an opposed one   
  leftSpeed  = forwardSpeed - angularSpeed
  rightSpeed = forwardSpeed + angularSpeed

  robot.wheels.set_velocity(leftSpeed,rightSpeed)
end

