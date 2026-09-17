pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--words of the wise
--
--if it aint broke 
--dont fix it
--

x = 60 
y = 60 
enemies = {} 
spawn_timer = 0 

copies = {} 
--scores
ones = 5
tens = 5
hund = 5
thou = 5

score = 0
hscore = 0

hones = 5
htens = 5
hhund = 5
hthou = 5


function _init() 
 cls(1) 
 map() 
 
 
 for i = 0, 120, 8 do
  add(copies, {x = i, y = -10})   -- top wall
  add(copies, {x = i, y = 130}) -- bottom wall
  add(copies, {x = -10, y = i})   -- left wall
  add(copies, {x = 130, y = i}) -- right wall
 end
end 


function hit_sprite4(px, py)
 
 for c in all(copies) do
  if (px < c.x + 8 and px + 8 > c.x and py < c.y + 8 and py + 8 > c.y) return true
 end
 return false
end

function _update() 
 
 if (btn(0) and not hit_sprite4(x - 4, y)) x -= 4 -- left
 if (btn(1) and not hit_sprite4(x + 4, y)) x += 4 -- right
 if (btn(2) and not hit_sprite4(x, y - 4)) y -= 4 -- up
 if (btn(3) and not hit_sprite4(x, y + 4)) y += 4 -- down

 
 spawn_timer += 1 
 if spawn_timer >= 2 then 
 
  add(enemies, {ex = 135, ey = 0 + flr(rnd(120))}) 
  spawn_timer = 0 
 end 

 
 for e in all(enemies) do 
  e.ex -= 3 
  if (e.ex < -5) del(enemies, e) -- delete when touching left wall
 end 
end 

function _draw() 
 local hit = false 

 
 for e in all(enemies) do 
  if (x < e.ex + 8 and x + 8 > e.ex and y < e.ey + 8 and y + 8 > e.ey) then 
   hit = true 
  end 
 end 

 if hit then 
  cls(8) 
  print("collision!", 16, 16, 7) -- shifted inside border view
	 score = tostr(thou-5)..tostr(hund-5)..tostr(tens-5)..tostr(ones-5)

		if(tonum(score)>tonum(hscore+5))then
 		hscore = score 
 		hones = ones
 		htens = tens
 		hhund = hund
 		hthou = thou
 			
		end
		
		ones = 5
		tens = 5
		hund = 5
		thou = 5
		
	
 else 
  cls(1) 
 end 
	
 
 spr(1, x, y) 
 
 for c in all(copies) do spr(4, c.x, c.y) end 
 for e in all(enemies) do spr(2, e.ex, e.ey) end 
 --score
 --
 --
 
 
 ones = ones + 1
 if(ones==15)then
 	ones = 5
 	tens = tens + 1
	end
	if(tens==15)then
 	tens = 5
 	hund = hund + 1
 end
 if(hund==15)then
 	hund = 5
 	thou = thou + 1
 	if(thou==15)then
 		thou=5
 	end
	end
 spr(thou,96,0)
 spr(hund,104,0)
 spr(tens,112,0)
 spr(ones,120,0)
 if(tonum(hscore)>1)then
 	spr(hthou,96,8)
 	spr(hhund,104,8)
 	spr(htens,112,8)
 	spr(hones,120,8)
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
--mentions--
--nicefella445 for art 
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
00000000cccccccc0000000033333333000004640000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66600000cccccccc00aaaa4433333333000055440777770000007000077777700777777007000700077777000777000007777770007777000777770000000000
06700700cccccccc0aa55a9433333333000004470700070000007000000000700000007007000700070000000700000000000070070000700700070000000000
66077000cc7ccccc6a587a9933333333000055640700070000007000007777700007777007000700077770000777700000077770077777700777770000000000
66077000cccccccc7aaaaa9933333333000004440700070000007000007000000000007007777700000070000700700000000070070000700000070000000000
00700700ccccc6cc07aaaa9933333333000055460700070000007000007000000000007000000700070070000700700000000070070000700000070000000000
00000000cccccccc0076aa9933333333000004740777770000007000007777700777777000000700077770000777700000000070007777000000070000000000
00000000cccccccc0000000033333333000055440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
