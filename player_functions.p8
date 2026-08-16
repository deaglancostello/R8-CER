pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

function player_init()
    levels = {"race1.p8","race2.p8","race3.p8", "race4.p8", "race5.p8", "race6.p8", "race7.p8", "race8.p8", "race9.p8", "race10.p8","mainmenu.p8","tutorial.p8"}
    player = {
        x = 84,
        y = 84,
        dx = 0,
        dy = 0,
        w = 8,
        h = 8,
        speed = 0, --speed
        max_speed = 10,
        acc = 0.6,
        da = 0, --change in angle, how hard the car is turning
        max_da = 10,
        da_acc = 0.3,
        sp = 2,
        angle_in_deg = 180,
        start = 0,
        fin_time = 0,
        cp_cd = 0,
        max_cpcd = 2,
        checkpoints = 0,
        in_rev = false,
        on_grass = false,
        flp_x = false,
        flp_y = false,
        slowing_down = false,
        fin = false,
        in_air = false
    }
    friction = 0.8
    g_friction = 0.1
    old_speed = 0
end

--making this an OOP project instead, to clean up code and make it a lot more readable when i transfer it to unity
function player_update()
    --this bool describes whether the player is on a ramp or not, the ramp flag in the editor is used for the ramps, and what the player flies over when in air
    local on_ramp = collide_map(player, "down", 4) or collide_map(player, "right", 4) or collide_map(player, "left", 4) or collide_map(player, "up", 4)
    --bool for whether a player is on a booster
    local on_booster = collide_map(player, "down", 3) or collide_map(player, "right", 3) or collide_map(player, "left", 3) or collide_map(player, "up", 3)
    --saving a bool for whether player is on cp, as it's long
    local on_cp = collide_map(player, "down", 2) or collide_map(player, "right", 2) or collide_map(player, "left", 2) or collide_map(player, "up", 2)
    --saving the fin bool for later, as its quite long
    local on_fin = collide_map(player, "down", 1) or collide_map(player, "right", 1) or collide_map(player, "left", 1) or collide_map(player, "up", 1)
    --saving the on grass bool for later, its also long
    local on_grass = collide_map(player, "down", 0) or collide_map(player, "right", 0) or collide_map(player, "left", 0) or collide_map(player, "up", 0)
    if on_fin and player.start == 0 and not player.fin then
        --checks if the player is at the start and updates the start (until they leave the start) to the current time
        player.start = time()
    elseif player.checkpoints == max_checkpoints and not player.fin and on_fin then
        --checks if the player has collected all checkpoints and is on the finish
        player.fin = true
        player.fin_time = time()-player.start
        --calculating the fin time here above this
        if player.fin_time < dget(12 + dget(1)) or dget(12 + dget(1)) == 0 then
            --set the memory value at 12 + (whatever level player is on) as the finish time, stored exactly
            --an example: for level 1
            --dset(13, player.fin_time) would set the best time for level one in memory
            dset(12 + dget(1), player.fin_time)
        end
    end
    if on_cp and player.start > 0 and time()-player.cp_cd > player.max_cpcd then
        --checks if the player is on a checkpoint, and hasn't touched a checkpoint in a while
        --does not prevent the player from going over the same checkpoint multiple times, which i will have to problem solve when porting to unity
        player.checkpoints += 1
        player.cp_cd = time()
    end
    if on_booster then
        --set's the players speed to almost max when hitting a booster, as setting it to max would cause some one off problems
        player.speed = player.max_speed-3
    else
        player.max_speed = 10
    end
    if on_ramp then
        --checks to see if the player is on a ramp, if they are, set the in_air bool to true then whatever speed they were at, will stay the same. 
        player.in_air = true
        old_speed = player.speed
        if player.da != 0 then
            player.da = 0
            --if the player is turning, stop it from happening, as you can't really turn in air 
        end
    elseif on_ramp and on_grass then
        --if the player hits grass while in air, then set their speed lower than normal, as grass can't affect you in air, you also can't turn in air
        player.speed = old_speed
    else
        player.in_air = false
    end

    if player.checkpoints > max_checkpoints then
        --prevents cps going over total
        player.checkpoints = max_checkpoints
    end
    
    --⬇️ ⬆️ ⬅️ ➡️
    if not player.fin then
        
        update_speed_direction()
        --this function will change the direction of the player, based on input, and also apply forces 

        --circle calculations, oh lord
        --caps the rate at which the player can turn at after doing the calculations for how they turn
        player.da = mid(-player.max_da, player.da, player.max_da)
        --changes the players direction based on the speed at which they are turning
        player.angle_in_deg += player.da

        if player.angle_in_deg > 360 then
            player.angle_in_deg -= 360 --make sure the angle_in_deg is always between 0-360
        end
        if player.angle_in_deg < 0 then
            player.angle_in_deg += 360 --make sure the angle_in_deg is always between 0-360
        end

        player_animate()

        --all the below statements snap the player to a degree when close enough
        if player.angle_in_deg > 88 and player.angle_in_deg < 92 then
            player.angle_in_deg = 90
        end
        if player.angle_in_deg > 178 and player.angle_in_deg < 182 then
            player.angle_in_deg = 180
        end
        if player.angle_in_deg > 268 and player.angle_in_deg < 272 then
            player.angle_in_deg  = 270
        end
        if (player.angle_in_deg > 358 and player.angle_in_deg <= 360) or (player.angle_in_deg >= 0 and player.angle_in_deg < 2) then
            player.angle_in_deg = 0
        end

        --divide angle by 360 to ensure that its in radians, hence the code above to make sure its under 360
        local p_angle = player.angle_in_deg/360

        --if the player is on grass and in air, then make sure to update that
        if on_grass and not player.in_air then
            player.on_grass = true
        else
            --otherwise ignore
            player.on_grass = false
        end

        --limiting speed if not in reverse and not slowing down
        if not player.in_rev and not player.slowing_down then
            if not player.on_grass then
                player.speed = mid(-player.max_speed, player.speed, player.max_speed)
            else
                --apply a different type of friction on grass
                player.speed = mid(-player.max_speed*g_friction, player.speed, player.max_speed*g_friction)
            end
        elseif not player.slowing_down then
            --if in reverse, go slower
            if not player.on_grass then
                --same as above
                player.speed = mid(-player.max_speed/2, player.speed, player.max_speed/2)
            else
                player.speed = mid((-player.max_speed/2)*g_friction, player.speed, (player.max_speed/2)*g_friction)
            end
        end

        --this snippet changes the x and y pos based on the angle and speed
        player.dy = -sin(p_angle) * player.speed --calculates the change in x based on the speed and angle the player is at
        player.dx = cos(p_angle) * player.speed --calculates the change in y based on the speed and angle the player is at
        --simply updates player pos, speed is limited already by player.max_da and min_da
        player.x += player.dx
        player.y += player.dy
        --update the camera, which just sticks to the player
        cam_update()
    else
        --have to optimize and fix bugs here, should be easier in unity, hopefully
        --dget(12+x, y) is the time for the current level, x starting at 0, y being the time
        if btn(🅾️) then
            --grab the level we're on
            local j = 1
            for i = 1,dget(1) do
                j = i
                --set j to the level we are on, this could be maybe phased out by
                --doing local j = dget(1)
            end
            if player.fin and dget(12) < player.fin_time then
                --set the memory value for best time
                dset(12 + j, player.fin_time)
            end
            load(levels[j])
        end
        if btn(❎) and (player.fin_time < time_to_beat or dget(12 + dget(1)) < time_to_beat) then
            local j = 1
            for i = 1,dget(1)+1 do
                j = i
            end
            if player.fin and dget(12+j) < player.fi_time then
                --same as above
                dset(12+j, player.fin_time)
            end
            if dget(1) == 12 then
                load("race1.p8")
            else
                load(levels[j])
            end
        end
    end
