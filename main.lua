function loadPhysical()
	lineI, colI = 1,1
	for line in level:gmatch(chCl) do 
		colI=1
		for i=1,#line do
			char = line:sub(i, i)
			if char == '#' then
				dashSolids:set(nil, (colI-1)*grid, (lineI-1)*grid, grid, grid, {"movingBlocker", 'solid'})
			end
			if char == '*' then
				dashSolids:set(nil, (colI-1)*grid, (lineI-1)*grid, grid, grid, {"movingBlocker"})
			end
			if char == 'F' then
				dashSolids:set(nil, (colI-1)*grid, (lineI-1)*grid, grid, grid, {"finish"})
			end
			if char == '@' then
				player.x = (colI-1)*grid
				player.y = (lineI-1)*grid
			end
			if char == '>' then
				len = grid
				holdCol =  colI
				colI = colI + 1
				while line:sub(colI, colI) == '-' do 
					len = len + grid
					colI = colI + 1
				end
				colI = holdCol
				nom = dashSolids:set(nil, (holdCol-1)*grid, (lineI-1)*grid, len, grid, {"moving", 'solid'})
				movings[nom] = 1
			end
			if char == 'O' then
				nom = dashSolids:set(nil, (colI-1)*grid, (lineI-1)*grid, grid, grid, {'jumpBoost'})
				jumpBoosts[nom] = true
			end
			if char == 'X' then
				dashSolids:set(nil, (colI-1)*grid, (lineI-1)*grid, grid, grid, {'lethal'})
			end
			if char == '<' then
				len = grid
				holdCol =  colI
				colI = colI + 1
				while line:sub(colI, colI) == '-' do 
					len = len + grid
					colI = colI + 1
				end
				colI = holdCol
				nom = dashSolids:set(nil, (holdCol-1)*grid, (lineI-1)*grid, len, grid, {"moving", 'solid'})
				movings[nom] = -1
			end
			colI=colI+1
		end
		lineI = lineI + 1
	end
end
function loadLevel(i)
	setUpPlayer()
	levelNum = i
	level = levels[i]
	dashSolids:clear()
	movings = {}
	jumpBoosts = {}
	loadPhysical()
end
function setUpPlayer()
	player.x = 220
	player.y = 100
	player.ac = 1200
	player.fDEFAULT = 4.5
	player.fMOVING = 1
	player.f = 0
	player.xv = 0
	player.xvmax = 330
	player.jump = 440
	player.jumpNumber = 0
	player.jumpFraction = 0.75
	player.jumpLast = 'none'
	player.clingDistance = 5
	player.jumpComputeTimes = 5
	player.moveComputeTimes = 5
	player.maxWallSpeed = 20
	player.jumpAlready = false
	player.canJump = true
	player.yv = 0
	player.g = 1750
	player.w = 16
	player.h = 16
end

function love.load()
	dashSolids = require('DashSolids')
	levels = require('levels')
	Tiles = 'countryside.png'
	Tileset = love.graphics.newImage(Tiles)
	height = 576
	width = 800
	love.window.setMode( 800, 576)





	levelNum = 1
	level = levels[1]
	grid = 16
	chCl = '[ F#><*-OX@]+'
	--' ' could be 0, 0
	QuadData={ {' ',0,0},{'#',16,0},{'*',0,0},{'>',0,0},{'<',0,0},{'-',0,0},{'@',0,0},{'O',0,0},{'X',16,16},{'F',32,0} }
	
	moving = love.graphics.newQuad(16,0,16,16,64,64)
	boost = love.graphics.newQuad(0,16,16,16,64,64)


	Quads = {}
	for i=1,#QuadData do 
		Quads[QuadData[i][1]] = love.graphics.newQuad(QuadData[i][2],QuadData[i][3],grid,grid,64,64)
	end


	player = {}
	setUpPlayer()
	function player:adjustX (grid,proxy,disp)
		disp = disp or 0
		proxy = proxy or 16
		grid = grid or grid
		disp = disp%grid
		self.x=self.x-disp
		if self.x%grid<proxy then
			self.x=self.x-self.x%grid
		elseif self.x%grid>grid-proxy then
			self.x=self.x-self.x%grid+grid
		end
		self.x=self.x+disp
	end
	function player:adjustY (grid,proxy,disp)
		disp = disp or 0
		proxy = proxy or 16
		grid = grid or grid
		disp = disp%grid
		self.y=self.y-disp
		if(self.y%grid<proxy)then
			self.y=self.y-self.y%grid
		elseif self.y%grid>grid-proxy then
			self.y=self.y-self.y%grid+grid
		end
		self.y=self.y+disp
	end




	movings = {}
	moveSpeed = 100
	jumpBoosts = {}





	loadLevel(1)
