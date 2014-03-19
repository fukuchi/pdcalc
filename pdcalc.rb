#!/usr/bin/ruby2.0

require 'csv'
require './cell'

$cell_w = 100
$cell_h = 50
$margin_x = 20
$margin_y = 20

@cells = CSV.read(ARGV[0])
@cellsidx = {}
@cellsidx_head = 0
@links = []

def pdobj(cnum, rnum, type, body)
	x = cnum * $cell_w + $margin_x
	y = rnum * $cell_h + $margin_y
	@cellsidx[[cnum, rnum]] = @cellsidx_head
	@cellsidx_head += 1
	"#X #{type} #{x} #{y} #{body};\r\n"
end

def pdconnect(srcid, destid)
	"#X connect #{srcid} 0 #{destid} 0;\r\n"
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
				funcname = m[1]
				args = m[2].split(",")
				args.each {|dest|
					print pdobj(cnum, rnum, "obj", funcname)
					destcell = address_to_index(dest)
					@links << [[cnum, rnum], destcell]
				}
			else
				print pdobj(cnum, rnum, "msg", entry)
			end
		ensure
			cnum += 1
		end
	}
	rnum += 1
}

@links.each {|link|
	destid = @cellsidx[link[0]];
	srcid = @cellsidx[link[1]];
	if srcid.nil? or destid.nil?
		puts "Undefined object is reffered at #{index_to_address(link[0])}"
	else
		print pdconnect(srcid, destid)
	end
}
