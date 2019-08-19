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
-- physics.setDrawMode( "hybrid" )

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
local widthFrame, heightFrame = 50, 50
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
  print('gridCol '..gridCols)
  print('gridRows '..gridRows)
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
    end
  end
end

-- Create the walking path in a graphic way (TO BE DEFINED BEFORE THE WALKING ALGORITHM)
local function openPath(rowNumber, colNumber)
    -- choose the random tile and save it in the grid to remember it
    randomPath = 'path'..math.random(4)
    -- remove old tile
    --printPairs(gridMatrix[rowNumber][colNumber])
    gridMatrix[rowNumber][colNumber]:removeSelf()
    gridMatrix[rowNumber][colNumber] = nil
    --print('NIL '..gridMatrix[rowNumber][colNumber])
    -- create the new image and save it on the grid
    cell = createSingleTile(randomPath, colNumber * widthFrame, rowNumber * heightFrame, rowNumber, colNumber)
    gridMatrix[rowNumber][colNumber] = cell
    gridMatrix[rowNumber][colNumber].obstacle = 0  -- set as path
    gridMatrix[rowNumber][colNumber].type = 'path'
    print('row '..gridMatrix[rowNumber][colNumber].row..' col '..gridMatrix[rowNumber][colNumber].col)
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
    print('INPUT '..pathGridX..' '..pathGridY)
    openPath(pathGridX,pathGridY)
  end
end

-- Count the ramaining obstacles, add body to them and eventually select and create random trees
local function createObstacles()
  for i = 1, gridRows do
    for j = 1, gridCols do
      if (gridMatrix[i][j].obstacle == 1) then
        --print(gridMatrix[i][j].obstacle)
        cell = createSingleTile('tree', j * widthFrame, i * heightFrame, j, i) -- all obstacles have grass background
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

  -- check if the 4 direction are free (+1) or not (0)
    --[[ print(r0..' '..r..' '..r1)
    print(c0..' '..c..' '..c1)
    print(gridMatrix[r][c1].name)
    print(gridMatrix[r1][c].obstacle) ]]
    --print(r0)
  --[[ for r=1, gridRow do
    for c = 1, gridCol do
      for k,v in pairs(gridMatrix[r][c]) do
        print( k,v )
      end
    end
  end ]]

  --[[ if c1 <= gridCol and gridMatrix[r][c1].obstacle == 0 then
    reachable = reachable + 1
  end
  if r1 <= gridRow and gridMatrix[r1][c].obstacle == 0 then
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
  end ]]
  return true
end

local function transformObstaclesIntoTrees()
  actualTrees = 0
  for t = 1, totalLevelTrees do
    randomCell = math.random(table.maxn(obstacleGrid))    -- choose a random cell
    -- check if it's close to path
    isReachable = checkIfReachable(obstacleGrid[randomCell].row, obstacleGrid[randomCell].col)
    if isReachable == true and actualTrees < totalLevelTrees then
      -- substitute the cell with the new background
      randomTree = 'tree'..math.random(4)
      --print(randomTree)              -- choose a random frame
      localRow = obstacleGrid[randomCell].row
      localCol = obstacleGrid[randomCell].col

      cell = createSingleTile(randomTree, localRow * widthFrame, localCol * heightFrame, localRow, localCol)
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
--createObstacles()
--transformObstaclesIntoTrees()
--cell = createSingleTile('flower1', col * widthFrame, row * heightFrame, 7, 11)
