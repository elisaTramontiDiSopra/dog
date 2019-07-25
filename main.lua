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
  right.x, right.y = display.screenOriginX + 256 + 32, display.screenOriginY + display.contentHeight - 96
  left.x, left.y =  display.screenOriginX + 128,display.screenOriginY + display.contentHeight - 96 - 32
  jump.x, jump.y = -display.screenOriginX + display.contentWidth - 128, display.screenOriginY + display.contentHeight - 96
  right.xScale, right.yScale = 0.5, 0.5
  left.xScale, left.yScale = 0.5, 0.5
  jump.xScale, jump.yScale = 0.5, 0.5
end






local composer = require "composer"
local physics = require "physics"

-- game var
local padButtonDimension = 30 -- GAMEPAD
local buttonPressed = {Down = false, Up = false, Left = false, Right = false}
local widthFrame, heightFrame = 52, 71
local velocity = 5

-- Image and sprite options for dog
local dogSrc = "scene/game/img/caracters/brownDog.png"
local sheetOptions = {width = widthFrame, height = heightFrame, numFrames = 12}
local sequenceData = {
    { name="walkingDown", start=1, count=3, time=100, loopCount = 0, loopDirection = "forward"},
    { name="walkingLeft", start=4, count=3, time=100, loopCount = 0, loopDirection = "forward"},
    { name="walkingRight", start=7, count=3, time=100, loopCount = 0, loopDirection = "forward"},
    { name="walkingUp", start=10, count=3, time=100, loopCount = 0, loopDirection = "forward"},}

-- Get the screen values
local screenWidth = display.viewableContentWidth
local screenHeight = display.viewableContentHeight

-- Create the sprite
local imageSheet = graphics.newImageSheet(dogSrc, sheetOptions)
local player = display.newSprite(imageSheet, sequenceData )
player.x = display.contentWidth/2 ;
player.y = display.contentHeight/2
player:setSequence( "walkingDown" )

function showDirectionPad()
  upBtn = display.newRect(display.contentWidth - (padButtonDimension - padButtonDimension/2),
        display.contentHeight - (2*padButtonDimension + padButtonDimension/4),
        padButtonDimension, padButtonDimension);
  upBtn:setFillColor(0,0,0)
	upBtn.name = "Up";
    upBtn:addEventListener("touch", move);

  downBtn = display.newRect(
    display.contentWidth - (padButtonDimension - padButtonDimension/2),
    display.contentHeight - (padButtonDimension - padButtonDimension/4),
    padButtonDimension, padButtonDimension);
  downBtn.name = "Down";
  downBtn:addEventListener("touch", move);

    leftBtn = display.newRect(
        display.contentWidth - (2*padButtonDimension - padButtonDimension/4),
        display.contentHeight - (2*padButtonDimension - padButtonDimension/2),
        padButtonDimension, padButtonDimension);
    leftBtn:setFillColor(0.8,0.2,0.3)
	leftBtn.name = "Left";
    leftBtn:addEventListener("touch", move);

    rightBtn = display.newRect(
        display.contentWidth + (padButtonDimension - padButtonDimension/4),
        display.contentHeight - (2*padButtonDimension - padButtonDimension/2),
        padButtonDimension, padButtonDimension);
    rightBtn:setFillColor(0.2,0.9,0.9)
    rightBtn.name = "Right";
    rightBtn:addEventListener( "touch", move )
end

function move(event)
  if ( event.phase == "began" ) then
    buttonPressed[event.target.name] = true
    walkAnimation = "walking"..event.target.name
    player:setSequence(walkAnimation)
    player:play()
  elseif ( event.phase == "ended" ) then
    buttonPressed[event.target.name] = false
    player:pause()
  end
end

local function frameUpdate()
  if buttonPressed['Down'] == true and player.y < (screenHeight - heightFrame/4) then
    player.y = player.y + velocity
  elseif buttonPressed['Up'] == true and player.y > (0 + heightFrame/4) then
    player.y = player.y - velocity
  elseif buttonPressed['Right'] == true and player.x < (screenWidth + widthFrame/4) then
    player.x = player.x + velocity
  elseif buttonPressed['Left'] == true and player.x > (0 - widthFrame/4) then
    player.x = player.x - velocity
  end
  --print(player.y)
end

-- GAME
Runtime:addEventListener( "enterFrame", frameUpdate ) --if the move buttons are pressed MOVE!
showDirectionPad()






























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
