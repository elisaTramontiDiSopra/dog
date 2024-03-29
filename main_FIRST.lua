-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
-- this module turns gamepad axis events and mobile accelometer events
-- into keyboard events so we don't have to write separate code
-- for joystick and keyboard control
require("com.ponywolf.joykey").start()

-- add virtual buttons to mobile
system.activate("multitouch")
if isMobile or isSimulator then
    local vjoy = require "com.ponywolf.vjoy"
    local right = vjoy.newButton("scene/game/img/ui/wheelButton.png", "right")
    local left = vjoy.newButton("scene/game/img/ui/footButton.png", "left")
    local jump = vjoy.newButton("scene/game/img/ui/jumpButton.png", "space")
    right.x, right.y = display.screenOriginX + 256 + 32,
                       display.screenOriginY + display.contentHeight - 96
    left.x, left.y = display.screenOriginX + 128,
                     display.screenOriginY + display.contentHeight - 96 - 32
    jump.x, jump.y = -display.screenOriginX + display.contentWidth - 128,
                     display.screenOriginY + display.contentHeight - 96
    right.xScale, right.yScale = 0.5, 0.5
    left.xScale, left.yScale = 0.5, 0.5
    jump.xScale, jump.yScale = 0.5, 0.5
end

local composer = require "composer"
local physics = require "physics"
physics.start()
physics.setGravity( 0,0 )
physics.setDrawMode( "hybrid" )

local debugOn = true

-- game var
local padButtonDimension = 30 -- GAMEPAD
local buttonPressed = {Down = false, Up = false, Left = false, Right = false}
local widthFrame, heightFrame = 50, 50
local gridMatrix = {}
local gridRows, gridCol, centerHoriz, centerVert, marginHoriz, marginVert --just initial random data, they will be calculated in createGrid()
local velocity = 5

local player
--local bodyOptions = {density = 100.0, friction = 15, bounce = 0 }
local levelVars = {
  {lvl = 1, trees = 5, minPeeLevel = 0.2, vanishingPee = 1.5, minutes = 2, pathTracerMoves = 300},
  {lvl = 2, trees = 5, minPeeLevel = 0.2, vanishingPee = 1.5, minutes = 2, pathTracerMoves = 300},
  {lvl = 3, trees = 6, minPeeLevel = 0.3, vanishingPee = 1.5, minutes = 2, pathTracerMoves = 300},
  {lvl = 4, trees = 6, minPeeLevel = 0.3, vanishingPee = 1, minutes = 2, pathTracerMoves = 300}
}
local totalLevelTrees, pathTracerMoves, peeLevel, minPeeLevel = 0, 0, 0

-- Obstacles Sheet vars
local obstacles = {'flower','rock','tree'}
local obstaclesSrc = "scene/game/img/ground/ground.jpg"
local obstaclesSheetOptions = {width = widthFrame, height = heightFrame, numFrames = 16}
local obstaclesSheet = graphics.newImageSheet(obstaclesSrc, obstaclesSheetOptions)
local obstaclesSequenceData = {
    {name = "path1", start = 1, count = 1, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "path2", start = 2, count = 1, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "path3", start = 3, count = 1, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "path4", start = 4, count = 1, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "flower1", start = 5, count = 1, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "flower2", start = 6, count = 1, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "flower3", start = 7, count = 1, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "flower4", start = 8, count = 1, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "rock1", start = 9, count = 1, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "rock2", start = 10, count = 1, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "rock3", start = 11, count = 1, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "rock4", start = 12, count = 1, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "tree1", start = 13, count = 1, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "tree2", start = 14, count = 1, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "tree3", start = 15, count = 1, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "tree4", start = 16, count = 1, time = 100, loopCount = 0, loopDirection = "forward"}
}
local obstacleGrid = {}
local treeGrid = {}
local treeModel = {}

-- Image and sprite options for dog
local dogSrc = "scene/game/img/caracters/mainDog.png"
local tilesSrc = "scene/game/img/tiles/" --NEED TO ADD THE IMAGE AT THE END
local sheetOptions = {width = widthFrame, height = heightFrame, numFrames = 20}
local sequenceData = {
    {name = "walkingDown", start = 1, count = 4, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "walkingLeft", start = 5, count = 4, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "walkingRight", start = 9, count = 4, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "walkingUp", start = 13, count = 4, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "pee", start = 17, count = 4, time = 100, loopCount = 0, loopDirection = "forward"}
}

