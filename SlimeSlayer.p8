pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--levels
function get_level_matrix(id)

--. = nothing
--1 = wall
--2 = green slime
--3 = breakable wall
--4 = next level portal
--5 = blue slime
--6 = player select spawn

  local levels = {
    {
      "....6...",
      "........",
      "........",
      "........",
      "........",
      "........",
      "........",
      "....4..."
    },{
      "...161..",
      "...1.1..",
      "...1.1..",
      "...1.1..",
      "1111.1..",
      "4....1..",
      "111111..",
      "........"
    },{
      "...161..",
      ".111.1..",
      ".....1..",
      "..1311..",
      "..1.1...",
      "..141...",
      "..111...",
      "........"
    },{
      "....6...",
      "........",
      "........",
      "22225222",
      "........",
      "........",
      "........",
      "....4..."
    },{
      "11111111",
      "161..5.1",
      "1.1.11.1",
      "1...12.1",
      "121131.1",
      "1.21...1",
      "113...41",
      "11111111"
    },
    {
      "11111111",
      "16.1.5.1",
      "13.3.1.1",
      "11.13121",
      "12.....1",
      "11131131",
      "15..2341",
      "11111111"
    },{
      "23.363.3",
      "3.3.3.3.",
      ".3.3.3.3",
      "3.3.3.3.",
      "33333333",
      "........",
      "........",
      "....4..."
    },{
      "..1..2..",
      "2.11.111",
      ".4.1....",
      "...1..1.",
      ".1112216",
      "......1.",
      "1111.11.",
      "2......."
    },{
      ".4.1..6.",
      "...1....",
      "...1....",
      "...1.22.",
      "...1.22.",
      "...1....",
      "...1....",
      "........"
    },{
      "....6...",
      "........",
      "........",
      "11113111",
      "22222222",
      "22222222",
      "........",
      "....4..."
    }
  }
  
  if id < 1 or id > #levels then return nil end
  return levels[id]
end

-->8
--init
function _init()
  level = 1
  game_started = false
  game_completed = false
  start_time = t()
  end_time = 0
  load_level()
end

function load_level()
  local str_map = get_level_matrix(level)
  if str_map == nil then
    if not game_completed then
      end_time = t() - start_time
      game_completed = true
    end
    return
  end
  world_map = {}
  map_size = #str_map
  grid_size = 16
  bullets = {}
  enemies = {}
  hit_effects = {}
  shoot_timer, cooldown = 0, 0
  portal_x, portal_y, portal_active = 0, 0, false
  px, py, pa = 24, 24, 0
  fov, hp = 0.16, 100
  for y=1, map_size do
    world_map[y] = {}
    local row_str = str_map[y]
    for x=1, map_size do
      local char = sub(row_str, x, x)
      if char == "1" then
        world_map[y][x] = 1
      elseif char == "3" then
        world_map[y][x] = 6
      elseif char == "4" then
        world_map[y][x] = 4
        portal_x, portal_y = x, y
      elseif char == "2" then
        world_map[y][x] = 0
        add(enemies, {ex=(x-0.5)*grid_size, ey=(y-0.5)*grid_size, hp=1, type=2, is_attacking=false, has_seen_player=false})
      elseif char == "5" then
        world_map[y][x] = 0
        add(enemies, {ex=(x-0.5)*grid_size, ey=(y-0.5)*grid_size, hp=2, type=5, is_attacking=false, has_seen_player=false})
      elseif char == "6" then
        world_map[y][x] = 0
        px = (x - 1) * grid_size + 8
        py = (y - 1) * grid_size + 8
      else
        world_map[y][x] = 0
      end
    end
  end
end

