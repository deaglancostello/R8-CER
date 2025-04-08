pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

function player_init()
    player = {
        x = 80,
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
        da_acc = 0.6,
        sp = 2,
        angle_in_deg = 180,
        start = 0,
        cp_cd = 0,
        checkpoints = 0,
        in_rev = false,
        on_grass = false,
        flp_x = false,
        flp_y = false,
        slowing_down = false,
        fin = false
    }
    friction = 0.8
    g_friction = 0.1
    old_speed = 0
end

function player_update()
    if (collide_map(player, "down", 1) or collide_map(player, "right", 1) or collide_map(player, "left", 1) or collide_map(player, "up", 1)) and player.start == 0 and not player.fin then
        player.start = time()
    end
    if (collide_map(player, "down", 2) or collide_map(player, "right", 2) or collide_map(player, "left", 2) or collide_map(player, "up", 2)) and player.start > 0 and time()-player.cp_cd > 5 then
        player.checkpoints += 1
        player.cp_cd = time()
    end
    if player.checkpoints > max_checkpoints then
        player.checkpoints = max_checkpoints
    end 
    --⬇️ ⬆️ ⬅️ ➡️
    player.speed *= friction
    if player.speed < 0.1 then
        player.speed = 0
    end
    if player.speed > 0 then
        if btn(⬅️) then
            friction = 0.4
            if player.da > 0 then
                player.da = 0
            end
            player.da -= player.da_acc/4
        end
        if btn(➡️) then
            friction = 0.4
            if player.da < 0 then
                player.da = 0
            end
            player.da += player.da_acc
        end
    end
    if not btn(➡️) and not btn(⬅️) then
        player.da = 0
        friction = 0.8
    end
    if btn(⬆️) then
        player.slowing_down = false
        player.in_rev = false
        player.speed += player.acc
        old_speed = player.speed
    end
    if btn(⬇️) then
        player.slowing_down = false
        old_speed = player.speed
        if player.speed > 0 then
            player.speed -= player.acc/10
        else
            player.in_rev = true
            player.speed -= player.acc
        end
    end
    if not btn(⬇️) and not btn(⬆️) and player.speed > 0 then
        player.slowing_down = true
        player.speed = old_speed
        old_speed -= 0.1
    end
    
    player.da = mid(-player.max_da, player.da, player.max_da)
    player.angle_in_deg += player.da

    if player.angle_in_deg > 360 then
        player.angle_in_deg -= 360 --make sure the angle_in_deg is always between 0-360
    end
    if player.angle_in_deg < 0 then
        player.angle_in_deg += 360 --make sure the angle_in_deg is always between 0-360
    end

    player_animate()

    local p_angle = player.angle_in_deg/360
    if collide_map(player, "down", 0) or collide_map(player, "right", 0) or collide_map(player, "left", 0) or collide_map(player, "up", 0) then
        player.on_grass = true
    else
        player.on_grass = false
    end
    if not player.in_rev and not player.slowing_down then
        if not player.on_grass then
            player.speed = mid(-player.max_speed, player.speed, player.max_speed)
        else
            player.speed = mid(-player.max_speed*g_friction, player.speed, player.max_speed*g_friction)
        end
    elseif not player.slowing_down then
        if not player.on_grass then
            player.speed = mid(-player.max_speed/2, player.speed, player.max_speed/2)
        else
            player.speed = mid((-player.max_speed/2)*g_friction, player.speed, (player.max_speed/2)*g_friction)
        end
    end
    player.dy = -sin(p_angle) * player.speed --calculates the change in x based on the speed and angle the player is at
    player.dx = cos(p_angle) * player.speed --calculates the change in y based on the speed and angle the player is at
    player.x += player.dx
    player.y += player.dy
    cam_update()
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
    elseif player.angle_in_deg > 232.5 and player.angle_in_deg < 267.5 then
        player.sp = 1
        player.flp_x = false
        player.flp_y = false
    elseif player.angle_in_deg > 247.5 and player.angle_in_deg < 337.5 then
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
    else
        cam_x = player.x - 64
    end
    if cam_y < 0 then
        cam_y = 0
    else
        cam_y = player.y - 64
    end
end

function player_draw()
    local str = flr(time()-player.start)..""
    local str2 = player.checkpoints.."/"..max_checkpoints
    cls()
    map(0,0)
    camera(cam_x, cam_y)
    line(player.x+4, player.y+4, player.x + 4 + player.dx * 15, player.y + 4 + player.dy * 15, 8)
    spr(player.sp, player.x, player.y, 1, 1, player.flp_x, player.flp_y)
    print(str, cam_x + 64 - #str+1 , cam_y + 8, 8)
    print(str2, cam_x + 63 - #str2, cam_y + 16, 9)
    print(flr(player.speed*100), cam_x + 64, cam_y + 24, 10)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