-- Get the screen values
local screenWidth = display.viewableContentWidth
local screenHeight = display.viewableContentHeight

-- Removes status bar on iOS
display.setStatusBar( display.HiddenStatusBar )

-- Removes bottom bar on Android
if system.getInfo( "androidApiLevel" ) and system.getInfo( "androidApiLevel" ) < 19 then
  native.setProperty( "androidSystemUiVisibility", "lowProfile" )
else
  native.setProperty( "androidSystemUiVisibility", "immersiveSticky" )
end

-- create obstacle Sprite (to change the properties quickly)
function createObstacleSprite(self, imgName, xPos, yPos)
    --self.image = display.newImage("images/"..imgName..".png" )
    self.image:setReferencePoint( CenterReferencePoint )
    self.image.x = xPos
    self.image.y = yPos
    self.image.name = "obstacle"
    self.peeLevel = 100
    self.minPeeLevel = 0.2
end




-- Create a grid filled with obstacles
local function createTheGrid()
  -- find the grid dimensions
  gridCol = math.floor(display.contentWidth / widthFrame)
  gridRows = math.floor(display.contentHeight / heightFrame)
  centerHoriz = math.floor(gridRows/2)
  centerVert = math.floor(gridCol/2)
  marginHoriz = (display.contentWidth - (gridCol * widthFrame))/2
  marginVert = (display.contentHeight - (gridRows * heightFrame))/2
  -- center the grid

  -- set level vars
  totalLevelTrees = levelVars[1].trees
  miniPeeLevel = levelVars[1].miniPeeLevel
  pathTracerMoves = levelVars[1].pathTracerMoves


  createObstacleSprite('grass' , 100, 100)
  -- Populate the grid matrix for the level
  --[[ for i = 1, gridRows do
    gridMatrix[i] = {} -- create a new row
    for j = 1, gridCol do
        gridMatrix[i][j] = {
          row = i, col = j,
          xPos = j * widthFrame, yPos = i * heightFrame,
          obstacle = 1, backgroundFrame = obstacleBg,
          name = 'gridCell'..'-'..i..'-'..j, type = obstacle}
    end
  end ]]
end

-- Create the walking path in a graphic way (TO BE DEFINED BEFORE THE WALKING ALGORITHM)
local function openPath(rowNumber, colNumber)
    -- set the gridCell as path
    gridMatrix[rowNumber][colNumber].obstacle = 0
    -- choose the random path and save it in the grid to remember it
    randomPath = 'path'..math.random(4)
    gridMatrix[rowNumber][colNumber].backgroundFrame = randomPath
    -- remove the previous bg and replace
    cellName = gridMatrix[rowNumber][colNumber]
    -- position the path with the new background
    cellName = display.newSprite(obstaclesSheet, obstaclesSequenceData)
    cellName:setSequence(randomPath)
    cellName:play()
    cellName.x = gridMatrix[rowNumber][colNumber].xPos
    cellName.y = gridMatrix[rowNumber][colNumber].yPos
    for k,v in pairs(cellName._class) do
        print( k,v )
      end
end

-- Random walking algorithm, clearing the path
local function randomWalkPath()
  createTheGrid()
  -- place the pathTracer at the center of the screen where the player is
  pathTracer = display.newRect(gridMatrix[centerHoriz][centerVert].xPos, gridMatrix[centerHoriz][centerVert].yPos, widthFrame, heightFrame)
  pathTracer:setFillColor(0.8, 0.2, 0.3)
  pathTracer.name = "pathTracer"
  -- keep track of the grid coordinates to change from obstacle to path
  pathGridX = centerHoriz
  pathGridY = centerVert
  for count = 1, pathTracerMoves, 1 do
    -- 1 choose a random number between 1 and 4 (the 4 directions)
    randomDirection = math.random(4)
    if (randomDirection == 1 and pathGridY > 1) then -- moveUp
      pathTracer.y = pathTracer.y - heightFrame
      pathGridY = pathGridY - 1
    elseif (randomDirection == 2 and pathGridX > 1) then -- moveRight
      pathTracer.x = pathTracer.x - widthFrame
      pathGridX = pathGridX - 1
    elseif (randomDirection == 3 and pathGridX < gridRows) then -- moveLeft
      pathTracer.x = pathTracer.x + widthFrame
      pathGridX = pathGridX + 1
    elseif (randomDirection == 4 and pathGridY < gridCol) then -- moveDown
      pathTracer.y = pathTracer.y + heightFrame
      pathGridY = pathGridY + 1
    end
    openPath(pathGridX,pathGridY)
  end
