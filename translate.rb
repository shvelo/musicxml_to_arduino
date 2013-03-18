#!/usr/bin/env ruby

require 'nokogiri'

exit 0 if ARGV.length < 1 || !File.exists?(ARGV[0])

file = File.open ARGV[0]

doc = Nokogiri::XML file

notes = []
durations = []

i = 0

doc.search('note').each do |note|
	break if i > 2000

	note_name = note.search("step").inner_text
	note_name += "S" if note.search("alter").inner_text == "1"
	note_name += note.search("octave").inner_text
	if note_name.length > 0 then
		notes.push note_name.upcase
		
		x_duration = note.search("duration").inner_text

		type = note.search("type").inner_text
		case type
			when "whole"
				duration = 1000
			when "half"
				duration = 1000 / 2
			when "quarter"
				duration = 1000 / 4
			when "eighth"
				duration = 1000 / 8
			else
				duration = 1000
		end
		
		duration = x_duration if x_duration.to_i < duration.to_i

		durations.push duration.to_s
	end

	i += 1
end



output = "int notes[] = {"
notes.each do |note|
	output += "NOTE_" + note + ","
end
output += "};\n"

output += "int durations[] = {"
durations.each do |duration|
	duration = "0" if duration.length < 1
	output += duration + ","
end
output += "};\n"

output += "int melody_size = #{notes.length};\n"

time = doc.search "time"

beats = time.search("beats").inner_text.to_i
beat_type = time.search("beat-type").inner_text.to_i

pause_mult = (1.0 / beats) + 1
output += "float pause_mult = #{pause_mult};\n"

out = File.open "melody.txt", "w"
out.write output
out.close

sketch = File.read "source.txt"
sketch["!!MELODY!!"] = output

out = File.open "musicxml_to_arduino.ino", "w"
out.write sketch
out.close