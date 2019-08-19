-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
-- this module turns gamepad axis events and mobile accelometer events
-- into keyboard events so we don't have to write separate code
-- for joystick and keyboard control

-- REQUIRE
local physics = require "physics"
physics.start()
-- physics.setGravity( 0,0 )
physics.setDrawMode( "hybrid" )

-- GAME VARS
local levelVars = {
  {lvl = 1, trees = 5, minPeeLevel = 0.2, vanishingPee = 1.5, minutes = 2, pathTracerMoves = 300},
  {lvl = 2, trees = 5, minPeeLevel = 0.2, vanishingPee = 1.5, minutes = 2, pathTracerMoves = 300},
  {lvl = 3, trees = 6, minPeeLevel = 0.3, vanishingPee = 1.5, minutes = 2, pathTracerMoves = 300},
  {lvl = 4, trees = 6, minPeeLevel = 0.3, vanishingPee = 1, minutes = 2, pathTracerMoves = 300}
}

-- TILES VARS
local obstaclesSrc = "scene/game/img/tiles/"
local obstacles = {'flower','rock','tree'}
local widthFrame, heightFrame = 50, 50 --dimensions of the tiles on screen
local gridRows, gridCols
local gridMatrix = {}
local obstacleGrid = {}


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
  totalLevelTrees = levelVars[1].trees

  -- find the grid dimensions
  gridCols = math.floor(display.contentWidth / widthFrame)
  gridRows = math.floor(display.contentHeight / heightFrame)
  centerHoriz = math.floor(gridRows/2)
  centerVert = math.floor(gridCols/2)
  print(gridRows..' '..gridCols)
end

local function createSingleTile(classTile, xPos, yPos, row, col)
  myImage = display.newImage(obstaclesSrc..classTile..'.png')
  myImage.anchorX = 1 --anchor on the bottom right corner
  myImage.anchorY = 1
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
      gridMatrix[i][j] = createSingleTile('grass', j * widthFrame, i * heightFrame, i, j)
      printPairs(gridMatrix[i][j])
    end
  end
end

-- Create the walking path in a graphic way (TO BE DEFINED BEFORE THE WALKING ALGORITHM)
local function openPath(rowNumber, colNumber)
    -- choose the random tile and save it in the grid to remember it
    randomPath = 'path'..math.random(4)
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
        cell = createSingleTile('flower3', j * widthFrame, i * heightFrame, i, j) -- all obstacles have grass background
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
  if obstacleGrid[randomCell].type == 'tree1' or
     obstacleGrid[randomCell].type == 'tree2' or
     obstacleGrid[randomCell].type == 'tree3' or
     obstacleGrid[randomCell].type == 'tree4' then
      return true
     else
    return false
     end
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
      cell = createSingleTile(randomTree, localCol * widthFrame, localRow * heightFrame, localRow, localCol)
      obstacleGrid[randomCell] = cell
      -- set the current cell as tree
      obstacleGrid[randomCell].type = randomTree
      physics.addBody(cell, "static")

      -- create the tree object
      tree = obstacleGrid[randomCell]
      tree.peeLevel = 0

    end
  end
end

-- GAME
initLevelSettings()
createTheGrid()
randomWalkPath()
createObstacles()
transformObstaclesIntoTrees()
