local M = {}
local composer = require "composer"
local color = require "com.ponywolf.ponycolor"

local sheetOptions = {
    --required parameters
    width = 52,
    height = 71,
    numFrames = 12,
    --optional parameters; used for scaled content support
    --sheetContentWidth = 156,  -- width of original 1x size of entire sheet
    --sheetContentHeight = 281   -- height of original 1x size of entire sheet
}
local sequenceData =
{
    { name="walkingDown", start=1, count=3, time=100, loopCount = 0, loopDirection = "forward"},
    --[[ { name="walkingLeft", start=4, count=6, time=100, loopCount = 0, loopDirection = "forward"},
    { name="walkingRight", start=7, count=9, time=100, loopCount = 0, loopDirection = "forward"},
    { name="walkingUp", start=10, count=12, time=100, loopCount = 0, loopDirection = "forward"}, ]]
}

-- temp var
--local imgSrc = "scene/game/img/brown.png"

--function M.new(instance, imgSrc, imageSheetOptions, sequenceOption )
function M.new(instance, imgSrc)
print(imgSrc)
  local scene = composer.getScene(composer.getSceneName("current"))
  --local dog = display.newImageRect(instance.parent, "scene/game/img/brown.png", 52, 71)

  -- To create a sprite you first need an imageSheet and options detailing how many frames there are
  local imageSheet = graphics.newImageSheet(imgSrc, sheetOptions)
  print(imageSheet)
  -- Then you set the sprite with the right image sheet and sequence data positioned on screen
  myAnimation = display.newSprite(imageSheet, sequenceData )
  myAnimation.x = display.contentWidth/2 ; myAnimation.y = display.contentHeight/2

  function instance:walkUp()
    myAnimation:setSequence( "walkingUp" )
    myAnimation:play()
  end

--[[
  function instance:walkUp()
    local myAnimation = display.newSprite(imageSheet, sequenceData)
    myAnimation.x = display.contentWidth/2 ; myAnimation.y = display.contentHeight/2
    myAnimation:play()
  end ]]


  -- Create a sprite
  -- Create a sequence with the option for the animation
  -- Create Example assumes 'imageSheet' is already created from graphics.newImageSheet()


  --[[ local frame = 0
  function instance:animate(board, vx, vy)
    if vy < 0 then vy = 0 end
    if not self.wrecked then
      self.x, self.y = board.x, board.y -64 - (vy / 33) + math.abs(board.rotation/4)
      top.rotation = self.rotation + board.rotation / 6
      bottom.rotation = self.rotation + board.rotation / 3
      frame = frame + 0.25 -- head bob
    end
    top.x, top.y = self.x, self.y + (math.sin(frame) * 1.5) - 1
    bottom.x, bottom.y = self.x, self.y
  end

  function instance:reset()
    physics.removeBody(self)
    self.rotation = 0
    self.wrecked = false
  end

  function instance:collision(event)
    if event.other.isGround and self.linearDamping < 3.0 then
      audio.play(scene.sounds.thud)
      audio.play(scene.sounds.ouch)
      self.linearDamping = 3.0
    end
  end
  function instance:crash(vx, vy)
    if not self.wrecked then
      self.wrecked = true
      audio.play(scene.sounds.thud)
      physics.addBody(self, { bounce = 0, radius = 32, friction = 1 , filter= { groupIndex = -1 } } )
      self:setLinearVelocity(vx ,vy)
      transition.to (top, { rotation = 70, time = 666, transition = easing.outQuad })
      transition.to (bottom, { rotation = 105, time = 333, transition = easing.outQuad })
      self:addEventListener("collision")
    end
  end ]]

  return instance
end

return M
