class Bounds
	@fromBounds: ( bounds ) =>
		return @ bounds.l, bounds.t, bounds.r, bounds.b

	new: ( @l, @t, @r, @b ) =>
		@l, @r = @r, @l if @r < @l
		@t, @b = @b, @t if @b < @t

	scale: ( factor ) =>
		return if 1 == factor
		@l = @l*factor
		@t = @t*factor
		@r = @r*factor
		@b = @b*factor

	ASS = {
		[[{\an7\pos(0,0)\bord3\3c&H0000FF&\1a&HFF&\p1}m ]]
		[[]]
	}
	toASS: =>
		ASS[2] = ([[%d %d l %d %d %d %d %d %d]])\format @l, @t, @r, @t, @r, @b, @l, @b
		return table.concat ASS

	containsPoint: ( x, y ) =>
		return ((x >= @l) and (y >= @t) and (x < @r) and (y < @b))