function _update()
  if not game_started then
    if btnp(4) then
      game_started = true
      start_time = t()
    end
    return
  end
  if game_completed then
    if btnp(4) then
      _init()
    end
    return
  end
  if hp <= 0 then
    if btnp(4) then
      _init()
    end
    return
  end
  if #enemies == 0 and not portal_active then
    portal_active = true
  end
  if portal_active then
    local p_target_x = (portal_x - 0.5) * grid_size
    local p_target_y = (portal_y - 0.5) * grid_size
    local dist_to_portal = sqrt((px - p_target_x)^2 + (py - p_target_y)^2)
    if dist_to_portal < 10 then
      level += 1
      load_level()
      return
    end
  end
  if btn(0) then pa -= 0.0125 end
  if btn(1) then pa += 0.0125 end
  local dx, dy = cos(pa) * 1.2, sin(pa) * 1.2
  if btn(2) then
    local t1 = get_tile(px + dx * 4, py)
    local t2 = get_tile(px, py + dy * 4)
    if t1 == 0 or (t1 == 4 and portal_active) then px += dx end
    if t2 == 0 or (t2 == 4 and portal_active) then py += dy end
  end
  if btn(3) then
    local t1 = get_tile(px - dx * 4, py)
    local t2 = get_tile(px, py - dy * 4)
    if t1 == 0 or (t1 == 4 and portal_active) then px -= dx end
    if t2 == 0 or (t2 == 4 and portal_active) then py -= dy end
  end
  if shoot_timer > 0 then shoot_timer -= 1 end
  if cooldown > 0 then cooldown -= 1 end
  if btnp(4) and cooldown == 0 then
    shoot_timer, cooldown = 5, 14
    add(bullets, {bx=px, by=py, bdx=cos(pa)*1.8, bdy=sin(pa)*1.8, life=50})
  end
  for h in all(hit_effects) do
    h.life -= 1
    if h.life <= 0 then del(hit_effects, h) end
  end
  for b in all(bullets) do
    b.bx += b.bdx
    b.by += b.bdy
    b.life -= 1
    local hit_something = false
    for e in all(enemies) do
      local dist_to_enemy = sqrt((b.bx - e.ex)^2 + (b.by - e.ey)^2)
      if dist_to_enemy < 10 then
        e.hp -= 1
        add(hit_effects, { hx = b.bx, hy = b.by, life = 25 })
        del(bullets, b)
        if e.hp <= 0 then del(enemies, e) end
        hit_something = true
        break
      end
    end
    if not hit_something then
      local tx = flr(b.bx / grid_size) + 1
      local ty = flr(b.by / grid_size) + 1
      if tx >= 1 and tx <= map_size and ty >= 1 and ty <= map_size then
        local wall_state = world_map[ty][tx]
        if wall_state == 6 then
          world_map[ty][tx] = 7
          add(hit_effects, { hx = b.bx, hy = b.by, life = 25 })
          del(bullets, b)
          hit_something = true
        elseif wall_state == 7 then
          world_map[ty][tx] = 0
          add(hit_effects, { hx = b.bx, hy = b.by, life = 25 })
          del(bullets, b)
          hit_something = true
        elseif wall_state == 1 or b.life <= 0 then
          del(bullets, b)
          hit_something = true
        end
      end
    end
  end
  for e in all(enemies) do
    local dist = sqrt((px - e.ex)^2 + (py - e.ey)^2)
    if not e.has_seen_player then
      local los_ang = atan2(px - e.ex, py - e.ey)
      local sx, sy = e.ex, e.ey
      local step_x, step_y = cos(los_ang), sin(los_ang)
      local clear_path, check_dist = true, 0
      while check_dist < dist do
        sx += step_x
        sy += step_y
        check_dist += 1
        if get_tile(sx, sy) == 1 or get_tile(sx, sy) == 6 or get_tile(sx, sy) == 7 then
          clear_path = false
          break
        end
      end
      if clear_path and dist < 90 then e.has_seen_player = true end
    end
    if e.has_seen_player and dist > 14 then
      local speed = (e.type == 5) and 0.35 or 0.4
      local move_ang = atan2(px - e.ex, py - e.ey)
      local nex = e.ex + cos(move_ang) * speed
      local ney = e.ey + sin(move_ang) * speed
      if get_tile(nex, e.ey) == 0 then e.ex = nex end
      if get_tile(e.ex, ney) == 0 then e.ey = ney end
    end
    if dist < 20 then
      e.is_attacking = true
      hp -= (e.type == 5 and 0.5 or 0.3)
    else
      e.is_attacking = false
    end
  end
end

function get_tile(mx, my)
  local tx = flr(mx / grid_size) + 1
  local ty = flr(my / grid_size) + 1
  if tx < 1 or tx > map_size or ty < 1 or ty > map_size then return 1 end
  return world_map[ty][tx]
end

