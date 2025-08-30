pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--TODO
--enemy behavior
--ENEMY BULLET
--BOMB
--boss fight
--JUICE
--ENTRANCE ANIMATION
--DEATH ANIMATION
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
end

function player_shoot_bullet(player, bullet_table)
    if player.bullet_cooldown <= 0 then
        -- shoot bullet
        bullet = make_actor(player.x, player.y - 2, 3, 8, 8, 2, 7, 1, 2, 1)
        add(bullet_table, bullet)
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

function near_miss(player, enemies)
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
end

function player_update_hp(player, enemies)
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
    end

    -- check collisions with bullets

    --game_over
    if player.current_hp <= 0 then
        game_state = "game_over"
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
particles = {}
function explode(x, y)
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
        if abs(enemy.y - enemy.pos_y) <= 0.6 then
            enemy.state = 0
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
end

function picking(enemies)
    --randomly update state
    if game_state != "game" then
        return
    end
    -- local curr_enemy = rnd(enemies)
    -- make sure they're idle first
    if t % current_wave.attack_freq == 0 then
        local chosen = flr(rnd(min(8, #enemies)))
        chosen = #enemies - chosen
        curr_enemy = enemies[chosen]
        if curr_enemy and curr_enemy.state == 0 then
            curr_enemy.state = 2
        end
    end
end

function spawn_enemy(x, y, en_type, en_wait)
    -- spawn enemy at random x position at top of screen
    -- x = flr(rnd(120))
    -- y = -8
    local enemy = make_actor(x, y, 3, 8, 8, 8, 8, 3, 1, 2, 0, 1, 1, 0, 1)
    enemy.state = 1
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
    elseif en_type == 2 then
        --deberry
        enemy.spr=18
        enemy.hp=2
        enemy.follows = true
    elseif en_type == 3 then
        --rainbow
        enemy.spr=19
        enemy.perpendicular = true
    elseif en_type == 4 then
        --pretzel
        enemy.spr=20
    elseif en_type == 5 then
        --chocolate chip
        enemy.spr=21
        enemy.hit_h=16
        enemy.hit_w=16
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
                explode(enemy.x, enemy.y)
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
    picking(enemies)
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
        curr_wave.attack_freq = 45
    elseif wave  == 2 then
        curr_wave.attack_freq = 30
    elseif wave == 3 then
        curr_wave.attack_freq = 20
    elseif wave == 4 then
        curr_wave.attack_freq = 60
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
        {3,3,1,2,1,2,1,2,3,3},
        {3,3,2,1,2,1,2,1,3,3},
        {3,3,1,2,1,2,1,2,3,3}
    },
    {
        {1,2,1,2,1,2,1,2,1,2},
        {2,1,2,1,2,1,2,1,2,1}
    },
    {
        {5}
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
    end
end
--some code for wave management

--win!
function win_game()
    if wave >= 5 then
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
        t = (t + 1) % 10000
        --update moves first
        move_player(player)
        update_bullet(bullet_table)
        update_enemies(enemies)

        --check collision
        near_miss(player, enemies)
        player_update_hp(player, enemies)
        enemy_update_hp(enemies, bullet_table)

        --update particles
        update_explode(particles)
        --condition to end the wave
        if game_state == "game" and #enemies == 0 then
            start_wave()
        end

        if #particles == 0 then
            win_game()
        end
    elseif game_state == "wave_text" then
        --track current
        -- wave text logic
        if wave_time == 0 then
            game_state = "game"
            wave_time = 60
            t = 0
        end
        wave_time -= 1
        move_player(player)
        update_bullet(bullet_table)
        update_explode(particles)
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
        print("SHMUP BASIC", 32, 50, 7)
        print("press z to start", 24, 60, 7)
    elseif game_state == "game_over" then
        --play some cutscene first
        print("game over", 48, 50, 7)
        print("press z to restart", 24, 60, 7)
    elseif game_state == "win" then
        print("you win!", 48, 50, 7)
        print("press z to restart", 24, 60, 7)
    else
        -- debug -------------------------
        -- print(#enemies, 120, 2, 7)
        if #enemies > 0 then
            print(enemies[1].x..','..enemies[1].y, 100, 10, 7)
            print(enemies[1].pos_y, 100, 10, 7)
        end
        print("state: " .. player.state, 90, 18, 7)
        print("bomb: " .. abs(player.bomb_progress - 1), 90, 26, 7)
        if #bullet_table > 0 then
            print('x,'..bullet_table[1].x, 2, 24, 7)
        end
        print(player.x..","..player.y, 2, 16, 7)
        if #bullet_table > 0 then
            local x = flr(bullet_table[1].x + bullet_table[1].w / 2 - 1)
            local y = bullet_table[1].y
            print("bullet:"..x..","..y, 2, 32, 7)
        end
        print("game_state: " .. game_state, 2, 40, 7)
        print("t: " .. t, 2, 90, 7)
        ----------------------------------------------------
        --actors
        draw_bullet(bullet_table)
        draw_enemies(enemies)
        draw_player(player)
        draw_explode(particles)
        --ui
        draw_bomb_progress(player)
        draw_player_hp(player)

        --text to display wave_number
        if game_state == "wave_text"  and wave < 5 then
            print("wave "..wave, 54, 60, ({7,7,7,6,6,6})[(player_t%6+1)])
        end
        

    end
end

function new_game()
    -- reset player
    player = make_actor(60, 90, 2, 8, 8, 2, 2, 4, 1, 1, 0, 1, 1)
    player.current_hp = player.hp
    player.invincible_t = 30
    player.bullet_cooldown = 0
    player.bomb_progress = 0
    -- reset enemies
    enemies = {}
    -- reset bullets
    bullet_table = {}
    --reset particles
    particles = {}
    -- reset wave
    wave = 1
    -- reset time
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

    for i=1, 100 do
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
00000000eeeceeee9aaaaaaa49e9c999944994490099999994999900000999999999900000000000000000000000000000000000000000000000000000000000
0000000084e4e4beaaa8eaaa99e99b99900990090999999994499990009999999499990000000000000000000000000000000000000000000000000000000000
000000000f4f4f40aaa88aaa99988999909449090999949999999990099999999449999000000000000000000000000000000000000000000000000000000000
000000000ffffff0aaaaaaaa99c97799494004949999444999999999099994999999999000000000000000000000000000000000000000000000000000000000
000000000ffffff00aaaaaa009999990049999409999944999999999999944499999999900000000000000000000000000000000000000000000000000000000
0000000000ffff0000aaaa0000999900004444009999999999944999999994499999999900000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000009999999999994999999999999994499900000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000001994499999999999999999999999499900000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000999999449999990199449999999999900000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000199999449949990099999944999999000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000019999999999900019999944994999000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000001199999999000001999999999990000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000099999900000000119999999900000000000000000000000000000000000000000000000000000000000
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
