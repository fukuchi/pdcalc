#!/usr/bin/ruby2.0

require 'csv'
require './cell'

$cell_w = 80
$cell_h = 50
$margin_x = 20
$margin_y = 20

if ARGV.length == 0
	puts "Usage: pdcalc.rb CSVFILE"
	exit
end

@cells = CSV.read(ARGV[0])
@cellsidx = {}
@cellsidx_head = 0
@links = []

class String
	def numeric?
		Float(self) != nil rescue false
	end
end

def pdobj(cnum, rnum, type, *body)
	x = cnum * $cell_w + $margin_x
	y = rnum * $cell_h + $margin_y
	@cellsidx[[cnum, rnum]] = @cellsidx_head
	@cellsidx_head += 1
	"#X #{type} #{x} #{y} #{body.join(" ")};\r\n"
end

def pdconnect(srcid, destid, destinlet = 0)
	destinlet = 0 if destinlet.nil?
	"#X connect #{srcid} 0 #{destid} #{destinlet};\r\n"
end

print "#N canvas 0 0 800 600 10;\r\n"

rnum = 0
@cells.each {|row|
	cnum = 0
	row.each {|entry|
		begin
			next if entry.nil?
			if entry =~ /^=/
				m = entry.match(/^=([^(]+)\(([^)]+)\)/)
				if m.nil?
					m = entry.match(/^=(.*)/)
					if m[1].numeric?
						print pdobj(cnum, rnum, "floatatom", "5 0 0 0 - - -" )
					else
						print pdobj(cnum, rnum, "msg", m[1])
					end
				else 
					funcname = m[1]
					if funcname == "signal"
						tokens = m[2].split(/([+\-*\/])/)
						if tokens[0].numeric?
							print pdobj(cnum, rnum, "obj", tokens[1]+"~", tokens[0])
							@links << [[cnum, rnum], address_to_index(tokens[2])]
						else
							print pdobj(cnum, rnum, "obj", tokens[1]+"~")
							@links << [[cnum, rnum, 0], address_to_index(tokens[0])]
							@links << [[cnum, rnum, 1], address_to_index(tokens[2])]
						end
					else
						args = m[2].split(",")
						args.each {|sexp|
							print pdobj(cnum, rnum, "obj", funcname)
							sexp.split('+').each {|src|
								srccell = address_to_index(src)
								@links << [[cnum, rnum], srccell]
							}
						}
					end
				end
			else
				case entry.split(" ")[0]
				when "hslider"
					type = "obj"
					body = entry.sub(/\Ahslider\s+([0-9]+)\s+([0-9]+)/, 'hsl 128 15 \1 \2')
				else
					type = "msg"
					body = entry
				end
				print pdobj(cnum, rnum, type, body)
			end
		ensure
			cnum += 1
		end
	}
	rnum += 1
}

@links.each {|link|
	destid = @cellsidx[link[0].slice(0, 2)];
	destinlet = link[0][2]
	srcid = @cellsidx[link[1]];
	if srcid.nil? or destid.nil?
		puts "Undefined object is reffered at #{index_to_address(link[0])}"
	else
		print pdconnect(srcid, destid, destinlet)
	end
}
