-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
-- this module turns gamepad axis events and mobile accelometer events
-- into keyboard events so we don't have to write separate code
-- for joystick and keyboard control

-- REQUIRE
local composer = require "composer"
local widget = require "widget"
local physics = require "physics"
physics.start()
physics.setGravity( 0,0 )
--physics.setDrawMode( "hybrid" )

-- GAME VARS
local maxPeeLevel, minPeeLevel, totalLevelTrees,peeVelocity, pathTracerMoves
local levelVars = {
  {lvl = 1, timerSeconds = 20, pathTracerMoves = 300, obstacleTile = 'flower', treeTile = 'tree', pathTile = 'path',
   trees = 5, minPeeLevel = 0.2, maxPeeLevel = 100, peeStream = 6, vanishingPee = 2},
  {lvl = 2, timerSeconds = 180, trees = 5, minPeeLevel = 0.2, maxPeeLevel = 100, peeStream = 5, vanishingPee = 1.5, minutes = 2, pathTracerMoves = 300},
  {lvl = 3, timerSeconds = 180, trees = 6, minPeeLevel = 0.3, maxPeeLevel = 100, peeStream = 5, vanishingPee = 1.5, minutes = 2, pathTracerMoves = 300},
  {lvl = 4, timerSeconds = 180, trees = 6, minPeeLevel = 0.3, maxPeeLevel = 100, peeStream = 4, vanishingPee = 1, minutes = 2, pathTracerMoves = 300}
}

-- GAMEPAD
local padButtonDimension = 30
local buttonPressed = {Down = false, Up = false, Left = false, Right = false}

-- TIMER VARS
local tmr, timerText

-- TILES VARS
local obstaclesSrc = "scene/game/img/tiles/"
local obstacles = {'flower','rock','tree'}
local widthFrame, heightFrame = 50, 50 --dimensions of the tiles on screen
local anchorXPoint, anchorYPoint = 0.5, 0.5 -- anchor points for all the tiles created
local gridRows, gridCols
local gridMatrix = {}
local obstacleGrid = {}
local treeGrid = {}

-- PLAYER VARS
local player
local velocity = 5
local peeing = false
local collidedWith = {}
local playerSrc = "scene/game/img/caracters/mainDog.png"
local playerSheetOptions = {width = widthFrame, height = heightFrame, numFrames = 20}
local playerBodyOptions = {radius = 20} -- for adding a physics body, use circle or it wouldn't be realistic
local playerSequenceData = {
    {name = "walkingDown", start = 1, count = 4, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "walkingLeft", start = 5, count = 4, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "walkingRight", start = 9, count = 4, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "walkingUp", start = 13, count = 4, time = 100, loopCount = 0, loopDirection = "forward"},
    {name = "pee", start = 17, count = 4, time = 100, loopCount = 0, loopDirection = "forward"}
}

function printPairs(grid)
  for k,v in pairs(grid) do
    print( k,v )
  end
end

local function chooseRandomlyFromTable(tableName)
  return math.random(table.maxn(tableName))
end

local function initLevelSettings()
  pathTracerMoves = levelVars[1].pathTracerMoves
  timerSeconds = levelVars[1].timerSeconds

  obstacleTile = levelVars[1].obstacleTile
  treeTile = levelVars[1].treeTile
  pathTile = levelVars[1].pathTile

  totalLevelTrees = levelVars[1].trees
  peeStream = levelVars [1].peeStream
  maxPeeLevel = levelVars [1].maxPeeLevel
  minPeeLevel = levelVars[1].minPeeLevel
  vanishingPee = levelVars[1].vanishingPee

  -- find the grid dimensions
  gridCols = math.floor(display.contentWidth / widthFrame)
  gridRows = math.floor(display.contentHeight / heightFrame)
  centerHoriz = math.floor(gridRows/2)
  centerVert = math.floor(gridCols/2)
  print(centerHoriz..' '..centerVert)
end

local function createTimer()
  -- visualize text with a random text inside
  timerText = display.newText( "00:00", display.contentWidth - 50, 50, native.systemFont, 18 )
  timerText:setFillColor( 1, 1, 1 )
end

local function updateTime( event )
  -- Decrement the number of seconds
  timerSeconds = timerSeconds - 1
  -- Time is tracked in seconds; convert it to minutes and seconds
  local minutes = math.floor( timerSeconds / 60 )
  local seconds = timerSeconds % 60

  -- Make it a formatted string
  local timerDisplay = string.format( "%02d:%02d", minutes, seconds )

  -- Update the text object
  timerText.text = timerDisplay
end

local function createSingleTile(classTile, xPos, yPos, row, col)
  myImage = display.newImage(obstaclesSrc..classTile..'.png')
  myImage.anchorX = anchorXPoint --anchor on the bottom right corner
  myImage.anchorY = anchorYPoint
  myImage.x = xPos
  myImage.y = yPos
  myImage.row = row
  myImage.col = col
  myImage.obstacle = 1
  myImage.name = 'cell_'..row..'-'..col
  myImage.type = classTile
  return myImage
