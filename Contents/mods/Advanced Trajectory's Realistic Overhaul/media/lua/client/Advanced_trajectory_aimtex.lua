require "Advanced_trajectory_core"


Advanced_trajectory.panel = ISPanel:derive("Advanced_trajectory.panel")


function Advanced_trajectory.panel:initialise()
	ISPanel.initialise(self);
end

function Advanced_trajectory.panel:noBackground()
	self.background = false;
end

function Advanced_trajectory.panel:close()
	self:setVisible(false);
end


--************************************************************************--
--** ISPanel:render
--**
--************************************************************************--
function Advanced_trajectory.panel:prerender()
	-- if self.background then
	-- 	self:drawRectStatic(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
	-- 	self:drawRectBorderStatic(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
	-- end

    local posx = getMouseX() - self.width/2
    local posy = getMouseY() - self.height/2

    self:setX(posx)
    self:setY(posy)

    local multiper = Advanced_trajectory.aimnum*3 
    if multiper < 14 then 
        multiper = 14
    end


    -- -- getMouseX()
    -- -- getMouseY()

    -- print(getMouseX(),"   ",getMouseY())

    local texturescal = 14

    -- texturescal = 14/(texturescal/multiper)

    local AR,AG,AB = 1,1,1
    AR,AG,AB = getSandboxOptions():getOptionByName("Advanced_trajectory.crosshairRedMain"):getValue(), getSandboxOptions():getOptionByName("Advanced_trajectory.crosshairGreenMain"):getValue() , getSandboxOptions():getOptionByName("Advanced_trajectory.crosshairBlueMain"):getValue() 

    if Advanced_trajectory.aimnum <= 4 then
        AR,AG,AB = getSandboxOptions():getOptionByName("Advanced_trajectory.crosshairRed"):getValue(), getSandboxOptions():getOptionByName("Advanced_trajectory.crosshairGreen"):getValue() , getSandboxOptions():getOptionByName("Advanced_trajectory.crosshairBlue"):getValue() 
    end

    local transparency = Advanced_trajectory.alpha

    -- causes shaky effect with drunk, maybe best paired with panic or stress
    self:drawTextureScaled(self.texturetable[1], (self.width/2 -texturescal/2) - ZombRand(Advanced_trajectory.stressEffect),            (self.height/2 - multiper- texturescal/2)  - ZombRand(Advanced_trajectory.stressEffect), texturescal, texturescal, transparency,AR, AG, AB)
    self:drawTextureScaled(self.texturetable[2], (self.width/2 +multiper -texturescal/2) + ZombRand(Advanced_trajectory.stressEffect) , (self.height/2 -texturescal/2)  + ZombRand(Advanced_trajectory.stressEffect),            texturescal, texturescal, transparency, AR, AG, AB)
    self:drawTextureScaled(self.texturetable[3], (self.width/2  -texturescal/2) - ZombRand(Advanced_trajectory.stressEffect),           (self.height/2 + multiper-texturescal/2) - ZombRand(Advanced_trajectory.stressEffect),  texturescal, texturescal, transparency, AR, AG, AB)
    self:drawTextureScaled(self.texturetable[4], (self.width/2 -multiper -texturescal/2) - ZombRand(Advanced_trajectory.stressEffect),  (self.height/2-texturescal/2)  - ZombRand(Advanced_trajectory.stressEffect),           texturescal, texturescal, transparency, AR, AG, AB)
 
    

end

function Advanced_trajectory.panel:onMouseUp(x, y)
    if not self.moveWithMouse then return; end
    if not self:getIsVisible() then
        return;
    end

    self.moving = false;
    if ISMouseDrag.tabPanel then
        ISMouseDrag.tabPanel:onMouseUp(x,y);
    end

    ISMouseDrag.dragView = nil;
end

function Advanced_trajectory.panel:onMouseUpOutside(x, y)
    if not self.moveWithMouse then return; end
    if not self:getIsVisible() then
        return;
    end

    self.moving = false;
    ISMouseDrag.dragView = nil;
end

function Advanced_trajectory.panel:onMouseDown(x, y)
    if not self.moveWithMouse then return true; end
    if not self:getIsVisible() then
        return;
    end
    if not self:isMouseOver() then
        return -- this happens with setCapture(true)
    end
    
    self.downX = x;
    self.downY = y;
    self.moving = true;
    self:bringToTop();
end

function Advanced_trajectory.panel:onMouseMoveOutside(dx, dy)
    if not self.moveWithMouse then return; end
    self.mouseOver = false;

    if self.moving then
        if self.parent then
            self.parent:setX(self.parent.x + dx);
            self.parent:setY(self.parent.y + dy);
        else
            self:setX(self.x + dx);
            self:setY(self.y + dy);
            self:bringToTop();
        end
    end
end

function Advanced_trajectory.panel:onMouseMove(dx, dy)
    if not self.moveWithMouse then return; end
    self.mouseOver = true;

    if self.moving then
        if self.parent then
            self.parent:setX(self.parent.x + dx);
            self.parent:setY(self.parent.y + dy);
        else
            self:setX(self.x + dx);
            self:setY(self.y + dy);
            self:bringToTop();
        end
        --ISMouseDrag.dragView = self;
    end
end

--************************************************************************--
--** ISPanel:new
--**
--************************************************************************--
function Advanced_trajectory.panel:new (x, y, width, height)

    
	local o = {}
	--o.data = {}
	o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
	o.x = x;
	o.y = y;
	o.background = false;
	o.backgroundColor = {r=0, g=0, b=0, a=0};
    o.borderColor = {r=0, g=0, b=0, a=0};
    o.width = 0;
	o.height = 0;
	o.anchorLeft = false;
	o.anchorRight = false;
	o.anchorTop = false;
	o.anchorBottom = false;
    o.moveWithMouse = false;
    o.keepOnScreen = false;
    o.texturetable = {
        getTexture("media/textures/Aimingtex1.png"),
        getTexture("media/textures/Aimingtex2.png"),
        getTexture("media/textures/Aimingtex3.png"),
        getTexture("media/textures/Aimingtex4.png")
    }
   return o
end