end

function update_speed_direction()
    if player.speed < 3 then
        --applies friction when not sped up by booster
        player.speed *= friction
    else
        --otherwise it linearly applies friction when boosting, as friction would slow you down too fast
        player.speed -= 1
    end
    if player.speed < 0.1 then
        --stops the player from keeping less than 0.1 speed, as they would never stop otherwise
        player.speed = 0
    end
    if (player.speed > 0 or player.speed < 0) and not player.in_air then
        --movement code, disabled in air
        if btn(⬅️) then
            --rotates player left
            friction = 0.5
            --set the friction to a lower value when turning, to be able to turn faster and it feels better too
            if player.da > 0 then
                player.da = 0
                --if the player was turning right, then stop that, and set the dA back to 0, to start turning left.
            end
            player.da -= player.da_acc
            --apply forces to the character in the 
        end
        --right
        if btn(➡️) then
            friction = 0.5
            --same thing as the other turning direction, lower friction feels better
            if player.da < 0 then
                player.da = 0
                --same thing as above here, set dA back to 0 if player was turning left
            end
            player.da += player.da_acc
            --apply forces
        end
    end
    if not btn(➡️) and not btn(⬅️) then
        --checks whether each button is being pressed
        --if not, set the friction higher, as friction when turning is less
        player.da = 0
        friction = 0.8
        player.max_da = 10
    end
    if btn(⬆️) then
        --speeds up the player
        --setting some bools here to make sure nothing is messed up in the logic
        player.slowing_down = false
        player.in_rev = false
        player.speed += player.acc
        old_speed = player.speed
        --this keeps track of the player speed in case they stop hitting buttons, old_speed will slow them down
    end
    if btn(⬇️) then
        --slows down the player
        player.slowing_down = false
        old_speed = player.speed
        if player.speed > 0 then
            player.speed -= 0.1
        else
            --makes the player go in reverse
            player.in_rev = true
            player.speed -= player.acc
        end
    end
    if not btn(⬇️) and not btn(⬆️) and player.speed > 0 then
        --if the player is not holding any buttons, slow them down
        player.slowing_down = true
        player.speed = old_speed
        old_speed -= 0.05
    end
