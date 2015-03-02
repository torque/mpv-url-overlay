class URLManager
	@fromJSON: ( json ) =>
		result = utils.parse_json json
		if result
			return @ result
		else
			msg.warn "JSON parse error."
			return nil, "JSON parse error."

	new: ( URLData ) =>
		@urls = { }
		@showUrlBoxes = false
		@urlBoxesShown = false
		@currentTime = 0
		@lastIndex = 1
		@activeURLs = { }
		@activeWindowBounds = { }
		@activeCount = 0

		vidW = mp.get_property_number "video-params/dw", 1
		vidH = mp.get_property_number "video-params/dh", 1
		assert vidW/vidH == URLData.resX/URLData.resY, "The video aspect ratio does not match that of the URLData. Dying."
		scale = vidW/URLData.resX

		winW, winH = mp.get_screen_size!
		@translator = CoordinateTranslator!
		@updateOSD winW, winH, ""
		@translator\update winW, winH

		for x = 1, #URLData.events
			url = URLData.events[x]
			bounds = Bounds\fromBounds url.bounds
			bounds\scale scale
			@urls[x] = URL url.start, url.stop, bounds, url.string

		-- loop for hover effects and showing link location.
		timer = mp.add_periodic_timer 0.05, @\update
		-- todo: add handlers for pause killing the loop? probably not
		-- because urls should be clickable when paused.
		@paused = mp.get_property_bool 'pause', false
		mp.observe_property 'pause', 'bool', ( event, paused ) ->
			@paused = paused

		mp.add_key_binding 'TAB', 'mp_url_overlay_show', ( event ) ->
			switch event.event
				when "up"
					@showUrlBoxes = false
				when "down"
					@showUrlBoxes = true,
			{ complex: true }

		mp.add_key_binding "MOUSE_BTN0", "mp_url_overlay_click", ->
			@update!
			mX, mY = @translator\unscaledMousePosition!
			if @translator\mouseOverVideo mX, mY
				@handleClick mX, mY

		mp.register_event "seek", ->
			time = mp.get_property_number "time-pos", 0
			if time < @currentTime
				@currentTime = time
				@lastIndex = 1

	updateOSD: ( w, h, string ) =>
		@translator.osdResX = w
		@translator.osdResY = h
		@translator\setMouseScale w, h
		mp.set_osd_ass w, h, string

	-- Ranges must be contiguous, but that's required by the URLData
	-- schema anyway.
	getUrlsForTime: ( time ) =>
		startIndex = false
		endIndex = false
		for x = @lastIndex, #@urls
			url = @urls[x]
			switch url.time\timeInRange time
				when 0
					startIndex = x unless startIndex
				when -1
					endIndex = x - 1
					break

		endIndex = #@urls if startIndex and not endIndex
		-- if startIndex is false, nothing was found.
		if startIndex
			@lastIndex = startIndex
		return startIndex, endIndex

	update: =>
		winW, winH = mp.get_screen_size!
		changed = @urlBoxesShown != @showUrlBoxes
		if (winW != @winW or winH != @winH)
			changed = true
			@translator\update winW, winH
			for x = 1, @activeCount
				@activeWindowBounds[x] = @translator\videoBoundsToWindow @activeURLs[x].bounds

			@winW, @winH = winW, winH

		if not @paused
			@currentTime = mp.get_property_number "time-pos", 0
			startIndex, endIndex = @getUrlsForTime @currentTime
			if startIndex and (startIndex != @lastStart or endIndex != @lastEnd)
				changed = true
				@lastStart, @lastEnd = startIndex, endIndex
				@activeCount = endIndex - startIndex + 1
				@activeURLs = { }
				@activeWindowBounds = { }
				for x = 1, @activeCount
					url = @urls[x + startIndex - 1]
					@activeURLs[x] = url
					@activeWindowBounds[x] = @translator\videoBoundsToWindow url.bounds

			elseif @activeCount > 0 and not startIndex
				changed = true
				@activeCount = 0
				@lastStart = false

		ass = { }
		hovered = @handleHover!
		if hovered
			@hovered = true
			table.insert ass, hovered
		elseif @hovered
			@hovered = false
			changed = true

		if changed or @hovered
			@urlBoxesShown = @showUrlBoxes
			if @showUrlBoxes
				for x = 1, @activeCount
					table.insert ass, @activeWindowBounds[x]\toASS!

			@updateOSD @winW, @winH, table.concat ass, '\n'

	handleHover: =>
		mX, mY = @translator\unscaledMousePosition!
		for x = @activeCount, 1, -1
			if @activeWindowBounds[x]\containsPoint mX, mY
				return @activeURLs[x]\toHoverASS @winW, @winH

		return false

	handleClick: ( mX, mY ) =>
		for x = @activeCount, 1, -1
			if @activeWindowBounds[x]\containsPoint mX, mY
				@activeURLs[x]\click!
				break

