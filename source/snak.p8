pico-8 cartridge // http://www.pico-8.com
version 35
__lua__
--snak v1.7
--by megabyte112


--[[
i don't even have amy
idea what's going on in here.
i'm pretending like i know
what i'm doing. this has taken
well over 100 hours to create
and debug at this point.
]]--

splash="🅾️ / z:  start"
name=""
version="v1.7"
title = true
advance=false
score = 0
pos={10,20}
startpos={10,20}
direction="up"
startdirection="up"
body={}
startbody={}
food={10,10}
bg=5
fg=0
frame=0
canmove=true
expanding=false
queue=nil
dead=false
phase=0
changephase=false
fontcol=7
beat=false
beatfast=false
beatcount=0
--flash, cycle, flashfast
bgeffect=nil
--flash, star, flashfast, circle
fgeffect=nil
bgflashcol=11
fgflashcol=5
stars={}
starspr=0
circlecol=7
radius=3
wait=0
mobile=true
lastnote=0
autostar=true
lastcol=false
grace=false
lastdir="up"
directionchange=false
graceused=false
rgbsprites=false
endgame=false
debug=false
endless=false
savedphase=nil
drawtitle=true
noeffects=false
sprint=0
sprinttime=0
startsprinttime=0
sprinting=false
framessincenote=0
hinttext=""
cansave=true

function _init()
	--allows mouse/kb
	poke(0x5f2d,1)
	
	music(63, 0, 15)
end

