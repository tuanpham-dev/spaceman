local spaces = require('spaces')
local spaceIndicator = require('space-indicator')

spaces.insertRemoveSpaceCallback = spaceIndicator.render
spaces.init()
spaceIndicator.init()