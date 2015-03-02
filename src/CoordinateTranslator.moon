class CoordinateTranslator

	windowPointToVideo: ( x, y ) =>
		newX = (x - @offsetX)/@scaleX
		newY = (y - @offsetY)/@scaleY
		return newX, newY

	windowBoundsToVideo: ( bounds ) =>
		l = (bounds.l - @offsetX)/@scaleX
		t = (bounds.t - @offsetY)/@scaleY
		r = (bounds.r - @offsetX)/@scaleX
		b = (bounds.b - @offsetY)/@scaleY

		return Bounds l, t, r, b

	unscaledMousePosition: =>
		x, y = mp.get_mouse_pos!
		return x*@mScaleX, y*@mScaleY

	mouseOverVideo: ( x, y ) =>
		return (x >= @offsetX) and (x < @edgeX) and (y >= @offsetY) and (y < @edgeY)

	videoPointToWindow: ( x, y ) =>
		newX = x*@scaleX + @offsetX
		newY = y*@scaleY + @offsetY
		return newX, newY

	videoBoundsToWindow: ( bounds ) =>
		l = bounds.l*@scaleX + @offsetX
		t = bounds.t*@scaleY + @offsetY
		r = bounds.r*@scaleX + @offsetX
		b = bounds.b*@scaleY + @offsetY

		return Bounds l, t, r, b

	setMouseScale: ( winW, winH ) =>
		@mScaleX = winW/@osdResX
		@mScaleY = winH/@osdResY

	update: ( winW, winH ) =>
		@setMouseScale winW, winH

		ml, mt, mr, mb = mp.get_screen_margins!
		vidW = mp.get_property_number "video-params/dw", 1
		vidH = mp.get_property_number "video-params/dh", 1

		dispW = winW - (ml + mr)
		dispH = winH - (mt + mb)

		@scaleX  = dispW/vidW
		@scaleY  = dispH/vidH
		@offsetX = ml
		@offsetY = mt
		@edgeX   = winW - mr
		@edgeY   = winH - mb