end

-- Count the ramaining obstacles, add body to them and eventually select and create random trees
local function createObstacles()
  for i = 1, gridRows do
    for j = 1, gridCol do
      --[[ for k,v in pairs(obstacleGrid[i][j]) do
        print( k,v )
      end ]]
      if (gridMatrix[i][j].obstacle == 1) then
        table.insert(obstacleGrid, gridMatrix[i][j])
        cellName = gridMatrix[i][j].name
        cellName = display.newSprite(obstaclesSheet, obstaclesSequenceData)
        cellName.x = gridMatrix[i][j].xPos
        cellName.y = gridMatrix[i][j].yPos
        cellName:setSequence('flower1')      -- all obstacles have grass background
        cellName:play()
        physics.addBody(cellName, "static")
      end
    end
  end
end

-- function to determine if a cell is reachable, needed for transformObstaclesIntoTrees
local function checkIfReachable(r, c)
  r0 = r - 1
  r1 = r + 1
  c0 = c - 1
  c1 = c + 1
  reachable = 0
  -- check if the 4 direction are free (+1) or not (0)
  if gridMatrix[r][c1] ~= nil and gridMatrix[r][c1].obstacle == 0 then
   reachable = reachable + 1
  end
  if gridMatrix[r1] ~= nil and gridMatrix[r1][c].obstacle == 0 then
   reachable = reachable + 1
  end
  if gridMatrix[r][c0] ~= nil and gridMatrix[r][c0].obstacle == 0 then
   reachable = reachable + 1
  end
  if gridMatrix[r0] ~= nil and gridMatrix[r0][c].obstacle == 0 then
   reachable = reachable + 1
  end
  if reachable > 0 then
    return true
  end
end

local function transformObstaclesIntoTrees()
  actualTrees = 0
  for t = 1, totalLevelTrees do
    randomCell = math.random(totalLevelTrees)    -- choose a random cell
    -- check if it's close to path
    isReachable = checkIfReachable(obstacleGrid[randomCell].row, obstacleGrid[randomCell].col)
    if isReachable == true and actualTrees < totalLevelTrees then
      -- substitute the cell with the new background
      randomTree = 'tree'..math.random(4)               -- choose a random frame
      localRow = obstacleGrid[randomCell].row
      localCol = obstacleGrid[randomCell].col
      cellName = gridMatrix[localRow][localCol].name

      --set additional properties on the general grid for the tree
      gridMatrix[localRow][localCol].type = 'tree'      --add type for the collision check
      gridMatrix[localRow][localCol].myName = "tree"..t

      cellName = display.newSprite(obstaclesSheet, obstaclesSequenceData)
      cellName.x = gridMatrix[localRow][localCol].xPos
      cellName.y = gridMatrix[localRow][localCol].yPos
      cellName.name  = 'tree'..t
      print('cell')
      for k,v in pairs(cellName) do
        print( k,v )
      end

      cellName:setSequence(randomTree)
      cellName:play()
      physics.addBody(cellName, "static")
      -- create the tree object
      tree = obstacleGrid[randomCell]
      tree.peeLevel = 0
      -- tree.name = 'tree'..t
      table.insert(treeGrid, tree)  -- save it in the treeGrid to keep track
      table.remove(obstacleGrid, randomCell)            -- remove so it can't be chooosen again
      actualTrees = actualTrees + 1
     --[[  for k,v in pairs(treeGrid[table.maxn(treeGrid)]) do
        print( k,v )
      end ]]
    end
  end
end