end

function collide_map(object, aim, flag)
    --[[
    Checks whether an object is colliding with something on the map, based on direction

    Variables:
    * object: table --> the object to check collision on, object needs x, y, w, h
    * aim: string --> the direction of the object to check collision in
    * flag: int --> the flag (0-7) to check collision for

    returns BOOL: whether the object is colliding with the map or not
    ]]
    --obj = table needs x,y,w,h
    --aim = left,right,up,down

    --luckily unity handles this for me, all i have to do is write the code for it to slow down the player, boost, air, etc
    local obj = object
    local x = obj.x
    local y = obj.y
    local w = obj.w
    local h = obj.h

    local x1 = 0
    local y1 = 0
    local x2 = 0
    local y2 = 0

    if aim == "left" then
        x1 = x - 1 
        y1 = y
        x2 = x 
        y2 = y + h - 1
    elseif aim == "right" then
        x1 = x + w - 1 
        y1 = y
        x2 = x + w 
        y2 = y + h - 1
    elseif aim == "up" then
        x1 = x + 2 
        y1 = y - 1
        x2 = x + w - 3 
        y2 = y
    elseif aim == "down" then
        x1 = x + 2 
        y1 = y + h
        x2 = x + w - 3 
        y2 = y + h
    end

    --pixels to tiles
    x1 /= 8
    y1 /= 8
    x2 /= 8
    y2 /= 8

    if fget(mget(x1, y1), flag)
            or fget(mget(x1, y2), flag)
            or fget(mget(x2, y1), flag)
            or fget(mget(x2, y2), flag) then
        return true
    else
        return false
    end
end

function player_animate()
    --changes the player's sprite based on angle, again unity can handle this, through rotation, just have to get the speed and turning working first
    if player.angle_in_deg > 22.5 and player.angle_in_deg < 67.5 then
        player.sp = 3
        player.flp_y = false
        player.flp_x = true
    elseif player.angle_in_deg > 67.5 and player.angle_in_deg < 110 then
        player.sp = 1
        player.flp_y = true
        player.flp_x = false
    elseif player.angle_in_deg < 132.5 and player.angle_in_deg > 110 then
        player.sp = 3
        player.flp_y = false
        player.flp_x = false
    elseif player.angle_in_deg < 200 and player.angle_in_deg > 132.5 then
        player.sp = 2
        player.flp_y = false
        player.flp_x = false
    elseif player.angle_in_deg < 232.5 and player.angle_in_deg > 200 then
        player.sp = 3
        player.flp_x = false
        player.flp_y = true
    elseif player.angle_in_deg > 232.5 and player.angle_in_deg < 297.5 then
        player.sp = 1
        player.flp_x = false
        player.flp_y = false
    elseif player.angle_in_deg > 297.5 and player.angle_in_deg < 337.5 then
        player.sp = 3
        player.flp_x = true
        player.flp_y = true
    elseif player.angle_in_deg > 337.5 and player.angle_in_deg < 360 then
        player.sp = 2
        player.flp_x = true
        player.flp_y = false
    elseif player.angle_in_deg > 0 and player.angle_in_deg < 22.5 then
        player.sp = 2
        player.flp_x = true
        player.flp_y = false
    end
end

function cam_update()
    cam_x = player.x - 64
    cam_y = player.y - 64
    if cam_x < 0 then
        cam_x = 0
    elseif cam_x > 1024 then
        cam_x = 1024
    else
        cam_x = player.x - 64
    end
    if cam_y < 0 then
        cam_y = 0
    elseif cam_y > 384 then
        cam_y = 384
    else
        cam_y = player.y - 64
    end
end

