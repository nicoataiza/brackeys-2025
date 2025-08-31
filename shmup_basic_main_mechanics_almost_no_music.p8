pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--TODO
--JUICE
--MUSIC -- all of it
actor_metatable = {
    defaults = {
        x = 0,
        y = 0,
        speed = 1,
        w = 8,
        h = 8,
        hit_w = 8,
        hit_h = 8,
        hp = 5,
        spr = 1,
        type = 1,
        state = 0,
        spr_w = 1,
        spr_h = 1,
        dx = 1,
        dy = 1
    },
}

game_state = "title"

--stars back ground
starx = {}
stary = {}
starspd = {}

function move(obj)
    if obj.osc then
        obj.dx = sin(t/45)
    end
    if obj.follows then
        if player.x + player.w/2 < obj.x + obj.w/2 then
            obj.dx = -0.5
        elseif player.x + player.w/2 > obj.x + obj.w/2 then
            obj.dx = 0.5
        else
            obj.dx = 0
        end
    end
    if obj.perpendicular then
        if obj.dx==0 then
            --go down first
            obj.dy=1
            if player.y <= obj.y then
                obj.dy = 0
                if player.x < obj.x then
                    obj.dx = -1
                else
                    obj.dx=1
                end
            end
        end
    end
    obj.x += obj.dx
    obj.y += obj.dy
end

function starfield()
    for i = 1, #starx do
        local star_color = 7
        if starspd[i] < 1 then
        elseif starspd[i] < 1.5 then
            star_color = 1
        end

        pset(starx[i], stary[i], star_color)
    end
end

function draw_stars()
    for i = 1, #stary do
        stary[i] = (stary[i] + starspd[i]) % 128
    end
end

--utils
function make_actor(x, y, speed, w, h, hit_w, hit_h,hp, spr, type, state, spr_w, spr_h)
    -- Create a new, empty table to represent the actor
    local new_actor = {
        x = x,
        y = y,
        speed = speed,
        w = w,
        h = h,
        hit_w = hit_w,
        hit_h = hit_h,
        hp = hp,
        spr = spr,
        type = type,
        state = state,
        spr_w = spr_w,
        spr_h = spr_h
    }
    new_actor.dx = 1
    new_actor.dy = 1
    -- Set its metatable to the actor_metatable
    setmetatable(new_actor, actor_metatable)
    return new_actor
end

function draw_actors(table)
    for i = 1, #table do
        local actor = table[i]
        if actor then
            spr(actor.spr, actor.x, actor.y)
        end
    end
end


function collision(a, b)
    local a_left = a.x
    local a_top = a.y
    local a_right = a.x + a.w - 1
    local a_bottom = a.y + a.h - 1

    local b_left = b.x
    local b_top = b.y
    local b_right = b.x + b.w - 1
    local b_bottom = b.y + b.h - 1

    if a_top > b_bottom then return false end
    if b_top > a_bottom then return false end
    if a_left > b_right then return false end
    if b_left > a_right then return false end
    if a_right < b_left then return false end
    if a_bottom < b_top then return false end
    if b_right < a_left then return false end
    if b_bottom < a_top then return false end

    return true     
end

--player code
function move_player(player)
    --ship movement
    if btn(0) then
        player.x = player.x - player.speed
    end
    if btn(1) then
        player.x = player.x + player.speed
    end
    if btn(2) then
        player.y = player.y - player.speed
    end
    if btn(3) then
        player.y = player.y + player.speed
    end
    limit_player(player)

    --shoot
    if btn(5) and player.bullet_cooldown <= 0 then
        -- shoot bullet
        player_shoot_bullet(player, bullet_table)
    end
    player.bullet_cooldown = max(player.bullet_cooldown - 1, 0)
    --bomb

    if btn(4) and abs(player.bomb_progress - 1) <= 0.001 then
        player_bomb(player, enemy_bullet_table)
        player.bomb_progress=0
    end
end

function player_bomb(player, enemy_bullet_table)
    --clear all enemy bullets
    for bullet in all(enemy_bullet_table) do
        del(enemy_bullet_table, bullet)
    end
    bomb_clear_time = 15
    next_t = 100000000
    current_wave.fire_freq = 1000000
end

function player_shoot_bullet(player, bullet_table)
    if player.bullet_cooldown <= 0 then
        -- shoot bullet
        p_bullet = make_actor(player.x, player.y - 2, 3, 8, 8, 2, 7, 1, 2, 1)
        add(bullet_table, p_bullet)
        player.bullet_cooldown = 4
    end
