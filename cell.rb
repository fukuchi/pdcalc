def address_to_index(address)
	d = address.match(/([A-Z]+)([0-9]+)/)
	row = d[2].to_i
	column = 0
	chars = d[1].chars
	while c = chars.shift
		column *= 26
		column += c.ord - 64
	end
	[column - 1, row - 1]
end

def index_to_address(column, row)
	columnstr = ""
	column += 1
	while column > 0
		m = column % 26
		if m == 0
			m = 26
			column -= 26
		end
		columnstr = (m + 64).chr + columnstr
		column /= 26
	end
	columnstr + (row + 1).to_s
end