function _update()
	if wait>0 then
		wait-=1
		return
	end
	if prepareload then
		prepareload=false
		loadstage(phase)
		return
	end
	frame+=1
	framessincenote+=1
	directionchange=lastdir!=direction
	lastdir=direction
	if directionchange then
		grace=false
		graceused=true
	end
	--music
	lastbeat=beat
	beat=(stat(50)%8)==0
	beatfast=(stat(50)%2)==0
	effects()
	if note~=lastnote then
		framessincenote=0
	end
	if beat and not lastbeat then beatcount+=1 end
	--title screen
	if title and not (changephase or endgame) then
		if issavegame() then
			name="🅾️ / z:  continue ("..savedphase..")"
			splash="❎ / x:  start new game"
		end
		if (btn(🅾️) and not issavegame()) or (issavegame() and btn(❎)) then
			music(-1)
			sfx(19)
			deletedata()
			title=false
			drawtitle=false
			advance=true
			bg=5
			version=""
			wait=25
			prepareload=true
		elseif issavegame() and btn(🅾️) then
			music(-1)
			sfx(19)
			loadgame()
			title=false
			drawtitle=false
			advance=true
			version=""
			spawnfood()
			score=phase*50
			wait=40
			prepareload=true
		end
		return
	end
	if endgame then
		if btnp(🅾️) and (stat(50)==-1 or debug) then
			expanding=false
			endless=true
			advance=true
			score=0
			spawnfood()
			pos={10,20}
			startpos={10,20}
			direction="up"
			startdirection="up"
			body={}
			startbody={}
			bg=5
			fg=0
			title=false
			endgame=false
			rgbsprites=true
			phase=4
			music(-1)
			sfx(19)
			wait=40
			prepareload=true
			version=""
			music(50,0,15)
		end
		return
	end
	--after death
	if dead then
		if #body>#startbody then
			deli(body,#body)
			return
		elseif #body==#startbody then
			prepareload=true
			wait=30
			return
		end
	end
	--phase change
	if changephase then
		if phase==0 and isending() and stat(50)>16 then music(-1) end
		if phase==2 and isending() and stat(50)>3 then music(-1) end
		for i=1,#body do
			startbody[i]=body[i]
		end
		startpos[1]=pos[1]
		startpos[2]=pos[2]
		startdirection=direction
		startsprinttime=sprinttime
		title = true
		version="game saved!"
		if not cansave then
			version="debug: save disabled"
		end
		name="stage "..phase+1 .." complete!"
		splash="🅾️ / z: begin stage "..phase+2
		if btnp(🅾️) and (isending() or stat(50)==-1 or debug) and phase<3 then
			phase+=1
			music(-1)
			sfx(19)
			wait=40
			prepareload=true
			version=""
			return
		end
	end
	
	
	--[[
	debug mode:
	enable using the <end> key,
	disable with <home> key.
	
	allows noclipping, infinite
	sprint, food consumption (❎),
	and advanced info.
	
	the game cannot be saved once
	debug mode has been activated.
	the cartridge must be reset.
	]]--
	if stat(28,77) then
		debug=true
		cansave=false
	elseif stat(28,74) then
		debug=false
	end
	--sprint timer
	if (advance and btn(🅾️) and sprinttime>0) then
		sprinting=true
		if sprinttime>0 then
			sprinttime-=1
		else
			sprinting=false
		end
		sprint=ceil(sprinttime/60)
	else
		sprinting=false
		sprint=ceil(sprinttime/60)
	end
	if debug and btn(🅾️) then
		sprinting=true
	end
	--timing
	if not sprinting then
		if phase==0 and stat(50)!=lastnote and not endless then
			mobile=true
		elseif phase>0 and stat(50)%2==0 and stat(50)!=lastnote then
			mobile=true
		else
			mobile=false
		end
	else
		if phase==0 and stat(50)~=lastnote and not endless or framessincenote==4 then
			mobile=true
		elseif phase>0 and stat(50)!=lastnote then
			mobile=true
		else
			mobile=false
		end
	end
	if graceused and mobile then graceused=false end
	for i=1,#body do
		if body[i][1]==food[1] and body[i][2]==food[2] then
			spawnfood()
		end
	end
	--direction input
	if canmove then
		if btnp(⬅️) and direction!= "right" then
			direction="left"
			canmove=false
			if willcollide() then
				direction=lastdir
			end
		elseif btnp(➡️) and direction != "left" then
			direction="right"
			canmove=false
			if willcollide() then
				direction=lastdir
			end
		elseif btnp(⬇️) and direction!= "up" then
			direction="down"
			canmove=false
			if willcollide() then
				direction=lastdir
			end
		elseif btnp(⬆️) and direction != "down" then
			direction="up"
			canmove=false
			if willcollide() then
				direction=lastdir
			end
		elseif queue!=nil then
			if queue==⬆️ and direction != "down" then
				direction="up"
				canmove=false
				if willcollide() then
					direction=lastdir
				end
			elseif queue==⬇️ and direction != "up" then
				direction="down"
				canmove=false
				queue=nil
				if willcollide() then
					direction=lastdir
				end
			elseif queue==⬅️ and direction != "right" then
				direction="left"
				canmove=false
				queue=nil
				if willcollide() then
					direction=lastdir
				end
			elseif queue==➡️ and direction != "left" then
				direction="right"
				canmove=false
				queue=nil
				if willcollide() then
					direction=lastdir
				end
			end
		end
		queue=nil
	elseif not canmove and queue == nil then
		if btnp(⬅️) then
			queue = ⬅️
		elseif btnp(➡️) then
			queue = ➡️
		elseif btnp(⬆️) then
			queue = ⬆️
		elseif btnp(⬇️) then
			queue = ⬇️
		end
	end
	if mobile and beatfast and bgeffect=="cycle" then
		bg=(frame%15)+1
	end
	--movement
	if mobile and advance and not grace then
		canmove=true
		add(body,{pos[1],pos[2]},1)
		if not expanding then
			deli(body,#body)
		else
			expanding=false
		end
		if direction=="up" then
			pos[2]-=1
		elseif direction=="down" then
			pos[2]+=1
		elseif direction=="left" then
			pos[1]-=1
		else
			pos[1]+=1
		end
	elseif grace and mobile then
		grace=false
		graceused=true
	end
	--eat food
	if (pos[1]==food[1] and pos[2]==food[2]) or (debug and btn(❎) and mobile and advance) then
		score+=1
		expanding=true
		spawnfood()
		updatemus()
		if sprinttime<840 then
			sprinttime+=60
		end
	end
	--death
	if willcollide() and not graceused and mobile then
		grace=true
	end
	if collision() and not dead and not grace then
		dead=true
		advance=false
		wait=30
		music(-1, 2000)
	end
	if autostar and beat and not lastbeat then
		updatestars()
	end
	if bg==7 or bg==10 then
		fontcol=0
	else
		fontcol=7
	end
	lastnote=stat(50)
	lastcol=collision()
end

function _draw()
	if wait>0 and not dead then return end
	if title or endgame then
		cls(0)
		if drawtitle then
			sspr(0,32,64,24,33,30)
		end
		if stat(54)>=48 or stat(50)==-1 or changephase then
			print(name,hcenter(name),56, 6)
		end
		if isending() or stat(54)>=47 or stat(50)==-1 then
			print(splash,hcenter(splash),68, 6)
		end
		print(version,hcenter(version),110,5)
		return
	end
	if dead then
		cls(0)
		for i=1,#body do
			spr(4,body[i][1]*4,body[i][2]*4,0.5,0.5)
		end
		spr(4,pos[1]*4,pos[2]*4,0.5,0.5)
		deadtext="game over! score:"..score
		print(deadtext, hcenter(deadtext), 1, 7)
		return
	end
	cls(bg)
	if beat  and bgeffect=="flash" then cls(bgflashcol) end
	if beatfast  and bgeffect=="flashfast" then cls(bgflashcol) end
	rectfill(4, 8, 123, 123, fg)
	rect(3, 7, 124, 124, 7)
	print(hinttext,hcenter(hinttext),80,5)
	if beat  and fgeffect=="flash" then rectfill(4, 8, 123, 123, fgflashcol) end
	if beatfast  and fgeffect=="flashfast" then rectfill(4, 8, 123, 123, fgflashcol) end
	if fgeffect=="star" then
		if mobile then
			if starspr==0 then
				starspr=16
			else
				starspr=0
			end
		end
		for i=1,#stars do
			spr(starspr,stars[i][1]*4,stars[i][2]*4,0.5,0.5)
		end
	end
	if fgeffect=="circle" then
		circ(31,35,radius,circlecol)
		circ(96,35,radius,circlecol)
		circ(31,96,radius,circlecol)
		circ(96,96,radius,circlecol)
	elseif fgeffect=="square" then
		rect(62-radius,65-radius,65+radius,66+radius,circlecol)
	end
	if not rgbsprites then
		spr(3+(phase*16),food[1]*4,food[2]*4,0.5,0.5)
	elseif rgbsprites then
		spr(40+(frame%8),food[1]*4,food[2]*4,0.5,0.5)
	end
	if not rgbsprites then
		for i=1,#body do
			spr(2+(phase*16),body[i][1]*4,body[i][2]*4,0.5,0.5)
		end
		spr(1+(phase*16),pos[1]*4,pos[2]*4,0.5,0.5)
	else
		for i=1,#body do
			spr(56+((frame+(body[i][1]*4)+(body[i][2]*4))%7),body[i][1]*4,body[i][2]*4,0.5,0.5)
			spr(36,body[i][1]*4,body[i][2]*4,0.5,0.5)
		end
		spr(56+((frame+(pos[1]*4)+(pos[2]*4))%7),pos[1]*4,pos[2]*4,0.5,0.5)
		if not sprinting then
			spr(20,pos[1]*4,pos[2]*4,0.5,0.5)
		end
	end
	if debug then
		print("m"..stat(0).."c"..stat(1).."s"..stat(2).."f"..stat(7).."l"..#body,1,1,7)
		print("saves disabled until reload",5,118,6)
		print("<home>: exit debug",5,112,6)
		print("❎ (hold): eat",5,106,6)
		print("🅾️: sprint",5,100,6)
	else
		print("length: "..score, 10, 1, 7)
		print("sprint:", 70, 1, 7)
		sspr(40,0,18,8,101,0)
		if sprint>0 then
			for i=1,sprint do
				spr(21,100+i,0)
			end
		end
	end
	if sprinting then
		for i=1,#body do
			spr(24+frame%7,body[i][1]*4,body[i][2]*4,0.5,0.5)
		end
		if not rgbsprites then
			spr(8+phase,pos[1]*4,pos[2]*4,0.5,0.5)
		end
	end
end
-->8
--food and helpers

function spawnfood()
	local pos1=flr(rnd(29))+1
	local pos2=flr(rnd(28))+2
	while pos1==pos[1] do
		pos1=flr(rnd(29))+1
	end
	while pos2==pos[2] do
		pos2=flr(rnd(28))+2
	end
	food[1]=pos1
	food[2]=pos2
	for i=1,#body do
		if food[1]==body[i][1] and food[2]==body[i][2] then
			spawnfood()
		end
	end
end

--string centering
function hcenter(s)
  return 64-#s*2
end

--rounding
function round(value)
	if value%1>=0.5 then
		return ceil(value)
	else
		return flr(value)
	end
end
-->8
--music

addresses={}

function changemus()
	--dynamic music:
	--find the memory address
	--containing music and
	--break the loop only once
	for i = 0x3101,0x31ff,4 do
		if (peek(i)|0b10000000)==peek(i) then
			poke(i,peek(i)&0b01111111)
			add(addresses, i)
			return
		end
	end
end

function updatemus()
	if endless then return end
	if score==1 then
		hinttext="that's snek."
		food[1]=20
		food[2]=10
	elseif score==2 then
		hinttext="<- this is snak."
		food[1]=5
		food[2]=20
	elseif score == 3 then
		hinttext="turn on sound."
		food[1]=19
		food[2]=16
		changemus()
	elseif score==4 then
		hinttext="don't crash into the wall."
		food[1]=30
		food[2]=2
	elseif score==5 then
		hinttext="or snek's tail."
		food[1]=3
		food[2]=4
	elseif score==6 then
		hinttext="🅾️ / z:  sprint"
		food[1]=28
		food[2]=24
	elseif score==7 then
		hinttext="have fun."
		food[1]=10
		food[2]=10
	elseif score==8 then
		hinttext=""
		changemus()
	elseif score == 20 then
		changemus()
	elseif score == 40 then
		changemus()
	elseif score == 50 then
		changemus()
		advance=false
		bg=0
		changephase=true
		savegame()
	elseif score == 53 then
		changemus()
	elseif score == 56 then
		changemus()
	elseif score == 60 then
		changemus()
	elseif score == 70 then
		changemus()
	elseif score == 85 then
		changemus()
	elseif score == 100 then
		changemus()
		advance=false
		bg=0
		fg=0
		changephase=true
		savegame()
	elseif score == 105 then
		changemus()
	elseif score == 115 then
		changemus()
	elseif score == 130 then
		changemus()
	elseif score == 140 then
		changemus()
	elseif score == 150 then
		changemus()
		advance=false
		bg=0
		fg=0
		changephase=true
		savegame()
	elseif score == 155 then
		changemus()
		music(-1)
		music(31, 0, 7)
	elseif score == 165 then
		changemus()
	elseif score == 175 then
		changemus()
	elseif score == 185 then
		changemus()
	elseif score == 198 then
		changemus()
	elseif score == 200 then
		changemus()
		endgame=true
		advance=false
		bg=0
		fg=0
		savegame()
	end
end

function musphase(stage)
	for i=1,#addresses do
		poke(addresses[i],peek(addresses[i])|0b10000000)
	end
	addresses={}
	if endless then
		music(50,0,15)
		return
	end
	if stage==0 then
		music(0, 0, 7)
	elseif stage==1 then
		for i=0,4 do
			changemus()
		end
		music(8, 0, 7)
	elseif stage==2 then
		for i=0,10 do
			changemus()
		end
		music(19, 0, 7)
	elseif stage==3 then
		for i=0,15 do
			changemus()
		end
		music(30, 0, 7)
	end
end

function isending()
	ends={0,7,18,29,46,47,48,49}
	for i=1,#ends do
		if ends[i]==stat(54) then
			return true
		end
	end
	return false
end
-->8
--collision

function collision()
	if debug then return false end
	--out of bounds
	if pos[1]<1 or pos[1]>30 then
		return true
	elseif pos[2]<2 or pos[2]>30 then
		return true
	end
	--collision with tail
	for i=1,#body do
		if body[i][1]==pos[1] and body[i][2]==pos[2] then
			return true
		end
	end
	return false
end

function willcollide()
	if debug then return false end
	if direction=="up" then
		if pos[2]==2 then return true end
		for i=1,#body-1 do
			if body[i][1]==pos[1] and body[i][2]==pos[2]-1 then
				return true
			end
		end
	elseif direction=="down" then
		if pos[2]==30 then return true end
		for i=1,#body-1 do
			if body[i][1]==pos[1] and body[i][2]==pos[2]+1 then
				return true
			end
		end
	elseif direction=="left" then
		if pos[1]==1 then return true end
		for i=1,#body-1 do
			if body[i][1]==pos[1]-1 and body[i][2]==pos[2] then
				return true
			end
		end
	elseif direction=="right" then
		if pos[1]==30 then return true end
		for i=1,#body-1 do
			if body[i][1]==pos[1]+1 and body[i][2]==pos[2] then
				return true
			end
		end
	end
	return false
end
-->8
--effects
function effects()
	if noeffects then return end
	note=stat(50)
	pattern=stat(54)
	n=note%8
	perc=stat(52)
	if pattern==1 then
		bgeffect="flash"
		bgflashcol=11
		if n==2 or n==6 then
			bg=6
		else
			bg=5
		end
	elseif pattern==2  or pattern==6 then
		bgeffect="flash"
		bgflashcol=11
		fgeffect="star"
		fg=0
		if n==2 or n==6 then
			bg=6
		else
			bg=5
		end
	elseif pattern==3 then
		bgeffect="flash"
		bgflashcol=11
		fgeffect="circle"
		circlecol=5
		if n==2 or n==6 then
			bg=6
		else
			bg=5
		end
		if n%4==0 then
			radius=5
		elseif n%4==1 then
			radius=8
		elseif n%4==2 then
			radius=11
		else
			radius=14
		end
	elseif pattern==4 then
		bgeffect="flash"
		bgflashcol=11
		fgeffect="circle"
		circlecol=5
		if n==2 or n==6 then
			bg=6
		else
			bg=5
		end
		if n%4==0 then
			radius=14
		elseif n%4==1 then
			radius=11
		elseif n%4==2 then
			radius=8
		else
			radius=5
		end
	elseif pattern==5 then
		bg=11
		fg=3
		circlecol=0
		if note==0 then
			radius=15
		elseif note==1 then
			radius=13
		elseif note==2 then
			radius=11
		elseif note==3 then
			radius=9
		elseif note==4 then
			radius=15
		elseif note==5 then
			radius=13
		elseif note==6 then
			radius=11
		elseif note==7 then
			radius=9
		elseif note==9 then
			radius=11
		elseif note==10 then
			radius=9
		elseif note==12 then
			radius=11
		elseif note==13 then
			radius=9
		elseif note==16 then
			radius=7
		elseif note==17 then
			radius=9
		elseif note==18 then
			radius=7
		elseif note==20 then
			radius=9
		elseif note==21 then
			radius=7
		elseif note==25 then
			radius=9
		elseif note==26 then
			radius=7
		elseif note==28 then
			radius=9
		elseif note==29 then
			radius=7
		end
	elseif pattern==8 then
		bg=12
		fg=1
	elseif pattern==9 then
		bgeffect=nil
		fg=0
		if note%8==4 or note==31 then
			bg=13
		else
			bg=12
		end
	elseif pattern==10 then
		if note%8==4 or note==31 then
			bg=12
		else
			bg=13
		end
		radius=2
	elseif pattern==11 then
		fgeffect="circle"
		circlecol=14
		if note%16==0 then
			bg=6
			fg=2
		elseif note%16==8 then
			bg=0
			fg=5
		elseif note%16==2 then
			radius=5
		elseif note%16==4 then
			radius=10
		elseif note%16==6 then
			radius=15
		elseif note%16==10 then
			radius=10
		elseif note%16==12 then
			radius=5
		elseif note%16==14 then
			radius=2
		end
	elseif pattern==12 then
		bg=0
		fg=0
		fgeffect=nil
	elseif pattern==13 or pattern==16 then
		if note==16 then
			bg=8
			bgeffect=nil
			fgeffect=nil
		elseif note<16 then
			fgeffect="star"
		elseif note%2==0 then
			bg=note/2
		end
	elseif pattern==14 then
		fgeffect="star"
		if n==4 then
			bg=6
		else
			bg=5
		end
	elseif pattern==15 then
		fgeffect=nil
		if n==4 then
			bg=6
		else
			bg=5
		end
		radius=3
		circlecol=2
	elseif pattern==17 then
		fgeffect="circle"
		bgeffect=nil
		if (note%16)<8 then
			if n==0 or n==2 then
				bg=2
			elseif n==1 or n==3 then
				bg=14
			end
			if n==4 then
				radius=6
				circlecol=12
			elseif n==5 then
				radius=9
				circlecol=11
			elseif n==6 then
				radius=12
				circlecol=10
			elseif n==7 then
				radius=15
				circlecol=8
			end
		else
			if n==1 or n==3 then
				bg=12
			elseif n==0 or n==2 then
				bg=1
			end
			if n==7 then
				radius=3
				circlecol=2
			elseif n==6 then
				radius=6
				circlecol=12
			elseif n==5 then
				radius=9
				circlecol=11
			elseif n==4 then
				radius=12
				circlecol=10
			end
		end
	elseif pattern==19 then
		fg=5
		if note==2 then
			bg=0
		elseif note==1 then
			bg=2
		elseif note==0 then
			bg=14
		elseif note==18 then
			bg=6
		elseif note==17 then
			bg=14
		elseif note==16 then
			bg=2
		end
	elseif pattern==20 then
		if note==2 then
			bg=0
		elseif note==1 then
			bg=9
		elseif note==0 then
			bg=10
		elseif note==18 then
			bg=6
		elseif note==17 then
			bg=10
		elseif note==16 then
			bg=9
		end
		circlecol=0
		radius=0
	elseif pattern==21 then
		if note==2 then
			fgeffect="square"
			fg=1
		end
		if note < 18 and note > 1 then
			radius=20
		elseif note == 18 then
			radius=35
		end
		if note==2 then
			bg=0
		elseif note==1 then
			bg=2
		elseif note==0 then
			bg=14
		elseif note==18 then
			bg=6
		elseif note==17 then
			bg=14
		elseif note==16 then
			bg=2
		end
		if perc%8==5 and fg==1 then
			fg=13
		elseif perc%8!=5 and fg==13 then
			fg=1
		end
		circlecol=bg
	elseif pattern==22 then
		fgeffect="square"
		if note < 18 and note > 1 then
			radius=20
		elseif note == 18 then
			radius=45
		end
		if note==2 then
			bg=0
		elseif note==1 then
			bg=9
		elseif note==0 then
			bg=10
		elseif note==18 then
			bg=6
		elseif note==17 then
			bg=10
		elseif note==16 then
			bg=9
		end
		if perc%8==5 and fg==1 then
			fg=13
		elseif perc%8!=5 and fg==13 then
			fg=1
		end
		circlecol=bg
	elseif pattern==23 or pattern==24 or pattern==27 or pattern==28 then
		autostar=false
		if n==2 then
			fgeffect="star"
			updatestars()
			fg=5
		end
		if n==0 then
			bg=9
		elseif n==2 then
			bg=10
		elseif n==4 then
			bg=9
		elseif n==6 then
			bg=4
		end
	elseif pattern==25 then
		if note==2 then
			circlecol=2
		elseif note==18 then
			circlecol=8
		end
		if n==0 then
			radius=15
		elseif n==1 then
			radius=17
		elseif n==2 then
			radius=15
			bg=5
			fg=0
			fgeffect="circle"
		elseif n==3 then
			radius=13
		elseif n==4 then
			radius=11
		elseif n==5 then
			radius=9
		elseif n==6 then
			radius=11
		elseif n==7 then
			radius=13
		end
		if note%16==10 then
			bg=6
		else
			bg=5
		end
	elseif pattern==26 then
		if note==2 then
			circlecol=2
		elseif note==18 then
			circlecol=8
		end
		if n==0 then
			radius=15
		elseif n==1 then
			radius=17
		elseif n==2 then
			radius=15
			bg=5
			fg=0
			fgeffect="circle"
		elseif n==3 then
			radius=13
		elseif n==4 then
			radius=11
		elseif n==5 then
			radius=9
		elseif n==6 then
			radius=11
		elseif n==7 then
			radius=13
		end
	elseif pattern==30 then
		bg=4
		fgeffect="star"
		autostar=true
	elseif pattern==31 then
		advance=false
		bg=0
		fgeffect=nil
		if note==16 then
			bg=6
		elseif note==20 then
			bg=6
		elseif note==24 then
			bg=6
		elseif note==26 then
			bg=6
		elseif note==28 then
			bg=6
		elseif note==29 then
			bg=5
		elseif note==30 then
			bg=6
		elseif note==31 then
			bg=5
			advance=true
		else
			bg=0
		end
		radius=4
	elseif pattern==32 then
		fgeffect="square"
		circlecol=1
		if n==4 or note%16==15 then
			bg=6
		else
			bg=0
		end
		if n==0 then
			radius=10
		elseif note==6 or note==14 then
			radius=10
		elseif note==18 or note==21 then
			radius=10
		else
			radius=4
		end
	elseif pattern==33 then
		fgeffect=nil
		if note==0 then
			advance=false
			bg=0
		elseif note==28 then
			rgbsprites=true
			bg=8
		elseif note==31 then
			advance=true
			radius=3
		end
	elseif pattern==34 or pattern==36 then
		fgeffect="circle"
		circlecol=7
		fg=0
		if n==4 or note%16==15 then
			bg=12
		else
			bg=8
		end
		if note==4 then
			radius=7
		elseif note==8 then
			radius=11
		elseif note==12 then
			radius=15
		elseif note==16 then
			radius=11
		elseif note==24 then
			radius=9
		end
	elseif pattern==35 then
		fg=0
		if n==4 or note%16==15 then
			bg=12
		else
			bg=8
		end
		if note==4 then
			radius=7
		elseif note==8 then
			radius=11
		elseif note==12 then
			radius=15
		elseif note==16 then
			radius=19
		elseif note==24 then
			radius=23
		end
	elseif pattern==37 then
		fg=0
		if n==4 or note%16==15 then
			bg=12
		else
			bg=8
		end
		if note==4 then
			radius=7
		elseif note==8 then
			radius=11
		elseif note==12 then
			radius=10
		elseif note==16 then
			radius=8
		elseif note==24 then
			radius=6
		end
	elseif pattern==38 then
		fg=0
		fgeffect=nil
		if n==4 or note%16==15 then
			bg=12
		else
			bg=8
		end
	elseif pattern==39 then
		if note==16 then
			bg=8
			bgeffect=nil
			fgeffect=nil
		elseif note<16 then
			fgeffect="star"
			bg=0
		elseif note%2==0 then
			bg=note/2
		end
	elseif pattern==40 then
		fgeffect="star"
		if n==4 then
			bg=6
		else
			bg=5
		end
	elseif pattern==42 or pattern==43 then
		circlecol=4
		bg=5
		fg=0
		fgeffect="circle"
		if n==0 then
			radius=13
		elseif n==2 then
			radius=11
		elseif n==4 then
			radius=9
		elseif n==6 then
			radius=11
		end
		if n==4 or note%16==15 then
			bg=6
		else
			bg=0
		end
	elseif pattern==44 or pattern==45 then
		circlecol=7
		bg=5
		fg=0
		fgeffect="circle"
		if n==0 then
			radius=13
		elseif n==2 then
			radius=11
		elseif n==4 then
			radius=9
		elseif n==6 then
			radius=11
		end
		version="game saved!"
		if not cansave then
			version="debug: save disabled"
		end
	elseif pattern==46 then
		name=""
		splash="snek has eaten snak!"
	elseif pattern==48 then
		if note<16 then
			version=""
			drawtitle=true
			name="by"
			splash="megabyte112"
		else
			name="made with pico-8"
			splash="and 1505 lines of code"
		end
	elseif pattern==49 then
		name="thank you for playing!"
		splash=""
		if note==31 then
			splash="🅾️ / z:  endless mode"
		end
	elseif pattern==-1 and endgame then
		name="thank you for playing!"
		splash="🅾️ / z:  endless mode"
	else
		bgeffect=nil
		fgeffect=nil
		bgflashcol=11
		fgflashcol=5
		bg=5
		fg=0
	end
end

function updatestars()
	if fgeffect=="star" then
		stars={}
		for i=1,32 do
			add(stars, {flr(rnd(30)+1),flr(rnd(29))+2})
		end
	end
end
-->8
--stages

function loadstage(stage)
	rgbsprites=false
	hinttext=""
	if endless then rgbsprites=true end
	changephase=false
	advance=true
	title=false
	body={}
	pos[1]=startpos[1]
	pos[2]=startpos[2]
	bgeffect=nil
	fgeffect=nil
	bgflashcol=11
	fgflashcol=5
	bg=5
	fg=0
	grace=false
	graceused=false
	endless=false
	for i=1,#startbody do
		body[i]=startbody[i]
	end
	direction=startdirection
	sprinttime=startsprinttime
	musphase(stage)
	phase=stage
	dead=false
	if stage==0 then
		score = 0
		sprinttime=0
		pos={10,20}
		startpos={10,20}
		direction="up"
		body={}
		startbody={}
		food={10,10}
		canmove=true
		expanding=false
		queue=nil
		phase=0
		fontcol=7
		bgeffect=nil
		fgeffect=nil
		bgflashcol=11
		fgflashcol=5
	elseif stage==1 then
		expanding=true
		score=50
	elseif stage==2 then
		expanding=true
		score=100
	elseif stage==3 then
		expanding=true
		score=150
	elseif stage==4 then
		music(-1)
		music(50)
		phase=4
		sprinttime=0
		rgbsprites=true
		endless=true
		score = 0
		pos={10,20}
		startpos={10,20}
		direction="up"
		body={}
		startbody={}
		food={10,10}
		canmove=true
		expanding=false
		queue=nil
	end
end
-->8
--saving and loading

--[[
layout of save file:

zero,
	prevents older versions
	from loading this save
stage,
	equal to phase+1
x position,
y position,
direction,
	1 = up
	2 = down
	3 = left
	4 = right
sprint timer (16-bit),
each body section,
	x pos, y pos, etc
	

512 bytes are copied each save

]]--
function savegame()
	if not cansave then return end
	poke(0x4300,0)
	poke(0x4301, phase+1)
	poke(0x4302, pos[1])
	poke(0x4303, pos[2])
	if direction=="up" then
		poke(0x4304,1)
	elseif direction=="down" then
		poke(0x4304,2)
	elseif direction=="left" then
		poke(0x4304,3)
	else
		poke(0x4304,4)
	end
	--can be greater than 127, so
	--this must be 16-bit
	poke2(0x4305,sprinttime)
	local current=0x4307
	for i=1,#body do
		poke(current,body[i][1])
		current+=1
		poke(current,body[i][2])
		current+=1
	end
	local len=(score*2)+4
	cstore(0x0000,0x4300,0x0200,"snaksave")
end

function loadgame()
	reload(0x4300,0x0000,0x0200,"snaksave")
	phase=peek(0x4301)
	startpos[1]=peek(0x4302)
	startpos[2]=peek(0x4303)
	if peek(0x4304)==1 then
		startdirection="up"
	elseif peek(0x4304)==2 then
		startdirection="down"
	elseif peek(0x4304)==3 then
		startdirection="left"
	else
		startdirection="right"
	end
	startsprinttime=peek2(0x4305)
	local current=0x4307
	local index=(phase*50)-1
	score=phase*50
	startbody={}
	for i=1,index do
		startbody[i]={}
		startbody[i][1]=peek(current)
		current+=1
		startbody[i][2]=peek(current)
		current+=1
	end
end

function issavegame()
	reload(0x4300,0x0000,0x0200,"snaksave")
	if peek(0x4300)~=0 then return false end
	if peek(0x4301)>0 then
		savedphase=peek(0x4301)
		if savedphase==4 then
			savedphase="endless"
		else
			savedphase="stage "..savedphase+1
		end
		return true
	else
		return false
	end
end

function deletedata()
	memset(0x4300,0x0000,0x0200)
	cstore(0x0000,0x4300,0x0200,"snaksave")
end
__gfx__
00000000eeee0000bbbb000008800000777700000000000000000000000000008888000099990000cccc0000aaaa000000000000000000000000000000000000
00700000e2210000b335000087280000766500000777777777777777700000008008000090090000c00c0000a00a000000000000000000000000000000000000
07000000e2210000b335000082280000766500000700000000000000700000008008000090090000c00c0000a00a000000000000000000000000000000000000
00000000111100005555000008800000555500000700000000000000700000008888000099990000cccc0000aaaa000000000000000000000000000000000000
00000000000000000000000000000000000000000700000000000000700000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000777777777777777700000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000eeee00006666000009900000777700000000000000000000000000007000000007000000007000000007000000000000000000000000000000000000
07000000e88200006cc5000097a90000700600000000000000000000000000000000000000000000000000000000000000070000700000000000000000000000
00700000e88200006cc500009aa90000700600000070000000000000000000000000000000000000000000000000000070000000000700000000000000000000
00000000222200005555000009900000666600000070000000000000000000000007000000700000070000007000000000000000000000000000000000000000
00000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ffff0000aaaa00000110000050050000000000000000000000000000089000000e80000002e00000012000000c1000000bc000000ab0000009a00000
00000000faa90000a994000017c1000000000000000000000000000000000000e75a00002759000017580000c75e0000b7520000a7510000975c0000875b0000
00000000faa90000a99400001cc1000000000000000000000000000000000000255b0000155a0000c5590000b5580000a55e00009552000085510000e55c0000
000000009999000044440000011000005005000000000000000000000000000001c000000cb000000ba000000a9000000980000008e000000e20000002100000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000007777000077770000055000006666000000000000000000000000000089ab00009abc0000abc10000bc1e0000c1e800001e890000e89a000000000000
000000007cc500007ee5000057650000600600000000000000000000000000009abc0000abc10000bc1e0000c1e800001e890000e89a000089ab000000000000
000000007cc500007ee500005665000060060000000000000000000000000000abc10000bc1e0000c1e800001e890000e89a000089ab00009abc000000000000
0000000055550000555500000550000066660000000000000000000000000000bc1e0000c1e800001e890000e89a000089ab00009abc0000abc1000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000880000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000880000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000009977ff0000eeee000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000009977ff0000e221000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000aa777777ee00e221000000000000000000000000000000000000000000000000000000000000000000000000
0000000066660066660000666666006600660000aa777777ee001111000000000000000000000000000000000000000000000000000000000000000000000000
000000006666006666000066666600660066000000bb77dd0000bbbb000000000000000000000000000000000000000000000000000000000000000000000000
000000660000006600660066006600660066000000bb77dd0000b335000000000000000000000000000000000000000000000000000000000000000000000000
00000066000000660066006600660066006600000000cc000000b335000000000000000000000000000000000000000000000000000000000000000000000000
00000000666600660066006666660066660000000000cc0000005555000000000000000000000000000000000000000000000000000000000000000000000000
000000006666006600660066666600666600000000000000bbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000
000000000066006600660066006600660066000000000000b335b335000000000000000000000000000000000000000000000000000000000000000000000000
000000000066006600660066006600660066000000000000b335b335000000000000000000000000000000000000000000000000000000000000000000000000
00000066660000660066006600660066006600000000000055555555000000000000000000000000000000000000000000000000000000000000000000000000
000000666600006600660066006600660066000000000000bbbb0000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000b3350000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000b3350000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000055550000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000880000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000880000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000009977ff0000eeee000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000009977ff0000e221000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000aa777777ee00e221000000000000000000000000000000000000000
0000000000000000000000000000000000000000066660066660000666666006600660000aa777777ee001111000000000000000000000000000000000000000
000000000000000000000000000000000000000006666006666000066666600660066000000bb77dd0000bbbb000000000000000000000000000000000000000
000000000000000000000000000000000000000660000006600660066006600660066000000bb77dd0000b335000000000000000000000000000000000000000
00000000000000000000000000000000000000066000000660066006600660066006600000000cc000000b335000000000000000000000000000000000000000
00000000000000000000000000000000000000000666600660066006666660066660000000000cc0000005555000000000000000000000000000000000000000
000000000000000000000000000000000000000006666006600660066666600666600000000000000bbbbbbbb000000000000000000000000000000000000000
000000000000000000000000000000000000000000066006600660066006600660066000000000000b335b335000000000000000000000000000000000000000
000000000000000000000000000000000000000000066006600660066006600660066000000000000b335b335000000000000000000000000000000000000000
00000000000000000000000000000000000000066660000660066006600660066006600000000000055555555000000000000000000000000000000000000000
000000000000000000000000000000000000000666600006600660066006600660066000000000000bbbb0000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000b3350000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000b3350000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000055550000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000666000006660666066606660660066606600000006606000066066006660000006606660000006606600666060606660000000000000000000
00000000000000606000006060600060000600606060006060000060006000606060606000000060606000000060006060606060606000000000000000000000
00000000000000666000006600660066000600606066006060000060006000606060606600000060606600000066606060666066006600000000000000000000
00000000000000606000006060600060000600606060006060000060006000606060606000000060606000000000606060606060606000000000000000000000
00000000000000606000006060666060006660606066606660000006606660660060606660000066006000000066006060606060606660060000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000006606600666060600000666066606660000006606600666060600000000000000000000000000000000000000000
00000000000000000000000000000000000060006060600060600000600060600600000060006060606060600000000000000000000000000000000000000000
00000000000000000000000000000000000066606060660066000000660066600600000066606060666066000000000000000000000000000000000000000000
00000000000000000000000000000000000000606060600060600000600060600600000000606060606060600000000000000000000000000000000000000000
00000000000000000000000000000000000066006060666060600000666060600600000066006060606060600600000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000055505050000055505550055055505550505055505550550055005550000000000000000000000000000000000000
00000000000000000000000000000000000050505050000055505000500050505050505005005000050005000050000000000000000000000000000000000000
00000000000000000000000000000000000055005550000050505500500055505500555005005500050005005550000000000000000000000000000000000000
00000000000000000000000000000000000050500050000050505000505050505050005005005000050005005000000000000000000000000000000000000000
00000000000000000000000000000000000055505550000050505550555050505550555005005550555055505550000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
4820000000755007051f6250000000755007051f6250070500755007051f625007050075513600136251f62500755000051f6250000500755000051f6250000500755000051f625000050075513655136251f625
082000001f0541d0501c0501a0501f0541d0501c0501a0501a0541c0501a0501a0501c0541a0521a05210051180541a05218052180521a054180521805218052180541a05218052180521a054180521805117051
4c2000000b1350b1350b1350b1350b1350b1350b1350b1350e1350e1350e1350e135071350713507135091310913509135091350913509135091350913509135091350913509135091350913509135091350b131
08200000230542305021050210501f054210501f0501f0501f054210501f0521f052210541f0521f0521d0511c0541c0521d0521f0521c0541c0521d0521f052210541d0521f0521c0521a0541c0521a05111051
08200000230542305021050210501f054210501f0501f0501f054210501f0521f052280511f0521f0521d0511c0541c0521d0521f0521c0541c0521d0521f052210541a0521c0521c05218054180521805111051
4c2000000b1350b1350b1350b1350b1350b1350b1350b1350b1350b1350b1350b1350b1350b1350b1350b1350b1350b1350b1350b1350b1350b1350b1350b1350b1350b1350b1350b1350b1350b1350b1350b135
082000001f0341d0301c0301a0301f0341d0301c0301a0301f0341d0301c0321c03218032180321803218032180321a00018000180001a000180001800018000180001a00018000180001a000180001800017000
c0100000103300c330053300533105321053110531005310053100531005310053100531005310053100531007330093300b3300b3310b3210b3110b3100b3100b3100b3100b3100b3100b3100b3100b3100b310
c0100000093300b330053300533105321053110531005310053100531005310053100531005310053100531007330093301033010331103211031110310103101031010310103101031010310103101031010310
001000001800018000187501870018700187001875018700187001870018750187001870018700187501870018700187001a7501870018700187001a7501870018700187001a7501870018700187001a75018700
c020000000000001700015500000000001c6751c6000460000100021700215500000000001c675106000460002100001700015500000000001c675046000460000100071700715500000000001c6750460004600
802000002802529025260252402528025290252602524025280252902526025240252802529025260252402528025290252602524025280252902526025240252802529025260252402528025290252602524025
c0100000093300b330053330530005300053000530005300053000530005300053000530005300053000530007300093001030010300103001030010300103001030010300103001030010300103001030010300
00200020135540c1150c6150c115115540c1150e1110c115105540c1150c6150c1150e5540c1150e1110c1150c5540c1150c6150c1150e5540c1150e1110c115105540c1150c6150c1150e5540c1150e1110c115
d01000001853018510185000050000500185001f5301f5101a5301a5101050015500155001550018530185101c5301c51018530185101f5301f5101f5001f5001a5301a5101a5001a50000500005000000000000
d010000018530185101f5301f5101c5301c51020000200001c5301c510170001700018530185101f5301f5101c5301c51020000200001c5301c5101e0001e00018530185101f5301f51018530185101f5301f510
001000101353511535105350e5350c5000c5001353511535105350e5350c5000c5001353511535105350e53515000130001d700000000000023700217001f7001d70000000000000000000000000000000000000
001000200705500000070550000007055000000705500000070550000004055000000405500000040550000009055000000905500000090550000009055000000905500000020550000002055000000205500000
001000100e5351053511535135350c5000c5000e5351053511535135350c5000c5000e5351053511535135351350011500105000e5000c5000c5001350011500105000e5000c5000c5001350011500105000e500
11100000185451f54524545185251f52524525185151f51524515183001f300243000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
101000000212502125021250212507655021250212502125021250212502125021250765502125021250212502125021250212502125076550212502125021250212502125021250212507655021250212507655
1010000007755000000575500000047550000002755000001355500000115550000010555000000e555000001315500000111550000010155000000e155000001f155000001d155000001c155000001a15300000
1010000007525000000552500000045250000002525005001302500000110250000010025000000e025000001342500000114250000010425000000e425000001f225000001d225000001c225000001a22300000
001000000c110101100c1101111000000111100c110000000c110101100c1101111000000111100c110000000c635101000c635111000c635111000c635000000c635101000c635111000c635111000c63500000
0010000013020130201302013020150201502215022180201c0201c0201c0201c020180201802018020180201c0221c0221c0221c0222102021020210201c0201802218022180221802215022150221502215022
001000002375511055217551105523755110552175511055237551105521755110552375511055217551105523755110552175511055237551105521755110552375511055217551105523755110552175511055
001000002b7551505529755150552b7551505529755150552b7551505529755150552b7551505529755150552b7551505529755150552b7551505529755150552b7551505529755150552b755150552975515055
0010000005325073251f055000002105500000230550000005325023251a055000001c055000001d0550000005325073251f055000002105500000230550000005325023251a055000001c055000001d05500000
0010000005325073251f055000002105500000230550000005325023251a055000001c055000001d055000001f055000001d055000001c055000001a055000001f055000001d055000001c055000001a05300000
001000000c120101200c1201112011655111200c120000000c120101200c1201112011655111200c120000000c120101200c1201312011655131200c120000000c120101200c1201112011655111200c12000000
08100000247422873224722287121d3251c3251a325183251f742237321f72223712183251a3251c3251d325247422873224722287121d3251c3251a325183251f742237321f72223712183251a3251c3251d325
08100000247422873224722287121d3251c3251a325183251f742237321f72223712183251a3251c3251d3251f325287001d325287001c3251c3001a325183001f325237001d325237001c3251a3001a3231d300
000c00200c0531d300000000000024615000000c0531d3000c0531d300000000000024615000000c053246150c053000000c0531d300246150c053246001d3000c0531d300000000000024615000000000024615
000c002009055050550405509055090550b0550b05504055090550505504055090550905510055100551005509055050550405509055090550b0550b055040550905505055040550905504055040550405504055
04ff00040005300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800002800000000000000000000000000000000000000000000000000000000000000000000000000000000655000000000000000006550000000000000000065500000006550000000655006550065500655
9610000009755057550475509755097550b7550b75504755097550575504755097550975510755107551075509755057550475509755097550b7550b755047550975505755047550975504755047550475504755
d00c00001304413040110401104010040100400e0400e0401304413040110401104010040100400e0400e0400e0440e04010040100400e0400e0400e0400e04010044100400e0420e0420e0420e0420e0420e042
000c000018700000000000000000187501873018720187101f7501f7301f7201f710247502473024720247101f7501f7301f7201f7101c7001c7001a7001a7001d7501d7301d7201d7101c7001c7001a70000000
000c000018700187001a7001a700187501873018720187101f7501f7301f7201f71024750247302472024710267502673026720267101c7001c7001a7001a700287502873028720287101c7001c7001a7001a700
000c000018700187001a7001a700187501873018720187101f7501f7301f7201f7101c7501c7301c7201c7101a7501a7301a7201a710000000000000000000001875018730187201871000000000000000000000
c00c000018700187001a7001a700187541875018005180051f7541f750000001f005247542475000000000001f7541f750000001c0051c0051a0051a005000001d7541d750000001c0050c7531a0001a70000000
d00c00001302413020110201102010020100200e0200e0201302413020110201102010020100200e0200e0200e0240e02010020100200e0200e0200e0200e02010024100200e0220e0220c053000000000000000
d00c0000075300753007530075300953009532095320c530105301053010530105300c5300c5300c5300c53010532105321053210532155301553015530105300c5320c5320c5320c53209532095320953209532
000c000018700187001a7001a700187501873018720187101f7501f7301f7201f710247502473024720247101f7501a7001d750000001c750000001a750000001f750000001d750000001c750000001a75300000
000c00000c110101100c1101111000000111100c110000000c110101100c1101111000000111100c110000001f1251c5001d1251c5001c125171001a125131001f125175001d125175001c125151001a12300000
000c00000c0531d300000000000024615000000c0531d3000c0531d300000000000024615000000c053000000c625000000c6251d3000c6250c0000c6251d3000c6251d3000c625000000c625000000c62324600
000c00000012500125001250012517625001250012500125001250012500125001251762500125001250012500125001250012500125176250012500125001250012500125001250012517625001250012517625
000c000018020000001a020000001c020000001d02000000000001d0201d020000001f0221f0221f023000001d020000001f020000001d020000001c02000000000001c0201c020000001d0221d0221d02300000
000c000018030000001a030000001c030000001d03000000000001d0301d030000001f0321f0321f033000001d030000001f030000001d030000001c03000000000001c0301c030000001d0321d032103100c310
c00c0000053200531105310053100531005310053100531005310053100531005310053100531007320093200b3200b3110b3100b3100b3100b3100b3100b3100b3100b3100b3100b3100b3100b310093200b320
c00c0000053200531105310053100531005310053100531005310053100531005310053100531007320093201032010311103101031010310103101031010310103101031010310103101031010310103200c320
800c00002901029015260102601524010240152801028015290102901526010260152401024015280102801529010290152601026015240102401528010280152901029015260102601524010240152801028015
d00c0000075300753007530075300953009532095320c530105301053010530105300c5300c5300c5300c53010532105321053210532155301553015530105300c5320c5320c5320c53209532095322801028015
000c00000531300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001800020015500000001000000000100000000010000000001000000000100000000010000000001000000000100000000010000000001000000000100000000000000000000000000000000000000000000000
000c00002800000000000000000000000000000000000000000000000000000000000000000000000000000000655000000000000000006550000000000000000065500000006550000000655006550065500655
081800001f0541d0501c0501a0501f0541d0501c0501a0501a0541c0501a0501a0501c0541a0521a05210051180541a05218052180521a054180521805218052180541a05218052180521a054180521805117051
080c00001f0541f0501d0501d0501c0501c0501a0501a0501f0541f0501d0501d0501c0501c0501a0501a0501f054000001d050000001c050000001a050000001f054000001d050000001c050000001805300000
080c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
080c0000247002870024700287001d3001c3001a300183001f700237001f70023700183001a3001c3001d3001f300287001d300287001c3001c3001a300183001f300237001d300237001c3001a3001a3001d300
100c000007700000000570000000047000000002700000001350000000115000000010500000000e500000001310000000111000000010100000000e100000001f100000001d100000001c100000001a10000000
100c000007500000000550000000045000000002500005001300000000110000000010000000000e000000001340000000114000000010400000000e400000001f200000001d200000001c200000001a20000000
__music__
03 05424244
03 00024044
03 00020144
00 03000244
00 04000244
03 01024044
03 00020146
04 06424044
03 19545744
03 19145744
03 1a145a44
03 1b145744
00 1b574344
00 1c175e44
03 181d5e44
00 1d1b1844
00 1715161c
03 1d181e1b
04 1715161f
01 07424344
02 08424344
01 07090a44
02 08090a44
01 090a0b07
02 08090a0b
03 090a0b44
00 090b4344
01 070b0a09
02 08090a0b
04 0c424344
03 24614344
00 23224344
03 20216544
00 292a2260
01 20212625
00 20212725
00 20212625
02 20212825
00 2120266b
00 2c2d2e6b
03 2120302b
00 3135706b
01 32212034
02 33212034
01 32344344
02 33346074
00 36343744
00 38343778
00 39223720
04 3a372044
00 11517d7e
00 11507760
01 11107760
00 11107760
00 11100e60
00 11100e60
00 11120f60
00 11120f60
00 11127760
02 11127760
00 41424344
00 41424344
00 41424344
03 0d424344