end

function limit_player(player)
    if player.x < 0 then
        player.x = 0
    elseif player.x > 128 - player.w then
        player.x = 128 - player.w
    end
    if player.y < 10 then
        player.y = 10
    elseif player.y > 128 - player.h then
        player.y = 128 - player.h
    end
end

function draw_player_hp(player)
    for i = 1, player.hp do
        if i <= player.current_hp then
            spr(9, (i) * 9 - 8, 2)
        else
            spr(10, (i) * 9 - 8, 2)
        end
    end
end

function player_collision(player, b)
    --hitbox is center of player sprite
    local player_hitbox = {
        x = flr(player.x + player.w / 2 - 1),
        y = flr(player.y + player.h / 2 - 1),
        w = player.hit_w,
        h = player.hit_h
    }
    return collision(player_hitbox, b)
end

function near_miss(player, enemies, enemy_bullet_table)
    --do this for all hazards
    for i = 1, #enemies do
        local enemy = enemies[i]
        if enemy then
            local player_hitbox = {
                x = (player.x - 3),
                y = (player.y - 3),
                w = player.w + 6,
                h = player.h + 6
            }
            if collision(player_hitbox, enemy) and not player_collision(player, enemy) and not enemy.dodge then
                player.bomb_progress = min(player.bomb_progress + 0.05, 1)
                enemy.dodge = true
            end
        end
    end
    for i = 1, #enemy_bullet_table do
        local bullet = enemy_bullet_table[i]
        if bullet then
            local bullet_hitbox = {
                    x = flr(bullet.x + bullet.w / 2 - 1),
                    y = flr(bullet.y + bullet.h / 2 - 1),
                    w = bullet.hit_w,
                    h = bullet.hit_h
                }
            local player_hitbox = {
                x = (player.x - 3),
                y = (player.y - 3),
                w = player.w + 6,
                h = player.h + 6
            }
            if collision(player_hitbox, bullet_hitbox) and not player_collision(player, bullet) and not bullet.dodge then
                player.bomb_progress = min(player.bomb_progress + 0.05, 1)
                bullet.dodge = true
            end
        end
    end
end

function player_update_hp(player, enemies, enemy_bullet_table)
    -- state
    if player.state == 1 then
        player.invincible_t = player.invincible_t - 1
        if player.invincible_t <= 0 then
            player.state = 0
            player.invincible_t = 30
        end
    end

    if player.state == 0 then 
        for i = 1, #enemies do
            local enemy = enemies[i]
            if enemy and player_collision(player, enemy) then
                player.current_hp = player.current_hp - 1
                --del(enemies, enemy)
                --update player state
                player.state = 1
            end
        end
        for i = 1, #enemy_bullet_table do
            if enemy_bullet_table[i] then
                local bullet = enemy_bullet_table[i]
                --off set bullet hit_box
                if bullet.type == 3 then
                    bullet_hitbox = {
                        x = flr(bullet.x + bullet.w / 2 - 2),
                        y = flr(bullet.y + bullet.h / 2 - 2),
                        w = bullet.hit_w,
                        h = bullet.hit_h
                    }
                else
                    bullet_hitbox = {
                        x = flr(bullet.x + bullet.w / 2 - 1),
                        y = flr(bullet.y + bullet.h / 2 - 1),
                        w = bullet.hit_w,
                        h = bullet.hit_h
                    }
                end
                if bullet and player_collision(player, bullet_hitbox) then
                    player.current_hp = player.current_hp - 1
                    del(enemy_bullet_table, bullet)
                    --update player state
                    player.state = 1
                end
            end
        end
    end

    -- check collisions with bullets

    --game_over
    if player.current_hp <= 0 then
        game_state = "game_over_cutscene"
        explode(player.x, player.y, player_particles)
        t = 0
    end
end

function draw_player(player)
    if player.state == 0 then
        spr(player.spr, player.x, player.y)
    elseif player.state == 1 then
        if sin(player_t/10) > 0 then
            spr(player.spr, player.x, player.y)
        end
    end
end

--bullet code
function update_bullet(bullet_table)
    --update each bullets position
    for i = 1, #bullet_table do
        local bullet = bullet_table[i]
        if bullet then
            --move bullet
            bullet.y = bullet.y - bullet.speed

            --going out of bounds
            if bullet.y < -bullet.h - 1 then
                del(bullet_table, bullet)
            end
        end
    end
end

function draw_bullet(bullet_table)
    draw_actors(bullet_table)
end