function player_draw()
    local minutes = flr(flr(time()-player.start)/60)
    if player.fin then
        minutes = dget(63)
    else
        dset(63, minutes)
    end
    local seconds = (flr(time()-player.start))%60
    if seconds < 10 then
        seconds = "0"..seconds
    end
    local fin_seconds = player.fin_time%60
    if fin_seconds < 10 then
        fin_seconds = "0"..fin_seconds
    end
    local str = "time: 0.00"
    if dget(12 + dget(1)) != 0 then
        --tests if the time saved in memory is not 0
        if dget(12 + dget(1))%60 < 10 then
            --if it is, and less than a minute, then display the seconds
            str = "best: "..flr(dget(12 + dget(1))/60)..".0"..dget(12 + dget(1))%60
        else
            --else display the minutes
            str = "best: "..flr(dget(12 + dget(1))/60).."."..dget(12 + dget(1))%60
        end
    end
    if player.start != 0 then
        str = "time: "..minutes.."."..seconds
    end
    local str2 = "cp/total: "..player.checkpoints.."/"..max_checkpoints
    local str3 = "speed: "..flr(player.speed*100)..""
    local str4 = "time: "..minutes.."."..fin_seconds
    local restart = "press 🅾️/z to restart"
    local beat_the_time = "beat the target time to advance"
    local next_level = "press ❎/x to go to next track"
    local in_air = "airborne!"
    local speed_up = "boost!"
    local target_time = ""
    if time_to_beat%60 < 10 then
        --display the time in seconds
        target_time = "beat time: "..(flr(time_to_beat/60)%60)..".0"..time_to_beat%60
    else
        --display the time in minutes + seconds
        target_time = "beat time: "..(flr(time_to_beat/60)%60).."."..time_to_beat%60
    end
    --basic map drawing
    cls()
    map(0,0)
    camera(cam_x, cam_y)
    --draws a line showing where the player is exactly pointing, as i cannot rotate in p8
    line(player.x+4, player.y+4, player.x + 4 + player.dx * 10, player.y + 4 + player.dy * 10, 1)
    --draws the player sprite at the correct position and flips it based on the orientation its facing, based on the circle i calculated earlier
    spr(player.sp, player.x, player.y, 1, 1, player.flp_x, player.flp_y)
    if player.start == 0 then
        --if the time is 0, the player hasn't started yet, display the target time to beat
        print(target_time, cam_x + 64 - #target_time*2, cam_y + 32, 7)
    end
    if not player.fin then
        --horrible variable naming, but it displays the time if the player hasn't finished yet
        print(str, cam_x + 64 - #str*2 , cam_y + 8, 7)
    else
        --if the player finished, then display the finish time, which is more exact than normal time
        print(str4, cam_x + 64 - #str4*2, cam_y + 8, 7)
        --print the restart message
        print(restart, cam_x + 64 - #restart*2, cam_y + 114, 12)
        if player.fin_time < time_to_beat or dget(12 + dget(1)) < time_to_beat then
            --if the player beat the time, print the next level message
            print(next_level, cam_x + 64 - #next_level*2, cam_y + 122, 12)
        else
            --if not, tell them to beat it
            print(beat_the_time, cam_x + 64 - #beat_the_time*2, cam_y + 122, 12)
        end
    end
    if player.speed > 3 then
        --displays the SPEED UP! message when boosting
        print(speed_up, cam_x + 64 - #speed_up*2, cam_y + 40, 7)
    end
    if player.in_air then
        --displays the IN AIR! message when in air
        print(in_air, cam_x + 64 - #in_air*2, cam_y + 32, 7)
    end
    --displays the cp and total, then the speed UI
    print(str2, cam_x + 64 - #str2*2, cam_y + 16, 6)
    print(str3, cam_x + 64 - #str3*2, cam_y + 24, 12)
end

function save()
    dset(2, 1)--whether to load from a save or not
    dset(3, player.x)
    dset(4, player.y)
    dset(5, player.angle_in_deg)
    dset(6, player.speed)
    dset(7, old_speed)
    dset(8, player.start)
    dset(9, player.sp)
    dset(11, player.checkpoints)
end

function load_save()
    player.x = dget(3)
    player.y = dget(4)
    player.angle_in_deg = dget(5)
    player.speed = dget(6)
    old_speed = dget(7)
    player.start = dget(8)
    player.sp = dget(9)
    player.checkpoints = dget(11)
end

function reset_save()
    dset(2, 0)
    dset(3, 84)--player.x
    dset(4, 84)--player.y
    dset(5, 180)--player.angle_in_deg
    dset(6, 0)--player.speed
    dset(7, 0)--old_speed
    dset(8, 0)--player.start
    dset(9, 2)--player.sp
    dset(10, 0)--tutorial completed
    dset(11, 0)--player.checkpoints
end

function random(x, y, t, cnt, prime)
    --never implemented, was gonna do a random level selection
    --  (prime(t + seed) + 
    --  (xy mod prime)) mod cnt
    --  cnt is the limit on the random number
    prime = prime or 97
    cnt = cnt or 100
    xy=x*y
    return (prime*((t*xy*prime)+t)+(xy%prime))%cnt
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
