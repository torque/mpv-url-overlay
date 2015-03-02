class TimeRange
	new: ( @start, @finish ) =>

	timeInRange: ( time ) =>
		if time <= @start
			return -1
		elseif time > @finish
			return 1
		else
			return 0