local function pee(event)
  tree = treeGrid[1]
  tree.minPeeLevel = minPeeLevel --assign pee lvl from the lvl properties
  if (event.phase == "began") then
    buttonPressed[event.target.name] = true
    player:setSequence("pee")
    player:play()
  elseif (event.phase == "ended") then
    buttonPressed[event.target.name] = false
    player:setSequence("walkingDown")
    player:play()
    player:pause()
  end
end

local function decresePeeLevel()

end

local function createThePlayer()
    -- Create the sprite
    local imageSheet = graphics.newImageSheet(dogSrc, sheetOptions)
    player = display.newSprite(imageSheet, sequenceData)
    player.x = gridMatrix[centerHoriz][centerVert].xPos
    player.y = gridMatrix[centerHoriz][centerVert].yPos
    player.name = 'player'
    player:setSequence("walkingDown")
    player.objectType = player
    physics.addBody(player, "dynamic", bodyOptions)
    --physics.addBody(player)
end

function showDirectionPad()
    upBtn = display.newRect(display.contentWidth -
                                (padButtonDimension - padButtonDimension / 2),
                            display.contentHeight -
                                (2 * padButtonDimension + padButtonDimension / 4),
                            padButtonDimension, padButtonDimension)
    upBtn:setFillColor(0, 0, 0)
    upBtn.name = "Up"
    upBtn:addEventListener("touch", move)

    downBtn = display.newRect(display.contentWidth -
                                  (padButtonDimension - padButtonDimension / 2),
                              display.contentHeight -
                                  (padButtonDimension - padButtonDimension / 4),
                              padButtonDimension, padButtonDimension)
    downBtn.name = "Down"
    downBtn:addEventListener("touch", move)

    leftBtn = display.newRect(display.contentWidth -
                                  (2 * padButtonDimension - padButtonDimension /
                                      4), display.contentHeight -
                                  (2 * padButtonDimension - padButtonDimension /
                                      2), padButtonDimension, padButtonDimension)
    leftBtn:setFillColor(0.8, 0.2, 0.3)
    leftBtn.name = "Left"
    leftBtn:addEventListener("touch", move)

    rightBtn = display.newRect(display.contentWidth +
                                   (padButtonDimension - padButtonDimension / 4),
                               display.contentHeight -
                                   (2 * padButtonDimension - padButtonDimension /
                                       2), padButtonDimension,
                               padButtonDimension)
    rightBtn:setFillColor(0.2, 0.9, 0.9)
    rightBtn.name = "Right"
    rightBtn:addEventListener("touch", move)

    peeBtn = display.newRect(80, 350, padButtonDimension,
                               padButtonDimension)
    peeBtn:setFillColor(0.6, 0.1, 0.4)
    peeBtn.name = "Pee"
    peeBtn:addEventListener("touch", pee)
end

function move(event)
    if (event.phase == "began") then
        buttonPressed[event.target.name] = true
        walkAnimation = "walking" .. event.target.name
        player:setSequence(walkAnimation)
        player:play()
    elseif (event.phase == "ended") then
        buttonPressed[event.target.name] = false
        player:pause()
    end
end

local function onLocalCollision( self, event )
  if (event.phase == "began" ) then
    --print(self.name)
    print(event)
    --[[ for k,v in pairs(event.target) do
        print( k,v )
      end ]]
    --print( self.name .. ": collision began with " .. event.other.name )
  elseif ( event.phase == "ended" ) then
    --print( self.name .. ": collision ended with " .. event.other.name )
  end
end

local function frameUpdate()
    player.collision = onLocalCollision
    player:addEventListener( "collision" )
    if buttonPressed['Down'] == true and player.y <
      -- (screenHeight - heightFrame / 4) then
      (gridRows * heightFrame) - heightFrame/2 then
      player.y = player.y + velocity
    elseif buttonPressed['Up'] == true and player.y >
      --(0 + heightFrame / 4) then
      (0 + heightFrame) then
      player.y = player.y - velocity
    elseif buttonPressed['Right'] == true and player.x <
      --(screenWidth + widthFrame / 4) then
      (gridCol * widthFrame) then
      player.x = player.x + velocity
    elseif buttonPressed['Left'] == true and player.x >
        --(0 - widthFrame / 4) then
      (0 + widthFrame) then
      player.x = player.x - velocity
    end
end

