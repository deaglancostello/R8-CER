pico-8 cartridge // http://www.pico-8.com
version 42
__lua__

function player_init()
    player = {
        x = 80,
        y = 80,
        dx = 0,
        dy = 0,
        speed = 0, --speed
        max_speed = 10,
        acc = 0.8,
        da = 0, --change in angle, how hard the car is turning
        max_da = 5,
        da_acc = 0.3,
        sp = 1,
        angle_in_deg = 0,
        in_rev = false,
        on_grass = false,
        flp_x = false,
        flp_y = false
    }
    friction = 0.3
    g_friction = 0.75

end

function player_update()
    --⬇️ ⬆️ ⬅️ ➡️
    if btn(⬅️) then
        player.da -= player.da_acc
    end
    if btn(➡️) then
        player.da += player.da_acc
    end
    if btn(⬆️) then
        player.in_rev = false
        player.speed += player.acc
    elseif btn(⬇️) then
        player.in_rev = true
        player.speed -= player.acc
    end
    
    player.da = mid(-player.max_da, player.da, player.max_da)
    player.angle_in_deg += player.da

    if player.angle_in_deg > 360 then
        player.angle_in_deg -= 360 --make sure the angle_in_deg is always between 0-360
    end
    if player.angle_in_deg < 0 then
        player.angle_in_deg += 360 --make sure the angle_in_deg is always between 0-360
    end

    if player.angle_in_deg > 45 and player.angle_in_deg < 135 then
        player.sp = 1
        player.flp_y = true
        player.flp_x = false
    elseif player.angle_in_deg < 225 and player.angle_in_deg > 135 then
        player.sp = 2
        player.flp_x = false
        player.flp_y = false
    elseif player.angle_in_deg > 225 and player.angle_in_deg < 360 then
        player.sp = 1
        player.flp_x = false
        player.flp_y = false
    elseif player.angle_in_deg > 0 and player.angle_in_deg < 45 then
        player.sp = 2
        player.flp_x = true
        player.flp_y = false
    end

    local p_angle = player.angle_in_deg/360
    player.speed *= friction
    if not player.in_rev then
        if not player.on_grass then
            player.speed = mid(-player.max_speed, player.speed, player.max_speed)
        else
            player.speed = mid(-player.max_speed*g_friction, player.speed, player.max_speed*g_friction)
        end
    else
        if not player.on_grass then
            player.speed = mid(-player.max_speed/2, player.speed, player.max_speed/2)
        else
            player.speed = mid((-player.max_speed/2)*g_friction, player.speed, (player.max_speed/2)*g_friction)
        end
    end
    player.dx = sin(p_angle) * player.speed --calculates the change in x based on the speed and angle the player is at
    player.dy = cos(p_angle) * player.speed --calculates the change in y based on the speed and angle the player is at
    player.x += player.dx
    player.y += player.dy
end


function player_draw()
    cls()
    map(0,0)
    camera(player.x - 64, player.y- 64)
    spr(player.sp, player.x, player.y, 1, 1, player.flp_x, player.flp_y)
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