-->8
--draw
function _draw()
  cls(0)
  
  if not game_started then
    rectfill(0, 0, 127, 127, 0)
    
    local title_pulse = 1
    local cycle = flr(t() * 4) % 3
    if cycle == 1 then title_pulse = 13
    elseif cycle == 2 then title_pulse = 12 end
    
    print("slime slayer", 40, 24, title_pulse)
    
    spr(1,30,25,8,8)
    
    if (t() * 1.5) % 2 < 1 then
      print("press z to start", 32, 94, 5)
    end
    return
  end

  if game_completed then
    rectfill(0, 0, 127, 127, 3)
    print("victory!", 48, 35, 11)
    local total_sec = flr(end_time)
    print("completed in:", 38, 55, 7)
    print(total_sec.." seconds", 44, 67, 10)
    print("press z to restart", 28, 95, 6)
    return
  end

  rectfill(0, 0, 127, 63, 12)
  rectfill(0, 64, 127, 127, 5)

  for screen_x = 0, 127 do
    local ray_angle = pa + (screen_x / 127 - 0.5) * fov
    local distance, hit_wall = 0, false
    local rx, ry = px, py
    local step_x, step_y = cos(ray_angle), sin(ray_angle)
    local wall_type = 1

    while not hit_wall and distance < 150 do
      rx += step_x
      ry += step_y
      distance += 1
      local check_tile = get_tile(rx, ry)
      if check_tile == 1 or check_tile == 4 or check_tile == 6 or check_tile == 7 then 
        hit_wall = true 
        wall_type = check_tile
      end
    end

    local corrected_dist = distance * cos(ray_angle - pa)
    local wall_height = mid(0, 127, (grid_size * 80) / corrected_dist)
    local wall_top = 64 - wall_height / 2
    local wall_bottom = 64 + wall_height / 2
    if wall_type == 7 then wall_top = 64 end

    local col = 7
    if wall_type == 4 then
      if portal_active then col = (t() * 12) % 2 < 1 and 14 or 8
      else col = 2 end
    elseif wall_type == 6 or wall_type == 7 then
      col = 4
    else
      if corrected_dist > 80 then col = 1
      elseif corrected_dist > 50 then col = 13
      elseif corrected_dist > 30 then col = 6 end
    end

    line(screen_x, wall_top, screen_x, wall_bottom, col)

    local visible_slimes = {}
    for e in all(enemies) do
      local angle_to_slime = atan2(e.ex - px, e.ey - py) - ray_angle
      if angle_to_slime < -0.5 then angle_to_slime += 1 end
      if angle_to_slime > 0.5 then angle_to_slime -= 1 end

      local e_dist = sqrt((e.ex - px)^2 + (e.ey - py)^2)
      if e_dist < distance and e_dist > 5 and cos(atan2(e.ex - px, e.ey - py) - pa) > 0 then
        local scale_mod = e.is_attacking and 80 or 60
        local slime_size = mid(2, 36, (grid_size * scale_mod) / e_dist)
        local slime_ang_width = slime_size * 0.00063

        if abs(angle_to_slime) < slime_ang_width then
          add(visible_slimes, {dist = e_dist, size = slime_size, ang_w = slime_ang_width, ang = angle_to_slime, type = e.type, is_attacking = e.is_attacking})
        end
      end
    end

    for i = 1, #visible_slimes - 1 do
      for j = i + 1, #visible_slimes do
        if visible_slimes[i].dist < visible_slimes[j].dist then
          local temp = visible_slimes[i]
          visible_slimes[i] = visible_slimes[j]
          visible_slimes[j] = temp
        end
      end
    end

    for s in all(visible_slimes) do
      local e_bottom = 64 + (grid_size * 80) / s.dist / 2
      local e_top = e_bottom - s.size
      
      local slime_col = 11
      if s.type == 5 then slime_col = s.is_attacking and 13 or 12 end
      line(screen_x, e_top, screen_x, e_bottom, slime_col)

      local rel_x = s.ang / s.ang_w
      if abs(rel_x - 0.35) < 0.12 or abs(rel_x + 0.35) < 0.12 then
        if s.size > 4 then
          local eye_y = (s.type == 5) and 0.35 or 0.25
          rectfill(screen_x, e_top + s.size * eye_y, screen_x, e_top + s.size * (eye_y + 0.15), 0)
        end
      end
    end

    for b in all(bullets) do
      local angle_to_bullet = atan2(b.bx - px, b.by - py) - ray_angle
      if angle_to_bullet < -0.5 then angle_to_bullet += 1 end
      if angle_to_bullet > 0.5 then angle_to_bullet -= 1 end

      if abs(angle_to_bullet) < 0.004 then
        local b_dist = sqrt((b.bx - px)^2 + (b.by - py)^2)
        if b_dist < corrected_dist and b_dist > 2 then
          local out_size = mid(2, 18, 110 / b_dist)
          local inn_size = mid(1, 10, 55 / b_dist)
          local floor_y = 64 + mid(0, 50, 220 / b_dist)
          rectfill(screen_x - out_size/2, floor_y, screen_x + out_size/2, floor_y + (out_size/4), 9)
          if inn_size >= 1 then
            rectfill(screen_x - inn_size/2, floor_y + 1, screen_x + inn_size/2, floor_y + 1 + (inn_size/4), 7)
          end
        end
      end
    end
  end

  for h in all(hit_effects) do
    local angle_to_hit = atan2(h.hx - px, h.hy - py) - pa
    if angle_to_hit < -0.5 then angle_to_hit += 1 end
    if angle_to_hit > 0.5 then angle_to_hit -= 1 end

    local sx = flr(127 * (angle_to_hit / fov + 0.5))
    if sx > -20 and sx < 148 and cos(angle_to_hit) > 0 then
      local h_dist = sqrt((h.hx - px)^2 + (h.hy - py)^2)
      local sy = 64 - mid(0, 40, 100 / h_dist)
      print("hit", sx - 6, sy, 8)
    end
  end

  if hp > 0 then
    rectfill(63, 62, 64, 65, 7)
    rectfill(4, 118, 54, 124, 0)
    rectfill(5, 119, 5 + flr(hp * 0.48), 123, 8)
    print("hp:"..flr(hp), 6, 111, 7)
    print("lvl:"..level, 6, 4, 7)
    if portal_active then print("portal open!", 76, 4, 14)
    else print("enemies left:"..#enemies, 68, 4, 11) end
    
    local bob = flr(sin(t() * 2) * 1.5)
    local wy = 98 + bob + (shoot_timer > 0 and 8 or 0)
    
    line(63, wy, 58, 127, 4)
    line(64, wy, 59, 127, 4)
    line(65, wy, 60, 127, 15)
    rectfill(62, wy - 3, 66, wy, 5)
    
    if shoot_timer > 0 then
      circfill(64, wy - 7, 6, 7)
      circfill(64, wy - 7, 3, 9)
    else
      local crystal_col = (t() * 4) % 2 < 1 and 14 or 12
      circfill(64, wy - 6, 3, crystal_col)
      pset(64, wy - 6, 7)
    end
  else
    rectfill(0, 0, 127, 127, 0)
    print("game over", 44, 54, 8)
    print("press z to restart progress", 12, 66, 7)
  end
end

-->8
--credits
--------------------------------
--lead dev--
--thanbanan
--
--------------------------------
--lead artist--
--thanbanan
--
--------------------------------
--add your contributions here
--if edited ⬇️⬇️⬇️⬇️⬇️⬇️⬇️⬇️
--------------------------------
--
--
--
--
--
--
--
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000000b00000bbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000bbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700033bbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000b33bbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000bbb33bbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000bbbb33bbbbbbbbb33b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbb3bbbbbb333bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbb3bb33333bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbb3333bbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbbb3bbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbbb3bbbbbb0bbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbbb3bbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbbb3bb0bbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbbb3bbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbbb3bbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbbb3bbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbbb3bbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbbb3bbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbbb3bbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000bbbbbbb33bbbbbbbbbb60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666bbbbbbbbbbbbbbb660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666666bbbbbbbbb666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000066766666666666676666000000000000000000ccccc00000000000000000000000000000000000000000000000000000000000000000000000000000
0000000066666676676666666666000000000000000000c7ccc00000000000000000000000000000000000000000000000000000000000000000000000000000
0000000006666666666666666660000000000000000000ccccc00000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000666666666660000000000000000000000ccccc00000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000004c77c00000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000444ccc00000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000444440000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000444400000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000004454000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000004444000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000066666666644446000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000006666666666666444446666660000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000666666666666666444466666666600000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000666666666666666664444666666666666600000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000006666666666666666664444666666666666660000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000666666666666666777744447776666666666666600000000000000000000000000000000000000000000000000000000000000000000
00000000000000000006666666666667777777444447777777666666666660000000000000000000000000000000000000000000000000000000000000000000
00000000000000000006666666666777777774445477777777776666666660000000000000000000000000000000000000000000000000000000000000000000
00000000000000000066666666667777777744444777777777777666666666000000000000000000000000000000000000000000000000000000000000000000
00000000000000000666666666677777777744454777777777777766666666600000000000000000000000000000000000000000000000000000000000000000
00000000000000000666666666677777777744547777777777777766666666600000000000000000000000000000000000000000000000000000000000000000
00000000000000000666666666677777777777777777777777777766666666600000000000000000000000000000000000000000000000000000000000000000
00000000000000000666666666677777777777777777777777777766666666600000000000000000000000000000000000000000000000000000000000000000
00000000000000000666666666667777777777777777777777777666666666600000000000000000000000000000000000000000000000000000000000000000
00000000000000000066666666666777777777777777777777776666666666000000000000000000000000000000000000000000000000000000000000000000
00000000000000000006666666666667777777777777777777666666666660000000000000000000000000000000000000000000000000000000000000000000
00000000000000000006666666666666666777777777776666666666666660000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000666666666666666666666666666666666666666600000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000006666666666666666666666666666666666660000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000666666666666666666666666666666666600000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000666666666666666666666666666600000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000006666666666666666666666660000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000066666666666666000000000000000000000000000000000000000000000000000000000000000000000000000000000