local function visualizeDebuggingInfo()
  treeText = 'tree'
  if debugOn == true then
    display.newText(treeText, 15, 15)
  end
end

-- GAME
Runtime:addEventListener("enterFrame", frameUpdate) -- if the move buttons are pressed MOVE!
randomWalkPath()
showDirectionPad()
createObstacles()
transformObstaclesIntoTrees()
createThePlayer()

--[[
local composer = require "composer"

-- Removes status bar on iOS
display.setStatusBar( display.HiddenStatusBar )

-- Removes bottom bar on Android
if system.getInfo( "androidApiLevel" ) and system.getInfo( "androidApiLevel" ) < 19 then
  native.setProperty( "androidSystemUiVisibility", "lowProfile" )
else
  native.setProperty( "androidSystemUiVisibility", "immersiveSticky" )
end

-- reserve audio for menu, bgsound, and wheels
audio.reserveChannels(3)

-- are we running on a simulator?
local isSimulator = "simulator" == system.getInfo( "environment" )
local isMobile = ("ios" == system.getInfo("platform")) or ("android" == system.getInfo("platform"))

-- if we are load our visual monitor that let's a press of the "F"
-- key show our frame rate and memory usage, "P" to show physics
if isSimulator then

  -- show FPS
  local visualMonitor = require( "com.ponywolf.visualMonitor" )
  local visMon = visualMonitor:new()
  visMon.isVisible = false

  -- show/hide physics
  local function debugKeys( event )
    local phase = event.phase
    local key = event.keyName
    if phase == "up" then
      if key == "p" then
        physics.show = not physics.show
        if physics.show then
          physics.setDrawMode( "hybrid" )
        else
          physics.setDrawMode( "normal" )
        end
      elseif key == "f" then
        visMon.isVisible = not visMon.isVisible
      end
    end
  end
  Runtime:addEventListener( "key", debugKeys )
end


-- this module turns gamepad axis events and mobile accelometer events
-- into keyboard events so we don't have to write separate code
-- for joystick and keyboard control
require("com.ponywolf.joykey").start()

-- add virtual buttons to mobile
system.activate("multitouch")
if isMobile or isSimulator then
  local vjoy = require "com.ponywolf.vjoy"
  local right = vjoy.newButton("scene/game/img/ui/wheelButton.png", "right")
  local left = vjoy.newButton("scene/game/img/ui/footButton.png", "left")
  local jump = vjoy.newButton("scene/game/img/ui/jumpButton.png", "space")
  right.x, right.y = display.screenOriginX + 256 + 32, display.screenOriginY + display.contentHeight - 96
  left.x, left.y =  display.screenOriginX + 128,display.screenOriginY + display.contentHeight - 96 - 32
  jump.x, jump.y = -display.screenOriginX + display.contentWidth - 128, display.screenOriginY + display.contentHeight - 96
  right.xScale, right.yScale = 0.5, 0.5
  left.xScale, left.yScale = 0.5, 0.5
  jump.xScale, jump.yScale = 0.5, 0.5
end

-- go to menu screen
--composer.gotoScene( "scene.menu", { params={ } } )
composer.gotoScene( "scene.game", { params={ } } )
-- uncomment to delete hiscores
--system.deletePreferences( "app", { "scores" } )








 ]]

