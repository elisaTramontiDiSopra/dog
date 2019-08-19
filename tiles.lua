function obstacles:init(sheet, options, xloc, yloc, row )
    self.image = display.newSprite(sheet, options)
    self.image:setReferencePoint( CenterReferencePoint )
    self.image.x = xloc
    self.image.y = yloc
    self.image.name = "obstacle"
    self.peeLevel = 100
    self.minPeeLevel = 0.2
    self.movement =  0.5
    self.leftHit = 0
    self.rightHit = 0
    self.numberOfWallHits = 0
    self.floorHits = 0
end
