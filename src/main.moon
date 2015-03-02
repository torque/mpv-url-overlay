initDraw = ->
	mp.unregister_event initDraw
	videoPath = mp.get_property "path", ""
	jsonPath = videoPath\sub(1, -4) .. "json"

	suburls = io.open jsonPath
	if not suburls
		log.warn "Could not find suburls: %s", jsonPath
		return

	json = suburls\read "*a"
	suburls\close!

	manager = URLManager\fromJSON json
	if not manager
		log.warn "Failed to create URLManager. Malformed JSON?"

fileLoaded = ->
	mp.register_event 'playback-restart', initDraw

mp.register_event 'file-loaded', fileLoaded