end

local function destroySingleTile(tile)
  display.remove(tile)
  tile = nil
end

local function createTheGrid()
  -- Populate the grid matrix for the level
  for i = 1, gridRows do
    gridMatrix[i] = {} -- create a new row
    for j = 1, gridCols do
      tile = obstacleTile..math.random(4)
      gridMatrix[i][j] = createSingleTile(tile, j * widthFrame, i * heightFrame, i, j)
    end
  end
end

-- Create the walking path in a graphic way (TO BE DEFINED BEFORE THE WALKING ALGORITHM)
local function openPath(rowNumber, colNumber)
    -- choose the random tile and save it in the grid to remember it
    randomPath = pathTile..math.random(4)
    -- remove old tile
    gridMatrix[rowNumber][colNumber]:removeSelf()
    gridMatrix[rowNumber][colNumber] = nil
    -- create the new image and save it on the grid
    cell = createSingleTile(randomPath, colNumber * widthFrame, rowNumber * heightFrame, rowNumber, colNumber)
    gridMatrix[rowNumber][colNumber] = cell
    gridMatrix[rowNumber][colNumber].obstacle = 0  -- set as path
    gridMatrix[rowNumber][colNumber].type = 'path'
end

-- Random walking algorithm, clearing the path
local function randomWalkPath()
  -- keep track of the grid coordinates to change from obstacle to path
  pathGridX = centerHoriz
  pathGridY = centerVert
  openPath(pathGridX, pathGridY) -- free the central cell
  for count = 1, pathTracerMoves, 1 do
    -- 1 choose a random number between 1 and 4 (the 4 directions)
    randomDirection = math.random(4)
    if (randomDirection == 1 and pathGridY > 1) then -- moveUp
      pathGridY = pathGridY - 1
    elseif (randomDirection == 2 and pathGridX > 1) then -- moveLeft
      pathGridX = pathGridX - 1
    elseif (randomDirection == 3 and pathGridX < gridRows) then -- moveRIght
      pathGridX = pathGridX + 1
    elseif (randomDirection == 4 and pathGridY < gridCols) then -- moveDown
      pathGridY = pathGridY + 1
    end
    openPath(pathGridX,pathGridY)
  end
end

-- Count the ramaining obstacles, add body to them and eventually select and create random trees
local function createObstacles()
  for i = 1, gridRows do
    for j = 1, gridCols do
      if (gridMatrix[i][j].obstacle == 1) then
        tile = obstacleTile..math.random(4)
        cell = createSingleTile(tile, j * widthFrame, i * heightFrame, i, j) -- all obstacles have grass background
        table.insert(obstacleGrid, cell)
        physics.addBody(cell, "static")
      end
    end
  end
end

-- function to determine if a cell is reachable, needed for transformObstaclesIntoTrees
local function checkIfReachable(r, c)
  --print('r '..r..' c '..c)
  r0 = r - 1
  r1 = r + 1
  c0 = c - 1
  c1 = c + 1
  reachable = 0

  if c1 <= gridCols and gridMatrix[r][c1].obstacle == 0 then
    reachable = reachable + 1
  end
  if r1 <= gridRows and gridMatrix[r1][c].obstacle == 0 then
    reachable = reachable + 1
  end
  if c0 > 0 and gridMatrix[r][c0].obstacle == 0 then
    reachable = reachable + 1
  end
  if r0 > 0 and gridMatrix[r0][c].obstacle == 0 then
    reachable = reachable + 1
  end
  if reachable > 0 then
    return true
  end
end

local function checkIfIsATree(cell)
  if cell == nil then
    return false
  end
  if cell and
     cell.type == 'tree' or
     cell.type == 'tree1' or
     cell.type == 'tree2' or
     cell.type == 'tree3' or
     cell.type == 'tree4' then
     return true
  else
    return false
  end
end

local function updateTreePeeBar(peeBar, peeLevel)
  peePerc = peeLevel / maxPeeLevel
  peeBar:setProgress(peePerc) -- percentage
end

local function visualizeTreePeeBar(xPos, yPos)
  peerBar = widget.newProgressView( {left = xPos, top = yPos, width = widthFrame, isAnimated = true} )
  peerBar:setProgress(0.0)
  return peerBar
end