function bullet_collision(bullet, b)
    local bullet_hitbox = {
        x = flr(bullet.x + bullet.w / 2 - 1),
        y = bullet.y,
        w = bullet.hit_w,
        h = bullet.hit_h
    }
    return collision(bullet_hitbox, b)
end

--enemy bullets
function fire(enemy, angle, speed)
    local e_bullet = make_actor(enemy.x, enemy.y, 1, 8, 8, 2, 2, 1, 26, 0, 0, 1, 1, 0, 0)
    e_bullet.dx = sin(angle) * speed
    e_bullet.dy = cos(angle) * speed
    e_bullet.dodge = false
    return e_bullet
end

function fire_proba(enemy,angle,speed, proba)
    if rnd() <= proba then
        --fire big bullet
        e_bullet = make_actor(enemy.x, enemy.y, 1, 8, 8, 4, 4, 1, 42, 3, 0, 1, 1, 0, 0)
        e_bullet.time = flr(rnd(30)) + 32
    else
        --fire small bullet
        e_bullet = make_actor(enemy.x, enemy.y, 1, 8, 8, 2, 2, 1, 26, 0, 0, 1, 1, 0, 0)
        -- e_bullet.time = 100000
    end
    e_bullet.dx = sin(angle) * speed
    e_bullet.dy = cos(angle) * speed
    e_bullet.dodge = false
    return e_bullet
end

function copy_table(t)
  local r = {}
  for k,v in pairs(t) do
    r[k] = (type(v)=="table") and copy_table(v) or v
  end
  return r
end

function firespread(actor, num, speed, base, enemy_bullet_table)
    act = nil
    if actor.spr == 21 then
        act = copy_table(actor)
        act.x += (act.w / 2) - 4
        act.y += (act.h / 2) - 4
    end
    if act != nil then
        for i = 1, num do
            local bullet = fire(act, 1/num*i + base, speed)
            add(enemy_bullet_table, bullet)
        end
    else
        for i = 1, num do
            local bullet = fire(actor, 1/num*i + base, speed)
            add(enemy_bullet_table, bullet)
        end
    end
end

function enemy_shoot_bullet(enemy, enemy_bullet_table)
    -- shoot bullet straight
    -- e_bullet = fire(enemy, 0, 1)
    e_bullet = fire_proba(enemy, 0, 1, .1*wave)
    enemy.state = 0
    -- shoot towards the player if en_type == 1
    -- if enemy.type == 1 then
    --     --angle
    --     ang = atan2(player.y - bullet.y, player.x - bullet.x)
    --     bullet.dx = sin(ang) * bullet.speed
    --     bullet.dy = cos(ang) * bullet.speed
    -- end
    add(enemy_bullet_table, e_bullet)
end

function aimedfire(enemy, enemy_bullet_table)
    --shoot bullet towards the player
    local ang = atan2(player.y - enemy.y, player.x - enemy.x)
    -- bullet = fire(enemy, ang, 1)
    local e_bullet = fire_proba(enemy, 0, 1, min(.15*wave, 1))
    e_bullet.dx = sin(ang) * e_bullet.speed
    e_bullet.dy = cos(ang) * e_bullet.speed
    enemy.state = 0
    add(enemy_bullet_table, e_bullet)
end

function update_enemy_bullet(enemy_bullet_table)
    --update each bullets position
    for bullet in all(enemy_bullet_table) do
        if bullet then
            --move bullet
            bullet.y += bullet.dy
            bullet.x += bullet.dx
            if bullet.time then
                if bullet.time > 0 then
                    bullet.time -= 1
                end
                if bullet.time <= 0 then
                    firespread(bullet, 10, 1, time(), enemy_bullet_table)
                    del(enemy_bullet_table, bullet)
                end
            end
            --going out of bounds
            if bullet.x < -bullet.w - 1 then
                del(enemy_bullet_table, bullet)
            end
            if bullet.y < -bullet.h - 1 then
                del(enemy_bullet_table, bullet)
            end
            if bullet.x > 128+bullet.w + 1 then
                del(enemy_bullet_table, bullet)
            end
            if bullet.y > 128+bullet.h + 1 then
                del(enemy_bullet_table, bullet)
            end
        end
    end
end


