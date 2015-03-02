#!/usr/bin/env ruby
# This should probably not be a ruby script, but I hate shell.

# The files must be ordered properly for references to work.
moonSources = [
	'src/log.moon',

	'src/Bounds.moon',
	'src/TimeRange.moon',
	'src/CoordinateTranslator.moon',
	'src/URL.moon',
	'src/URLManager.moon',

	'src/main.moon'
]

# Test for moonscript compile errors (this does not guarantee there
# won't be lua compile errors)
buildCount = 0
`mkdir -p .build`
moonSources.each do |sourceFile|
	output = ".build/#{sourceFile}.lua"
	if File.exists?( output ) && File.stat( output ) > File.stat( sourceFile )
		next
	end
	# This doesn't eat stderr
	`moonc -o #{output} #{sourceFile}`
	# Abort on error.
	if $?.exitstatus != 0
		exit 1
	end
	# test lua bytecode too.
	# `luajit -b #{output} #{output}.luac`
	# if $?.exitstatus != 0
	# 	exit 1
	# end
	buildCount += 1
end

if buildCount > 0
	# Compile the sources together.
	tempScript = 'url-overlay-temp.moon'
	`cat #{moonSources.join ' '} > #{tempScript}`
	`moonc -o url-overlay.lua #{tempScript}`
	`rm #{tempScript}`
else
	puts "Nothing to do."
end