local function transformObstaclesIntoTrees()
  actualTrees = 0
  while actualTrees < totalLevelTrees do
    randomCell = math.random(table.maxn(obstacleGrid))    -- choose a random cell
    -- check if it's close to path
    isReachable = checkIfReachable(obstacleGrid[randomCell].row, obstacleGrid[randomCell].col)
    alreadyChosenAsTree = checkIfIsATree(obstacleGrid[randomCell])
    if isReachable == true and alreadyChosenAsTree == false then
      actualTrees = actualTrees + 1
      -- substitute the cell with the new background
      randomTree = 'tree'..math.random(4)

      localRow = obstacleGrid[randomCell].row
      localCol = obstacleGrid[randomCell].col

      -- destroy the old cell image
      destroySingleTile(obstacleGrid[randomCell])
      obstacleGrid[randomCell] = nil
      destroySingleTile(gridMatrix[localRow][localCol])
      gridMatrix[localRow][localCol] = nil

      cell = createSingleTile(randomTree, localCol * widthFrame, localRow * heightFrame, localRow, localCol)
      obstacleGrid[randomCell] = cell
      gridMatrix[localRow][localCol] = cell

       -- add the pee loading bar
      peeBar = visualizeTreePeeBar(localCol * widthFrame - widthFrame / 2, localRow * heightFrame + heightFrame / 2, actualTrees)

      -- set the current cell as tree
      gridMatrix[localRow][localCol].type = 'tree'
      gridMatrix[localRow][localCol].peeLevel = 0
      gridMatrix[localRow][localCol].maxPeeLevel = maxPeeLevel
      gridMatrix[localRow][localCol].minPeeLevel = minPeeLevel
      gridMatrix[localRow][localCol].actualTrees = actualTrees --tree number
      gridMatrix[localRow][localCol].peeBar = peeBar

      -- add the current tree to a tree table
      table.insert(treeGrid, {row = localRow, col = localCol, number = actualTrees})

      --printPairs(gridMatrix[localRow][localCol])
      physics.addBody(gridMatrix[localRow][localCol], "static")

    end
  end
end

local function playerCollision(self, event)
  if (event.phase == "began" ) then
    if event.other.type == 'tree' then
      collidedWith = event.other
    else
      collidedWith.type = event.other.type
    end
  end
  return true --limit event propagation
end

function pee()
  if checkIfIsATree(collidedWith) then
    localRow = collidedWith.row
    localCol = collidedWith.col
    peeLevel = gridMatrix[localRow][localCol].peeLevel
    if peeLevel <= maxPeeLevel then
      gridMatrix[localRow][localCol].peeLevel = gridMatrix[localRow][localCol].peeLevel + peeStream
      updateTreePeeBar(gridMatrix[localRow][localCol].peeBar, gridMatrix[localRow][localCol].peeLevel)
      player:setSequence('pee')
      player:play()
    end
  else
    print("not a tree")
    collidedWith = nil
  end
end

local function createThePlayer()
  local imageSheet = graphics.newImageSheet(playerSrc, playerSheetOptions)
  player = display.newSprite(imageSheet, playerSequenceData)
  player.anchorX = anchorXPoint --anchor on the bottom right corner
  player.anchorY = anchorYPoint
  player.x = centerVert * heightFrame
  player.y = centerHoriz * widthFrame
  player.name = 'player'
  player:setSequence("walkingDown")
  player.objectType = player
  -- player collision
  player.collision = playerCollision
  player:addEventListener("collision", player)

  physics.addBody(player, "dynamic", playerBodyOptions)
end

local function move(event)
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

local function showDirectionPad()
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

local function checkIfLevelIsPassed()
  print("END")
end

local function frameUpdate()
  if timerSeconds == 0 then
    --checkIfLevelIsPassed()
  end

  player.rotation = 0 -- to prevent player from rotating if walking on an obstacle angle

  if buttonPressed['Down'] == true and player.y <
    (gridRows * heightFrame) - heightFrame/2 then
    --collidedWith = nil
    --collidedWith.type = 'empty'
    player.y = player.y + velocity
  elseif buttonPressed['Up'] == true and player.y >
    (0 + heightFrame) then
    --collidedWith = nil -- as soon as you move delete the last collision
    --collidedWith.type = 'empty'
    player.y = player.y - velocity
  elseif buttonPressed['Right'] == true and player.x <
    (gridCols * widthFrame) then
    --collidedWith = nil -- as soon as you move delete the last collision
    --collidedWith.type = 'empty'
    player.x = player.x + velocity
  elseif buttonPressed['Left'] == true and player.x >
    (0 + widthFrame) then
    --collidedWith = nil -- as soon as you move delete the last collision
    --collidedWith.type = 'empty'
    player.x = player.x - velocity
  end
end

-- GAME
Runtime:addEventListener("enterFrame", frameUpdate) -- if the move buttons are pressed MOVE!

initLevelSettings()
createTheGrid()
randomWalkPath()
createObstacles()
transformObstaclesIntoTrees()
createThePlayer()
showDirectionPad()
createTimer()

local countDownTimer = timer.performWithDelay( 1000, updateTime, timerSeconds)
local countDownPeeTimer = timer.performWithDelay( 1000, updatePeeLevels)