--[[
-- 0 SETTINGS
local function initializeSettings()
    print('test')
    -- Hide the status bar, enable multitouch
    display.setStatusBar(display.HiddenStatusBar)
    system.activate("multitouch")

    -- "Constants"
    local W = display.contentWidth / 2;
    local H = display.contentHeight / 2;

    -- Set the background color to green
    local background = display.newRect(W, H, 2.5*W, 2*H)
    background:setFillColor( 0.5, 0.6, 0.3 )

    _G.padButtonDimension = 30

    showDirectionPad()

    -- Set up the physics world
    local physics = require("physics")
    physics.start()
    physics.setDrawMode( "hybrid" )
    physics.setGravity(0, 0)
    physics.setDrawMode("normal") -- Enable drawing mode for testing, you can use "normal", "debug" or "hybrid"
end

local function loadingVisualization()
    -- Create a new text field using native device font
    local loadingText = display.newText("The dog is drinking...", 0, 0, native.systemFont, 16 * 2)
    loadingText.xScale = 0.5
    loadingText.yScale = 0.5

    -- Change the center point to bottom left
    --loadingText:setReferencePoint(display.BottomLeftReferencePoint)

    -- Place the text on screen
    loadingText.x = _W / 2 - 210
    loadingText.y = _H - 20
end

local function initializeVariables()

    tilesWidth = 10

    -- 4. Number of balloons variable
    balloons = 0

    -- 5. How many balloons do we start with?
    numBalloons = 100

    startTime = 20
    totalTime = 20         -- 7. Total amount of time
    timeLeft = true        -- 8. Is there any time left?
    velocity = tilesWidth

    -- 9. Ready to play?
    playerReady = false

    -- 10. Generate math equation for randomization
    Random = math.random

    -- 11. Load background music
    -- local music = audio.loadStream("sounds/music.mp3")

    -- 12. Load balloon pop sound effect
    -- local balloonPop = audio.loadSound("sounds/balloonPop.mp3")

    -- Create a new text field to display the timer
    --local timeText = display.newText("Time: "..startTime, 0, 0, native.systemFont, 16*2);
    --timeText.xScale = 0.5
    --timeText.yScale = 0.5;
    --timeText:setReferencePoint(display.BottomLeftReferencePoint);
    --timeText.x = _W / 2;
    --timeText.y = _H - 20;
end

-- 1 MOVE PLAYER
-- 1.1 createPlayer(), function
-- 1.2 coerceOnScreen(), function

local function createPlayer()

    _G.player = display.newImage( "assets/img/dog.png", 0, 0 )
    player.x = display.contentCenterX
    player.y = display.contentCenterY
    --player.alpha = 0.8

    local playerCollisionFilter = {categoryBits = 2, maskBits = 5}
    local playerBodyElement = {filter = playerCollisionFilter}

    player.isBullet = true
    player.objectType = "player"
    physics.addBody(player, "dynamic", playerBodyElement)
    player.isSleepingAllowed = false

    return player
end

-- Forces the object to stay within the visible screen bounds.
local function coerceOnScreen(object)
    if object.x < object.width then object.x = object.width end
    if object.x > display.viewableContentWidth - object.width then
        object.x = display.viewableContentWidth - object.width
    end
    if object.y < object.height then object.y = object.height end
    if object.y > display.viewableContentHeight - object.height then
        object.y = display.viewableContentHeight - object.height
    end
end

function showDirectionPad()

    upBtn = display.newRect(
        display.contentWidth - (padButtonDimension - padButtonDimension/2),
        display.contentHeight - (2*padButtonDimension + padButtonDimension/4),
        padButtonDimension, padButtonDimension);
    upBtn:setFillColor(0,0,0)
	upBtn.name = "up";
    upBtn:addEventListener("tap", move);

    downBtn = display.newRect(
        display.contentWidth - (padButtonDimension - padButtonDimension/2),
        display.contentHeight - (padButtonDimension - padButtonDimension/4),
        padButtonDimension, padButtonDimension);
    downBtn.name = "down";
    downBtn:addEventListener("tap", move);

    leftBtn = display.newRect(
        display.contentWidth - (2*padButtonDimension - padButtonDimension/4),
        display.contentHeight - (2*padButtonDimension - padButtonDimension/2),
        padButtonDimension, padButtonDimension);
    leftBtn:setFillColor(0.8,0.2,0.3)
	leftBtn.name = "left";
    leftBtn:addEventListener("tap", move);

    rightBtn = display.newRect(
        display.contentWidth + (padButtonDimension - padButtonDimension/4),
        display.contentHeight - (2*padButtonDimension - padButtonDimension/2),
        padButtonDimension, padButtonDimension);
    rightBtn:setFillColor(0.2,0.9,0.9)
    rightBtn.name = "right";
	rightBtn:addEventListener("tap", move);
end

function move(event)

    if event.target.name == "down" then
    player.y = player.y + velocity
    end
    if event.target.name == "up" then
    player.y = player.y - velocity
    end
    if event.target.name == "right" then
    player.x = player.x + velocity
    end
    if event.target.name == "left" then
    player.x = player.x - velocity
    end

end

initializeSettings()
initializeVariables()
createPlayer()
 ]]