--bomb
function draw_bomb_progress(player)
    local progress = player.bomb_progress
    local x1, y1 = 127-32, 2
    local x2, y2 = 127-1, 8
    -- outline
    rect(x1, y1, x2, y2, 7)

    -- clamp progress 0..1 and compute inner width (so fill doesn't overlap outline)
    local p = max(min(progress, 1), 0)
    local inner_w = (x2 - x1) -- space inside the outline
    local fill_w = ceil(inner_w * p)

    if fill_w > 0 then
        rectfill(x1+1, y1+1, x1 + fill_w - 1, y2-1, 8)
    end

    ----CHECK FOR BOMB READYNESS
    if abs(progress - 1) <= 0.001 then
        -- shadow + text so it's readable on top of the bar
        print('ready', x1 + 7 + 1, y1 + 1, 0)
        print('ready', x1 + 7, y1 + 1, 7)
    				print('\x8e', x1-8,y1+1, 7)
    end
end

--procedural explosion
player_particles = {}
particles = {}
function explode(x, y, particles)
    local myp = {}
    --add a big one
    myp.x = x + 3
    myp.y = y + 3
    myp.sx = rnd()*3-1.5
    myp.sy = rnd()*3-1.5
    myp.age=0
    myp.size=10
    add(particles, myp)
    for i = 1, 30 do
        myp = {}
        myp.x = x + 3
        myp.y = y + 3
        myp.sx = rnd()*3-1.5
        myp.sy = rnd()*3-1.5
        myp.age=10 + rnd(10)
        myp.size=1+rnd(4)
        add(particles, myp)
    end
end

function update_explode(particles)
    for particle in all(particles) do
        particle.x = particle.x + particle.sx
        particle.y = particle.y + particle.sy
        particle.sx = particle.sx * 0.9
        particle.sy = particle.sy * 0.9
        particle.age -= 1
        if particle.age <= 0 then
            particle.size -= .5
            if particle.size <= 0 then
                del(particles, particle)
            end
        end
    end
end
function draw_explode(particles)
    for particle in all(particles) do
        if particle.age < 3 then
            pc = 2
        elseif particle.age < 5 then
            pc = 8
        elseif particle.age < 9 then
            pc = 9
        elseif particle.age < 12 then
            pc = 10
        end
        circfill(particle.x, particle.y, particle.size, pc)
    end
end

--enemies
function enemy_state_manager(enemy)
    --0=idle
    --1=fly in
    --1=moving
    --2=attack
    --3=shoot
    --3=hit
    --4=die
    if enemy.wait > 0 then
        enemy.wait -= 1
        return
    end
    if enemy.state == 0 then
        --idle
        -- enemy.y += 10
    end
    if enemy.state == 1 then
        enemy.x += (enemy.pos_x - enemy.x) / 8
        enemy.y += (enemy.pos_y - enemy.y) / 8
        if abs(enemy.y - enemy.pos_y) <= 1 then
            enemy.state = 0
            enemy.x = enemy.pos_x
            enemy.y = enemy.pos_y
        end
    end
    if enemy.state == 2 then
        
        if enemy.x < 32 and enemy.osc then
            enemy.dx += 1-(enemy.x/32)
        end
        if enemy.x > 88 and enemy.osc then
            enemy.dx -= (enemy.x-88)/32
        end
        move(enemy)
    end
    if enemy.state == 3 then
        if enemy.type == 1 then
            enemy_shoot_bullet(enemy, enemy_bullet_table)
            -- firespread(enemy, 10, 1, rnd(), enemy_bullet_table)
        end
        if enemy.type == 2 then
            aimedfire(enemy, enemy_bullet_table)
        end
        if enemy.type == 5 then
            --boss shoot
            if t % 10 == 0 then
                firespread(enemy, 16, 1, rnd(), enemy_bullet_table)
            end
        end
        enemy.state = 0
    end
end

function pick_attack(enemies)
    --randomly update state
    if game_state != "game" then
        return
    end
    -- local curr_enemy = rnd(enemies)
    -- make sure they're idle first
    if t % current_wave.attack_freq == 0 then
        local chosen = flr(rnd(min(8, #enemies)))
        local chosen = #enemies - chosen
        local curr_enemy = enemies[chosen]
        if curr_enemy == nil or curr_enemy.type == 5 then return end
        if curr_enemy.state == 0 then
            curr_enemy.state = 2
        end
    end
end

function pick_fire(enemies)
    --randomly update state
    if game_state ~= "game" then
        return
    end

    if t >= next_fire or t % current_wave.fire_freq == 0 then
        if wave == 4 then
            for curr_enemy in all(enemies) do
                if curr_enemy.type == 5 and curr_enemy.state == 0 then
                    curr_enemy.state = 3
                end
            end
        elseif wave == 6 then
            --boss fire: all enemies shoot
            for curr_enemy in all(enemies) do
                if curr_enemy.state == 0 then
                    curr_enemy.state = 3
                end
            end
        else
            if #enemies > 0 then
                local chosen = flr(rnd(#enemies)) + 1
                local curr_enemy = enemies[chosen]
                if curr_enemy and curr_enemy.state == 0 then
                    curr_enemy.state = 3
                end
            end
        end

        next_fire = t + flr(rnd(current_wave.fire_freq)) + flr(current_wave.fire_freq / 2)
    end
end
-- function pick_fire(enemies)
--     --randomly update state
--     if game_state != "game" then
--         return
--     end
--     -- local curr_enemy = rnd(enemies)
--     -- make sure they're idle first
    
--     if t >= next_fire or t % current_wave.fire_freq == 0 then
--         if wave == 4 then
--             local curr_enemy = enemies[1]
--             if curr_enemy == nil then return end
--             if curr_enemy.state == 0 then
--                 curr_enemy.state = 3
--             end
--         else if wave == 5 then
--             --boss fire
--             for curr_enemy in all(enemies) do
--                 if curr_enemy.state == 0 then
--                     curr_enemy.state = 3
--                 end
--             end
--         else
--             local chosen = flr(rnd(#enemies))
--             local curr_enemy = enemies[chosen]
--             if curr_enemy == nil then return end
--             if curr_enemy.state == 0 then
--                 curr_enemy.state = 3
--             end
--         end
        
--         next_fire = t + rnd(current_wave.fire_freq) + flr(current_wave.fire_freq / 2)
--     end
-- end

function spawn_enemy(x, y, en_type, en_wait)
    -- spawn enemy at random x position at top of screen
    -- x = flr(rnd(120))
    -- y = -8
    local enemy = make_actor(x, y, 3, 8, 8, 8, 8, 3, 1, en_type, 1, 1, 1, 0, 1)
    --pos_ is target position, x is where the enemy will spawn
    enemy.pos_x = x
    enemy.pos_y = y

    --spawn offscreen
    enemy.y -= 66
    enemy.x = enemy.x*1.3 - 32
    enemy.dx = 0
    --wait time during spawn
    enemy.wait = en_wait
    --enemy map
    if en_type == 1 then
        --cupcake: basic enemy
        enemy.spr=17
        enemy.hp=2
        enemy.osc = true
        enemy.shoot = flr(rnd(60))
    elseif en_type == 2 then
        --deberry
        enemy.spr=18
        enemy.hp=6
        enemy.follows = true
        enemy.shoot = flr(rnd(300))
    elseif en_type == 3 then
        --rainbow
        enemy.spr=19
        enemy.hp = 7
        enemy.perpendicular = true
    elseif en_type == 4 then
        --pretzel
        enemy.spr=20
    elseif en_type == 5 then
        --chocolate chip
        enemy.spr=21
        enemy.hit_h=16
        enemy.hit_w=16
        enemy.hp = 80
        enemy.w=16
        enemy.h=16
        enemy.y=-enemy.h
        enemy.spr_w=2
        enemy.spr_h=2
    end
    
    enemy.flash = 0
    add(enemies, enemy)
end

function update_enemies(enemies)
    for i = 1, #enemies do
        local enemy = enemies[i]
        if enemy then
            --move enemy down
            enemy_state_manager(enemy)
            --enemy is dead
            if enemy.hp <= 0 then
                del(enemies, enemy)
                explode(enemy.x, enemy.y, particles)
            end

            --going out of bounds
            if enemy.state != 1 and enemy.y > 128 then
                del(enemies, enemy)
            end
            if enemy.state != 1 and (enemy.x < -40 or enemy.x > 156 or enemy.y < -16 or enemy.y > 136) then
                del(enemies, enemy)
            end
        end
    end
    if #enemies != 0 then
        pick_attack(enemies)
        pick_fire(enemies)
    end
end

function draw_enemies(enemies)
    for i = 1, #enemies do
        local actor = enemies[i]
        if actor then
            -- flashing
            if actor.flash > 0 then
                actor.flash -= 1
                for i = 1, 15 do
                    pal(i, 7)
                end
            end
            spr(actor.spr, actor.x, actor.y, actor.spr_w, actor.spr_h)
            pal()
        end
    end
end

function enemy_update_hp(enemies, bullet_table)
    for i = 1, #enemies do
        local enemy = enemies[i]
        if enemy then
            for j = 1, #bullet_table do
                local bullet = bullet_table[j]
                if bullet then
                    if bullet_collision(bullet, enemy) then
                        del(bullet_table, bullet)
                        enemy.flash=3
                        enemy.hp = enemy.hp - 1
                    end  
                end
            end
        end
    end
end

function place_enemy(level)
    local curr_level = wave_map[wave]
    -- col then row
    for y = 1, #curr_level do
        for x = 1, #curr_level[y] do
            if curr_level[y][x] != 0 then
                spawn_enemy(x * 12 - 6, y * 12 + 4, curr_level[y][x], x * 3)
            end
        end
    end
end

function wave_manager(wave)
    local curr_wave = {}
    -- Do something with curr_wave
    if wave == 1 then
        curr_wave.attack_freq = 100
        curr_wave.fire_freq = 30
    elseif wave  == 2 then
        curr_wave.attack_freq = 70
        curr_wave.fire_freq = 15
    elseif wave == 3 then
        curr_wave.attack_freq = 30
        curr_wave.fire_freq = 15
    elseif wave == 4 then
        curr_wave.attack_freq = 60
        curr_wave.fire_freq = 1
    elseif wave == 5 then
        curr_wave.attack_freq = 100
        curr_wave.fire_freq = 15
    elseif wave == 6 then
        curr_wave.attack_freq = 60
        curr_wave.fire_freq = 1
    end
    return curr_wave
end
wave_map = {
    {
        {1,1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1,1,1}

    },
    {
        {1,1,2,2,1,1,2,2,1,1},
        {1,1,2,2,1,1,2,2,1,1},
        {1,1,2,2,1,1,2,2,1,1}
    },
    {
        {3,3,1,2,1,2,1,2,3,3},
        {3,3,2,1,2,1,2,1,3,3},
        {3,3,1,2,1,2,1,2,3,3},
    },
    {
        {3,3,0,0,0,0,0,0,3,3},
        {3,3,0,0,5,0,0,0,3,3},
        {3,3,0,0,0,0,0,0,3,3},
    },
    {
        {2,1,2,0,2,2,0,2,1,2},
        {2,1,2,0,1,1,0,2,1,2},
        {0,0,0,0,0,0,0,0,0,0},
    },
    {
        {0,0,0,0,0,0,0,0,0,0},
        {0,5,0,0,0,0,0,5,0,0},
        {0,0,0,0,0,0,0,0,0,0},
    },
}


--wave
function start_wave()
    game_state = "wave_text"
    wave = wave + 1
    if #enemies == 0 and wave < 4 then
        -- spawn_enemy(flr(rnd(120)),-8, 1)
        place_enemy()
        current_wave = wave_manager(wave)
    end
    if wave == 4 then
        -- spawn special enemy
        place_enemy()
        current_wave = wave_manager(wave)
    end
    if wave == 5 then
        -- spawn special enemy
        place_enemy()
        current_wave = wave_manager(wave)
    end
    if wave == 6 then
        -- spawn special enemy
        place_enemy()
        current_wave = wave_manager(wave)
    end
end
--some code for wave management

--win!
function win_game()
    if wave >= 7 then
        game_state = "win"
        t = 0
    end
end

--game manager
function update_game()
    if game_state == "title" then
        -- title screen logic
        if btnp(4) then
            --starting cutscene
            start_wave()
        end
    elseif game_state == "game" then
        --track current frame: 30 frames per second
        --change this when scheduler requires
        t = (t + 1) % 50000
        --update moves first
        move_player(player)
        update_bullet(bullet_table)
        update_enemies(enemies)
        update_enemy_bullet(enemy_bullet_table)
        --check collision
        near_miss(player, enemies, enemy_bullet_table)
        player_update_hp(player, enemies, enemy_bullet_table)
        enemy_update_hp(enemies, bullet_table)

        --update particles
        update_explode(particles)
        --condition to end the wave
        if game_state == "game" and #enemies == 0 and #enemy_bullet_table == 0 then
            start_wave()
        end

        if #particles == 0 then
            win_game()
        end
        if bomb_clear_time > 0 then
            bomb_clear_time -= 1
        elseif bomb_clear_time == 0 then
            current_wave.fire_freq = wave_manager(wave).fire_freq
        end
    elseif game_state == "wave_text" then
        --track current
        -- wave text logic
        if wave_time == 0 then
            game_state = "game"
            wave_time = 60
            t = 0
        end
        if wave == 1 then
            if player.y > 90 then
                player.y -= 1
            else
                move_player(player)
                update_bullet(bullet_table)
                update_enemy_bullet(enemy_bullet_table)
                update_explode(particles)
            end
        else
            move_player(player)
            update_bullet(bullet_table)
            update_enemy_bullet(enemy_bullet_table)
            update_explode(particles)
        end
        wave_time -= 1
    elseif game_state == "game_over_cutscene" then
        -- game over cutscene logic
        if #player_particles > 0 then
            update_explode(player_particles)
        else
            game_state = "game_over"
            t = 0
        end
    elseif game_state == "game_over" then
        -- game over logic
        if t >= lock_out then
            if btnp(4) then
                new_game()
                start_wave()
            end
        end
        t += 1
    elseif game_state == "win" then
        -- win logic
        if t >= lock_out then
            if btnp(4) then
                new_game()
                start_wave()
            end
        end
        t += 1
    end
    player_t = (player_t + 1) % 30
end

function draw_game()
    -- Draw game state
    cls(0)
    -----------------
    if game_state != "game_over" then
        starfield()
        draw_stars()
    end
    if game_state == "title" then
        print("SHMUP BASIC", 38, 50, 7)
        print("press z to start", 29, 60, 7)
    elseif game_state == "game_over_cutscene" then
        -- game over cutscene logic
        draw_enemies(enemies)
        draw_bullet(enemy_bullet_table)
        if #player_particles > 0 then
            draw_explode(player_particles)
        end
    elseif game_state == "game_over" then
        --play some cutscene first
        print("game over", 48, 50, 7)
        print("press z to restart", 24, 60, 7)
    elseif game_state == "win" then
        print("you win!", 48, 50, 7)
        print("press z to restart", 24, 60, 7)
    else
        -- -- debug -------------------------
        
        -- if act then
        --     print(act.x..','..act.y, 100, 99, 7)
        --     -- print(act.pos_y, 100, 108, 7)
        -- end
        -- print("state: " .. player.state, 90, 18, 7)
        -- print("bomb: " .. abs(player.bomb_progress - 1), 90, 26, 7)
        -- if #bullet_table > 0 then
        --     print('x,'..bullet_table[1].x, 2, 24, 7)
        -- end
        -- print(player.x..","..player.y, 2, 16, 7)
        -- if #bullet_table > 0 then
        --     local x = flr(bullet_table[1].x + bullet_table[1].w / 2 - 1)
        --     local y = bullet_table[1].y
        --     print("bullet:"..x..","..y, 2, 32, 7)
        -- end
        -- print("game_state: " .. game_state, 2, 40, 7)
        -- print("t: " .. t, 2, 90, 7)
        -- print("count:"..#enemies, 90, 80, 7)
        -- ----------------------------------------------------
        --actors
        if bomb_clear_time > 0 then
            cls(bomb_clear_anim[t % #bomb_clear_anim + 1])
            -- print("BOMB CLEAR!", 48, 50, 7)
        end
        draw_player(player)
        draw_bullet(bullet_table)
        draw_enemies(enemies)
        if #enemy_bullet_table > 0 then
            draw_bullet(enemy_bullet_table)
        end
        
        draw_explode(particles)
        --ui
        draw_bomb_progress(player)
        draw_player_hp(player)

        --text to display wave_number
        if game_state == "wave_text" then
            if wave < 6 then
                print("wave "..wave, 54, 60, ({7,7,7,6,6,6})[(player_t%6+1)])
            end
            if wave == 6 then
                print("final wave!", 44, 60, ({7,7,7,6,6,6})[(player_t%6+1)])
            end
        end
    end
end

function new_game()
    -- reset player
    player = make_actor(60, 130, 2, 8, 8, 2, 2, 5, 1, 1, 0, 1, 1)
    player.current_hp = player.hp
    player.invincible_t = 30
    player.bullet_cooldown = 0
    player.bomb_progress = 0
    -- reset enemies
    enemies = {}
    -- reset bullets
    bullet_table = {}
    enemy_bullet_table = {}
    next_fire = 100000
    --reset particles
    particles = {}
    -- reset wave
    wave = 0
    -- reset time
    bomb_clear_anim = {5,5,13,13,5,5,13,13}
    bomb_clear_time = 0
    t = 0
    wave_time = 60
    lock_out = 30
    player_t = 0
end

--main
function _init()
    cls(0)
    -- make player code
    game_state = "title"
    new_game()

    for i=1, 70 do
        add(starx, flr(rnd(128)))
        add(stary, flr(rnd(128)))
        add(starspd, rnd(1.5) + 0.5)
    end
end

function _update()
    update_game()
end

function _draw()
    -- Draw game state
    -- debug: print bullet queue
    draw_game()
end

__gfx__
00000000000660000009900000000000000000000000000000000000000000000000000008800880088008800000000000000000000000000000000000000000
00000000001661000009900000000000000000000000000000000000000000000000000087788888800880080000000000000000000000000000000000000000
00700700001771000009900000000000000000000000000000000000000000000000000087888888800000080000000000000000000000000000000000000000
0007700001cb3c100009900000000000000000000000000000000000000000000000000088888888800000080000000000000000000000000000000000000000
0007700051cbbc15000a900000000000000000000000000000000000000000000000000008888880080000800000000000000000000000000000000000000000
007007007cc11cc70007a00000000000000000000000000000000000000000000000000000888800008008000000000000000000000000000000000000000000
000000000cc77cc00000700000000000000000000000000000000000000000000000000000088000000880000000000000000000000000000000000000000000
00000000010660100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000008800009aaa0000499900000000000000099999900000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aee88e009aaaaa004999990099009900009999999999000000009999990000000000000000000000000000000000000000000000000000000000000
00000000eeeceeee9aaaaaaa49e9c999944994490099999994999900000999999999900000000000000880000000000000000000000000000000000000000000
0000000084e4e4beaaa8eaaa99e99b99900990090999999994499990009999999499990000000000008778000000000000000000000000000000000000000000
000000000f4f4f40aaa88aaa99988999909449090999949999999990099999999449999000000000008778000000000000000000000000000000000000000000
000000000ffffff0aaaaaaaa99c97799494004949999444999999999099994999999999000000000000880000000000000000000000000000000000000000000
000000000ffffff00aaaaaa009999990049999409999944999999999999944499999999900000000000000000000000000000000000000000000000000000000
0000000000ffff0000aaaa0000999900004444009999999999944999999994499999999900000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000009999999999994999999999999994499900000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000001994499999999999999999999999499900000000008888000000000000000000000000000000000000000000
0000000000000000000000000000000000000000099999944999999019944999999999990000000008e66e800000000000000000000000000000000000000000
00000000000000000000000000000000000000000199999449949990099999944999999000000000086776800000000000000000000000000000000000000000
00000000000000000000000000000000000000000019999999999900019999944994999000000000086776800000000000000000000000000000000000000000
0000000000000000000000000000000000000000000119999999900000199999999999000000000008e66e800000000000000000000000000000000000000000
00000000000000000000000000000000000000000000099999900000000119999999900000000000008888000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000009999990000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008800005aaa000049990000000000000009999990000000000000000000000000099999900000000000000000000000000000000000000000000000000000
0aee88e005aaaaa00499999009900990000999999999900000000999999000000009999999999000000009999990000000000000000000000000000000000000
eeeceeeeaaaaaaaa99e9c99994499449009999999499990000099999999990000099999994999900000999999999900000000000000000000000000000000000
e4e4e4beaaa8eaaa99e99b9990099009099999999449999000999999949999000999999994499990009999999499990000000000000000000000000000000000
0f4f4f40aaa88aaa9998899990944909099994999999999009999999944999900999949999999990099999999449999000000000000000000000000000000000
0ffffff0aaaaaaaa99c9779949400494999944499999999909999499999999909999444999999999099994999999999000000000000000000000000000000000
0ffffff00aaaaaa00999999004999940999994499999999999994449999999999999944999999999999944499999999900000000000000000000000000000000
00ffff0000aaaa000099990000444400999999999994499999999449999999999999999999944999999994499999999900000000000000000000000000000000
00000000000000000000000000000000999999999999499999999999999449999999999999994999999999999994499900000000000000000000000000000000
00000000000000000000000000000000999449999999999999999999999949999994499999999999999999999999499900000000000000000000000000000000
00000000000000000000000000000000099999944999999099944999999999990999999449999990999449999999999900000000000000000000000000000000
00000000000000000000000000000000099999944994999009999994499999900999999449949990099999944999999000000000000000000000000000000000
00000000000000000000000000000000009999999999990009999994499499900099999999999900099999944994999000000000000000000000000000000000
00000000000000000000000000000000000999999999900000999999999999000009999999999000009999999999990000000000000000000000000000000000
00000000000000000000000000000000000009999990000000099999999990000000099999900000000999999999900000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000999999000000000000000000000000009999990000000000000000000000000000000000000
__gff__
0001020000000000000000000000000000040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004040400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
