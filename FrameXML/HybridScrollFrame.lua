--[[-----------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------]]--

local round = function (num) return math.floor(num + .5); end

function HybridScrollFrame_OnLoad (self)
	self:EnableMouse(true);
end

function HybridScrollFrame_OnValueChanged (self, value)
	HybridScrollFrame_SetOffset(self, value);
	
	self.scrollUp:Enable();
	self.scrollDown:Enable();

	local minVal, maxVal = self.scrollBar:GetMinMaxValues();
	if ( value >= maxVal ) then		
		if ( self.scrollDown ) then
			self.scrollDown:Disable()
		end
		val = maxVal;
	end
	if ( value <= minVal ) then
		if ( self.scrollUp ) then
			self.scrollUp:Disable();
		end
		val = minVal;
	end
end

function HybridScrollFrame_OnMouseWheel (self, delta, stepSize)
	if ( not self.scrollBar:IsVisible() ) then
		return;
	end
	
	local minVal, maxVal = 0, self.range;
	stepSize = stepSize or self.stepSize or self.buttonHeight;
	if ( delta == 1 ) then
		self.scrollBar:SetValue(max(minVal, self.scrollBar:GetValue() - stepSize));
	else
		self.scrollBar:SetValue(min(maxVal, self.scrollBar:GetValue() + stepSize));
	end
end

function HybridScrollFrameScrollButton_OnUpdate (self, elapsed)
	self.timeSinceLast = self.timeSinceLast + elapsed;
	if ( self.timeSinceLast >= ( self.updateInterval or 0.08 ) ) then
		if ( not IsMouseButtonDown("LeftButton") ) then
			self:SetScript("OnUpdate", nil);
		elseif ( MouseIsOver(self) ) then
			local parent = self.parent or self:GetParent():GetParent();
			HybridScrollFrame_OnMouseWheel (parent, self.direction, (self.stepSize or parent.buttonHeight/3));
			self.timeSinceLast = 0;
		end
	end
end

function HybridScrollFrameScrollButton_OnClick (self, button, down)
	local parent = self.parent or self:GetParent():GetParent();
	
	if ( down ) then
		self.timeSinceLast = (self.timeToStart or -0.2);
		self:SetScript("OnUpdate", HybridScrollFrameScrollButton_OnUpdate);
		HybridScrollFrame_OnMouseWheel (parent, self.direction);
		PlaySound("UChatScrollButton");
	else
		self:SetScript("OnUpdate", nil);
	end
end

function HybridScrollFrame_Update (self, numElements, totalHeight, displayedHeight)
	local range = totalHeight - self:GetHeight();
	if ( range > 0 and self.scrollBar ) then
		local minVal, maxVal = self.scrollBar:GetMinMaxValues();
		if ( math.floor(self.scrollBar:GetValue()) >= math.floor(maxVal) ) then
			self.scrollBar:SetMinMaxValues(0, range)
			if ( math.floor(self.scrollBar:GetValue()) ~= math.floor(range) ) then
				self.scrollBar:SetValue(range);
			else
				HybridScrollFrame_SetOffset(self, range); -- If we've scrolled to the bottom, we need to recalculate the offset.
			end
		else
			self.scrollBar:SetMinMaxValues(0, range)
		end
		self.scrollBar:Show();
	elseif ( self.scrollBar ) then
		self.scrollBar:SetValue(0);
		self.scrollBar:Hide();
	end
	
	self.numElements = numElements;
	self.range = range;
	self.scrollChild:SetHeight(displayedHeight);
	self:UpdateScrollChildRect();
end

function HybridScrollFrame_GetOffset (self)
	return math.floor(self.offset or 0), (self.offset or 0);
end

function HybridScrollFrameScrollChild_OnLoad (self)
	self:GetParent().scrollChild = self;
end

function HybridScrollFrame_ExpandButton (self, offset, height)
	self.largeButtonTop = round(offset);
	self.largeButtonHeight = round(height)
end

function HybridScrollFrame_CollapseButton (self)
	self.largeButtonTop = nil;
	self.largeButtonHeight = nil;
end

function HybridScrollFrame_SetOffset (self, offset)
	local buttons = self.buttons
	local buttonHeight = self.buttonHeight;
	local element, overflow;
	
	local scrollHeight = 0;
	
	local largeButtonTop = self.largeButtonTop
	if ( largeButtonTop and offset >= largeButtonTop ) then
		local largeButtonHeight = self.largeButtonHeight;
		-- Initial offset...
		element = largeButtonTop / buttonHeight;
			
		if ( offset >= (largeButtonTop + largeButtonHeight) ) then
			element = element + 1;
			
			local leftovers = (offset - (largeButtonTop + largeButtonHeight) );
			
			element = element + ( leftovers / buttonHeight );
			overflow = element - math.floor(element);
			scrollHeight = overflow * buttonHeight;
		else
			scrollHeight = math.abs(offset - largeButtonTop);		
		end
	else	
		element = offset / buttonHeight
		overflow = element - math.floor(element);
		scrollHeight = overflow * buttonHeight;
	end
	
	if ( math.floor(self.offset or 0) ~= math.floor(element) and self.update ) then
		self.offset = element;
		self.update();
	else
		self.offset = element;
	end
	
	self:SetVerticalScroll(scrollHeight);
end

function HybridScrollFrame_CreateButtons (self, buttonTemplate, initialOffsetX, initialOffsetY, initialPoint, initialRelative, offsetX, offsetY, point, relativePoint)
	assert(self and buttonTemplate);
	
	local scrollChild = self.scrollChild;
	local button, buttonHeight, buttons, numButtons;
	
	local buttonName = self:GetName() .. "Button";
	
	initialPoint = initialPoint or "TOPLEFT";
	initialRelative = initialRelative or "TOPLEFT";
	point = point or "TOPLEFT";
	relativePoint = relativePoint or "BOTTOMLEFT";
	offsetX = offsetX or 0;
	offsetY = offsetY or 0;
	
	if ( self.buttons ) then
		buttons = self.buttons;
		buttonHeight = buttons[1]:GetHeight();
	else
		button = CreateFrame("BUTTON", buttonName .. 1, scrollChild, buttonTemplate);
		buttonHeight = button:GetHeight();
		button:SetPoint(initialPoint, scrollChild, initialRelative, initialOffsetX, initalOffsetY);
		buttons = {}
		tinsert(buttons, button);
	end
	
	self.buttonHeight = round(buttonHeight);
	
	local numButtons = (self:GetHeight() / buttonHeight) + 1;
	self.overflow = math.ceil(numButtons) - numButtons;
	numButtons = math.ceil(numButtons);
	
	for i = #buttons + 1, numButtons do
		button = CreateFrame("BUTTON", buttonName .. i, scrollChild, buttonTemplate);
		button:SetPoint(point, buttons[i-1], relativePoint, offsetX, offsetY);
		tinsert(buttons, button);
	end
	
	scrollChild:SetWidth(self:GetWidth())
	scrollChild:SetHeight(numButtons * buttonHeight);
	self:SetVerticalScroll(0);
	self:UpdateScrollChildRect();
	
	self.buttons = buttons;
	scrollBar = self.scrollBar;	
	scrollBar:SetMinMaxValues(0, numButtons * buttonHeight)
	scrollBar:SetValueStep(.005);
	scrollBar:SetValue(0);
end