end


function die()
	
	if player.x<0 or player.x>width or player.y<0 or player.y>height or love.keyboard.isDown('r') or dashSolids:checkCollision(player.x,player.y,player.w,player.h,"solid") or dashSolids:checkCollision(player.x,player.y,player.w,player.h,"lethal") then
		if love.keyboard.isDown('n') then
			levelNum = levelNum + 1
		end
		loadLevel(levelNum)
	end
end


function signOf(x, default)
	default = default or 0
	if x > 0 then
		return 1
	elseif x < 0 then
		return -1
	end
	return default 
end

function updateTheBoosts(dt)
	collect, name = dashSolids:checkCollision(player.x, player.y, player.w, player.h, "jumpBoost")
	if collect and jumpBoosts[name] then
		jumpBoosts[name] = false
		player.canJump = true
	end
end
function updateTheMoves(dt)
	for k,v in pairs(movings) do
		dashSolids.Solids[k].x = dashSolids.Solids[k].x + moveSpeed*v*dt
		if dashSolids:checkCollision(dashSolids.Solids[k].x-1, dashSolids.Solids[k].y, dashSolids.Solids[k].w+2, dashSolids.Solids[k].h, "movingBlocker") then 
			movings[k] = v*-1
			player.adjustX(dashSolids.Solids[k],grid,grid/2)
		end

	end
end

function wallJump()
	onFloor, nameB = dashSolids:checkCollision(player.x,player.y+5,player.w,player.h,"solid")
	if onFloor then 
		player.jumpLast = 'bottom'
	end
	onLeftWall, nameL = dashSolids:checkCollision(player.x-player.clingDistance,player.y,player.w,player.h,"solid")
	onRightWall, nameR = dashSolids:checkCollision(player.x+player.clingDistance,player.y,player.w,player.h,"solid")
	if onLeftWall and love.keyboard.isDown('up') and not player.jumpAlready and not onFloor then
		if player.jumpLast == 'right' then
			player.jumpNumber = 1
		end
		player.jumpAlready = true
		player.jumpLast = 'left'
		player.xv = player.xvmax
		player.yv = -player.jump*math.pow(player.jumpFraction, player.jumpNumber)
		player.jumpNumber = player.jumpNumber + 1
	end
	if onRightWall and love.keyboard.isDown('up') and not player.jumpAlready and not onFloor then
		if player.jumpLast == 'left' then
			player.jumpNumber = 1
		end
		player.jumpAlready = true
		player.jumpLast = 'right'
		player.xv = -player.xvmax
		player.yv = -player.jump*math.pow(player.jumpFraction, player.jumpNumber)
		player.jumpNumber = player.jumpNumber + 1
	end
end


