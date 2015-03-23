export script_name        = "Url Overlay Generator"
export script_description = "Turns special tags into url overlays."
export script_author      = "torque"
export script_version     = "0.1.0"

json = require 'json'
ASSInspector = require 'SubInspector.Inspector'

local myInspector
urlPlaceholder = "\3%d\3"
urlPattern     = "\3(%d+)\3"

-- This is designed to use table references as confusingly as possible.
conjoinRects = ( rects, times, start, results, url ) ->
	lastRect = results[#results]
	-- finish is the index of the last visible rect.
	finish = start + 1
	for i = finish, #rects
		rect = rects[i]
		if rect
			with lastRect.bounds
				unless rect.x == .x and rect.y == .y and rect.w == .w and rect.h == .h
					time = times[i]
					-- takes care of the rect on top of the results table.
					if next lastRect.bounds
						lastRect.stop = time
						lastRect.bounds = { l: .x, t: .y, r: .x + .w, b: .y + .h }
					-- pushes a new rect onto the results table.
					lastRect = { start: time, bounds: rect, :url }
					table.insert results, lastRect
			finish = i + 1
		else
			-- takes care of the rect currently at the top of the results
			-- table if it hasn't already been taken care of.
			if next lastRect.bounds
				lastRect.stop = times[i]
				with lastRect.bounds
					lastRect.bounds = { l: .x, t: .y, r: .x + .w, b: .y + .h }
			lastRect = { bounds: { } }

	return finish

-- This function finds bounds of subsections in lines by wrapping all
-- uninteresting sections of the line in \alpha&HFF&. In this case,
-- uninteresting sections are defined as "not in the current \x-url
-- section".
collectBounds = ( line ) ->
	i = 0
	blockIndex = 0
	urls = { }
	blockIndices = { }
	tokenizedText = line.text\gsub "({.-})", ( block ) ->
		blockIndex += 1
		count = 0
		matches = { }
		-- handle tags with provided urls.
		block = block\gsub "\\x%-url%((.-)%)", ( url ) ->
			count += 1
			matches[count] = url
			return urlPlaceholder\format count
		-- handle tags without provided urls.
		block = block\gsub "\\x%-url", ->
			count += 1
			matches[count] = false
			return urlPlaceholder\format count
		-- clean up.
		j = 0
		block = block\gsub urlPattern, ( idx ) ->
			j += 1
			if j == count
				idx = tonumber idx
				i += 1
				urls[i] = matches[idx]
				blockIndices[i] = blockIndex
				return urlPlaceholder\format i
			else
				return ""

		return block

	line.assi_exhaustive = true
	rawLine = line.raw\sub( 1, -(#line.text + 1) ) .. '{\\alpha&HFF&}'
	blockCount = blockIndex
	results = { }
	for idx = 1, #urls
		if url = urls[idx]
			blockIndex = blockIndices[idx]
			nextBlockIndex = blockIndices[idx+1] or blockCount + 1
			currentBlock = 0
			-- might just abuse implementation details of ASSInspector
			-- (line.raw is what is used for the actual bounds checking, and
			-- nothing is done to verify that it has the same text as
			-- line.text).
			line.raw = rawLine .. tokenizedText\gsub "({.-)}", ( block ) ->
				currentBlock += 1
				if (currentBlock >= blockIndex) and (currentBlock < nextBlockIndex)
					block ..= "\\alpha&H00&}"
				else
					block ..= "\\alpha&HFF&}"
				return block

			checkLine = { k, v for k, v in pairs line}

			rects, times = myInspector\getBounds { checkLine }
			if nil == rects
				error times

			start = 1
			while false == rects[start]
				start += 1

			-- join identical bounding rects together.
			if start <= #rects
				firstRect = { }
				firstRect.bounds = rects[start]
				firstRect.start = times[start]
				firstRect.url = url
				table.insert results, firstRect
				finish = conjoinRects rects, times, start, results, url
				with results[#results]
					.stop = times[finish] or checkLine.end_time
					.bounds = { l: .bounds.x, t: .bounds.y, r: .bounds.x + .bounds.w, b: .bounds.y + .bounds.h }
					.url = url

	return results

generate = ( sub ) ->
	myInspector = ASSInspector sub
	collection = { }
	meta       = { }
	for x = 1, #sub
		line = sub[x]
		if "info" == line.class
			meta[line.key] = line.value
		elseif "dialogue" == line.class
			found = false
			line.text\gsub "{(.-)}", ( block ) ->
				unless found
					if block\match "\\x%-url"
						found = true

			if found
				line.index = x
				table.insert collection, line

	bounds = { }
	i = 0
	for line in *collection
		for urlBound in *collectBounds line
			i += 1
			-- insert for sorting.
			urlBound.i = i
			urlBound.layer = line.layer
			urlBound.start /= 1000
			urlBound.stop /= 1000

			table.insert bounds, urlBound

	if #bounds > 0
		-- have to sort bounds here so that lines with multiple urls and
		-- multiple rects end up with the urls properly interleaved.
		table.sort bounds, ( a, b ) ->
			if a.start == b.start
				return a.i < b.i
			else
				return a.start < b.start

		-- don't want to write the index field to the resulting json.
		for bound in *bounds
			bound.i = nil

		aegisub.log json.encode {
			resX: meta.PlayResX
			resY: meta.PlayResY
			events: bounds
		}

aegisub.register_macro "Generate URL Overlay", script_description, generate
