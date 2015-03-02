utils = require "mp.utils"

open_osx = ( urlString ) -> utils.subprocess { args: { "open", urlString } }
open_windows = ( urlString ) -> utils.subprocess { args: { "start", urlString } }
open_linux = ( urlString ) -> utils.subprocess { args: { "xdg-open", urlString } }

class URL
	clickAction = nil
	if true
		if "Windows_NT" == os.getenv "OS"
			clickAction = open_windows
		else
			uname = utils.subprocess { args: { "uname", "-s" } }
			if uname.stdout\match "Darwin"
				clickAction = open_osx
			elseif uname.stdout\match "Linux"
				clickAction = open_linux

	new: ( start, stop, @bounds, @urlString ) =>
		@time = TimeRange start, stop

	hoverASS = {
		[[{\an1\fs40\\pos(]],
		[[-100,-100]]
		[[)}]]
		[[]]
	}
	toHoverASS: ( winW, winH ) =>
		hoverASS[2] = ("%g,%g")\format 10, winH - 10
		hoverASS[4] = @urlString
		return table.concat hoverASS

	click: =>
		clickAction @urlString