function updateThePlayer(dt)
	if not love.keyboard.isDown('up') then
		player.jumpAlready = false
	end
	shouldAdjust, name = dashSolids:checkCollision(player.x,player.y,player.w,player.h,"moving")
	if shouldAdjust then
		player:adjustX(grid,8,dashSolids.Solids[name].x)
	end


	onMoving, n = dashSolids:checkCollision(player.x+1,player.y+1, player.w-2 ,player.h, "moving") 
	if onMoving then 
		player.x = player.x + moveSpeed*movings[n]*dt
	end

	player.f = player.fDEFAULT

	gfactor = 1
	if love.keyboard.isDown('up') and player.yv<0 then
		gfactor = 0.5
	end
	if dashSolids:checkCollision(player.x-1,player.y, player.w+2 ,player.h, "solid") and player.yv>player.maxWallSpeed and (love.keyboard.isDown('left') or love.keyboard.isDown('right')) then
		player.yv=player.maxWallSpeed
	end

	--Coninue in y direction
	cant, name = dashSolids:checkCollision(player.x,player.y + player.yv*dt, player.w, player.h, 'solid') 
	for i = 1, player.jumpComputeTimes do 
		cant, name = dashSolids:checkCollision(player.x,player.y + player.yv*dt/player.jumpComputeTimes, player.w, player.h, 'solid') 
		if not cant then
			player.y = player.y + player.yv*dt/player.jumpComputeTimes
			player.yv = player.yv + player.g*dt*gfactor/player.jumpComputeTimes
		else
			if player.yv>=0 then
				player:adjustY(grid,8, grid-16)
			else
				player:adjustY(grid,8)
			end
			player.yv = 0
		end
	end
	if cant then
		if player.yv>=0 then
			player:adjustY(grid,8, grid-16)
		else
			player:adjustY(grid,8)
		end
		player.yv = 0
		
	end


	if math.abs(player.xv) <= 10 then
		player.xv = 0
	end

	canWallJump = dashSolids:checkCollision(player.x-player.clingDistance,player.y+1, player.w+2*player.clingDistance,player.h, 'solid') 
	isBelow = dashSolids:checkCollision(player.x+1,player.y+1, player.w-2 ,player.h, 'solid')  
	if isBelow then
		player.jumpNumber = 0
		player.canJump = true
	end
	if love.keyboard.isDown('up') and player.canJump and not player.jumpAlready and (not canWallJump or isBelow) then
		player.jumpAlready = true
		player.yv = 0-player.jump
		player.jumpNumber = 1
		player.canJump = false
	end
	

	if love.keyboard.isDown('right') then
		player.xv = player.xv + player.ac*dt
		player.f = player.fMOVING
	elseif love.keyboard.isDown('left') then
		player.xv = player.xv - player.ac*dt
		player.f = player.fMOVING
	end
	if math.abs (player.xv*dt)>player.xvmax*dt then 
		if player.xv>0 then
			player.xv = player.xvmax 
		else
			player.xv = -player.xvmax 
		end
	end




	--willTouch, name = dashSolids:checkCollision(player.x + player.xv*dt/player.moveComputeTimes,player.y, player.w,player.h, 'solid')
	for i = 1,player.moveComputeTimes do
		willTouch, name = dashSolids:checkCollision(player.x + player.xv*dt/player.moveComputeTimes,player.y, player.w,player.h, 'solid')
		if not willTouch then 
			player.x = player.x+player.xv*dt/player.moveComputeTimes
		else
			player:adjustX(grid,8,dashSolids.Solids[name].x)
			player.xv = 0;
		end
	end





	player.xv = (math.abs(player.xv)-(player.xvmax*player.f*dt))*signOf(player.xv)
	--print(player.xv*dt,player.xvmax*dt)
	shouldAdjust, name = dashSolids:checkCollision(player.x,player.y,player.w,player.h,"moving")
	while shouldAdjust do
		player.x = player.x + (movings[name] or signOf(player.x-dashSolids.Solids[name].x,1))
		shouldAdjust, name = dashSolids:checkCollision(player.x,player.y,player.w,player.h,"moving")
	end
end






function love.update(dt)
	updateTheMoves(dt)
	updateThePlayer(dt)
	wallJump()
	updateTheBoosts(dt)
	die()
	if dashSolids:checkCollision(player.x,player.y,player.w, player.h, 'finish') then
		loadLevel(levelNum+1)
	end
end






function drawTiles()
	lineI, colI = 1,1
	for line in level:gmatch(chCl) do 
		colI=1
		for char in line:gmatch('.') do
			love.graphics.draw(Tileset, Quads[char], (colI-1)*grid, (lineI-1)*grid)
			colI=colI+1
		end
		lineI = lineI + 1
	end
end
function drawBlocks()
	lineI, colI = 1,1
	for line in level:gmatch(chCl) do 
		colI=1
		for char in line:gmatch('.') do
			if char=='#' then
				love.graphics.draw(Tileset, Quads[char], (colI-1)*grid, (lineI-1)*grid)
			end
			colI=colI+1
		end
		lineI = lineI + 1
	end
end
function drawMovings()
	for k,_ in pairs(movings) do 
		for i =0, dashSolids.Solids[k].w/grid-1 do
			love.graphics.draw(Tileset, moving, math.floor(dashSolids.Solids[k].x)+i*grid, dashSolids.Solids[k].y)
		end
	end
end
function drawBoosts()
	for k, v in pairs(jumpBoosts) do
		if v then
			love.graphics.draw(Tileset, boost, math.floor(dashSolids.Solids[k].x), dashSolids.Solids[k].y)
		end
	end

end



function love.draw()
	love.graphics.setColor(255, 255, 255)
	drawTiles()
	if dashSolids:checkCollision(player.x,player.y,player.w,player.h) then
		love.graphics.setColor(100, 0, 0)
	end
	love.graphics.setColor(0, 255, 0)
	if not player.canJump then
		love.graphics.setColor(0, 100, 0)
	end
	love.graphics.rectangle('fill',player.x,player.y,player.w,player.h)
	--love.graphics.rectangle('line',player.x+4,player.y+1, grid-8,grid)
	love.graphics.setColor(255, 255, 255)
	drawBlocks()
	drawMovings()
	drawBoosts()
	--dashSolids:draw()

	

end