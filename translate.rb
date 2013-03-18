#!/usr/bin/env ruby

require 'nokogiri'

exit 0 if ARGV.length < 1 || !File.exists?(ARGV[0])

file = File.open ARGV[0]

doc = Nokogiri::XML file

notes = []
durations = []
delays = []

i = 0

divisions = doc.search("divisions").inner_text.to_i

sound = doc.search("sound")
if sound.first then
	tempo = sound.first.attribute("tempo").to_i
else
	tempo = 120
end

quarter_note = 60.0  / tempo / divisions * 1000.0

delay = 0

doc.search('measure').each do |measure|

	rest = measure.css("rest").first

	if rest then
		delay = rest.parent.search("duration").inner_text.to_i
		delay = delay * quarter_note
	end

	measure.search('note').each do |note|
		break if i > 2000

		note_name = note.search("step").inner_text
		note_name += "S" if note.search("alter").inner_text == "1"
		note_name += note.search("octave").inner_text
		if note_name.length > 0 then
			notes.push note_name.upcase
			
			duration = note.search("duration").inner_text
			if duration.length > 0 then
				duration = duration.to_i * quarter_note
			else
				type = note.search("type").inner_text
				case type
					when "whole"
						duration = quarter_note * 4
					when "half"
						duration = quarter_note * 2
					when "quarter"
						duration = quarter_note
					when "eighth"
						duration = quarter_note / 2.0
					else
						duration = quarter_note * 4
				end
			end
			
			durations.push duration.to_s

			delays.push delay.to_s
		end

		i += 1
	end

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

output += "int delays[] = {"
delays.each do |delay|
	delay = "0" if delay.to_i < 1
	output += delay + ","
end
output += "};\n"

output += "int melody_size = #{notes.length};\n"

out = File.open "melody.txt", "w"
out.write output
out.close

sketch = File.read "source.txt"
sketch["!!MELODY!!"] = output

out = File.open "musicxml_to_arduino.ino", "w"
out.write sketch
out.close