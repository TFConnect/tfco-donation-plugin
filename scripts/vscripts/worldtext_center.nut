class Character
{
	function constructor(code_point, x, y, width, height, origin_x, origin_y, advance)
	{
		this.code_point = code_point
		this.x = x
		this.y = y
		this.width = width
		this.height = height
		this.origin_x = origin_x
		this.origin_y = origin_y
		this.advance = advance
	}
	
	code_point = null
	x = null
	y = null
	width = null
	height = null
	origin_x = null
	origin_y = null
	advance = null
}

class Font
{
	function constructor(name, size, bold, italic, width, height, char_count, chars)
	{
		this.name = name
		this.size = size
		this.bold = bold
		this.italic = italic
		this.width = width
		this.height = height
		this.char_count = char_count
		this.chars = chars
	}
	
	name = null
	size = null
	bold = null
	italic = null
	width = null
	height = null
	char_count = null
	chars = null
}

chars_TF2_Build <-
[
	Character(' ', 146, 238, 12, 12, 6, 6, 25),
	Character('!', 67, 182, 24, 56, 6, 50, 16),
	Character('"', 0, 238, 24, 24, 6, 54, 15),
	Character('#', 609, 182, 51, 50, 6, 47, 42),
	Character('$', 477, 182, 34, 54, 6, 49, 25),
	Character('%', 564, 182, 45, 51, 6, 47, 36),
	Character('&', 636, 0, 49, 58, 6, 50, 39),
	Character('\'', 1000, 182, 19, 25, 6, 54, 10), /* ' To fix syntax highlighter */
	Character('(', 118, 0, 34, 62, 6, 54, 25),
	Character(')', 152, 0, 34, 62, 6, 54, 25),
	Character('*', 861, 182, 34, 34, 6, 54, 25),
	Character('+', 782, 182, 36, 37, 6, 40, 27),
	Character(',', 978, 182, 22, 26, 6, 16, 12),
	Character('-', 70, 238, 32, 19, 6, 30, 23),
	Character('.', 24, 238, 23, 22, 6, 16, 14),
	Character('/', 373, 182, 36, 55, 6, 50, 27),
	Character('0', 91, 182, 52, 55, 6, 50, 43),
	Character('1', 409, 182, 32, 55, 5, 50, 25),
	Character('2', 239, 182, 46, 55, 6, 50, 37),
	Character('3', 192, 182, 47, 55, 6, 50, 37),
	Character('4', 143, 182, 49, 55, 6, 50, 41),
	Character('5', 330, 182, 43, 55, 6, 50, 34),
	Character('6', 0, 182, 40, 56, 6, 51, 30),
	Character('7', 285, 182, 45, 55, 6, 50, 36),
	Character('8', 961, 125, 45, 56, 6, 50, 36),
	Character('9', 873, 0, 42, 58, 6, 50, 32),
	Character(':', 760, 182, 22, 43, 6, 41, 14),
	Character(';', 738, 182, 22, 48, 6, 42, 13),
	Character('<', 660, 182, 39, 49, 6, 46, 30),
	Character('=', 895, 182, 39, 28, 6, 36, 29),
	Character('>', 699, 182, 39, 49, 6, 46, 30),
	Character('?', 294, 125, 47, 57, 6, 51, 38),
	Character('@', 511, 182, 53, 53, 6, 47, 44),
	Character('A', 596, 68, 54, 57, 6, 51, 45),
	Character('B', 341, 125, 47, 57, 6, 51, 38),
	Character('C', 534, 0, 51, 58, 6, 51, 42),
	Character('D', 486, 68, 55, 57, 6, 51, 46),
	Character('E', 102, 125, 48, 57, 6, 51, 39),
	Character('F', 150, 125, 48, 57, 6, 51, 39),
	Character('G', 916, 68, 51, 57, 6, 51, 43),
	Character('H', 258, 68, 57, 57, 6, 51, 48),
	Character('I', 915, 0, 26, 58, 4, 51, 18),
	Character('J', 709, 125, 39, 57, 6, 51, 30),
	Character('K', 529, 125, 46, 57, 6, 51, 37),
	Character('L', 748, 125, 39, 57, 6, 51, 32),
	Character('M', 142, 68, 58, 57, 6, 51, 49),
	Character('N', 967, 68, 51, 57, 6, 51, 42),
	Character('O', 186, 0, 59, 58, 6, 52, 50),
	Character('P', 685, 0, 47, 58, 6, 51, 38),
	Character('Q', 0, 0, 59, 68, 6, 51, 50),
	Character('R', 388, 125, 47, 57, 6, 51, 38),
	Character('S', 732, 0, 47, 58, 6, 51, 38),
	Character('T', 812, 68, 52, 57, 6, 51, 43),
	Character('U', 315, 68, 57, 57, 6, 51, 48),
	Character('V', 245, 0, 59, 58, 6, 52, 49),
	Character('W', 0, 68, 71, 57, 6, 51, 61),
	Character('X', 650, 68, 54, 57, 6, 51, 46),
	Character('Y', 422, 0, 56, 58, 6, 51, 47),
	Character('Z', 621, 125, 44, 57, 6, 51, 38),
	Character('[', 892, 125, 25, 57, 6, 51, 16),
	Character('\\', 441, 182, 36, 54, 6, 50, 27),
	Character(']', 917, 125, 25, 57, 6, 51, 16),
	Character('^', 818, 182, 43, 34, 6, 54, 34),
	Character('_', 102, 238, 44, 18, 6, 3, 35),
	Character('`', 47, 238, 23, 21, 6, 54, 10),
	Character('a', 704, 68, 54, 57, 6, 51, 45),
	Character('b', 435, 125, 47, 57, 6, 51, 38),
	Character('c', 585, 0, 51, 58, 6, 51, 42),
	Character('d', 541, 68, 55, 57, 6, 51, 46),
	Character('e', 198, 125, 48, 57, 6, 51, 39),
	Character('f', 246, 125, 48, 57, 6, 51, 39),
	Character('g', 0, 125, 51, 57, 6, 51, 43),
	Character('h', 372, 68, 57, 57, 6, 51, 48),
	Character('i', 941, 0, 26, 58, 4, 51, 21),
	Character('j', 787, 125, 39, 57, 6, 51, 30),
	Character('k', 575, 125, 46, 57, 6, 51, 37),
	Character('l', 826, 125, 39, 57, 6, 51, 30),
	Character('m', 200, 68, 58, 57, 6, 51, 49),
	Character('n', 51, 125, 51, 57, 6, 51, 42),
	Character('o', 304, 0, 59, 58, 6, 52, 50),
	Character('p', 779, 0, 47, 58, 6, 51, 38),
	Character('q', 59, 0, 59, 68, 6, 51, 50),
	Character('r', 482, 125, 47, 57, 6, 51, 38),
	Character('s', 826, 0, 47, 58, 6, 51, 38),
	Character('t', 864, 68, 52, 57, 6, 51, 43),
	Character('u', 429, 68, 57, 57, 6, 51, 48),
	Character('v', 363, 0, 59, 58, 6, 52, 49),
	Character('w', 71, 68, 71, 57, 6, 51, 61),
	Character('x', 758, 68, 54, 57, 6, 51, 46),
	Character('y', 478, 0, 56, 58, 6, 51, 47),
	Character('z', 665, 125, 44, 57, 6, 51, 38),
	Character('{', 40, 182, 27, 56, 6, 51, 18),
	Character('|', 942, 125, 19, 57, 0, 51, 16),
	Character('}', 865, 125, 27, 57, 6, 51, 18),
	Character('~', 934, 182, 44, 26, 6, 35, 34),
]

font_TF2_Build <- Font("TF2 Build", 64, 0, 0, 1024, 512, 95, chars_TF2_Build)
chars_size <- chars_TF2_Build.len() - 1

TextSizeOutWidth <- 0.0
TextSizeOutHeight <- 0.0

function CalcTextTotalSize(entity)
{
	TextSizeOutWidth = 0.0
	TextSizeOutHeight = 0.0

	local text = NetProps.GetPropString(entity, "m_szText")
	local text_len = text.len()
	if (text_len == 0)
		return

	local screen_size = NetProps.GetPropFloat(entity, "m_flTextSize")
	local screen_spacing_x = NetProps.GetPropFloat(entity, "m_flTextSpacingX")
	local screen_spacing_y = NetProps.GetPropFloat(entity, "m_flTextSpacingY")
	
	local font = font_TF2_Build
	local font_size = font.size
	local font_chars = font.chars
	local scale = screen_size / font_size.tofloat()
	local line_width = 0.0
	
	TextSizeOutHeight += font_size * scale
	for (local i = 0; i < text_len; i++)
	{
		local chr = text[i]
		local chr_idx = chr - 32
		if (chr_idx < 0)
			chr_idx = 0
		else if (chr_idx > chars_size)
			chr_idx = chars_size
		
		if (chr == '\n')
		{
			if (line_width >= TextSizeOutWidth)
				TextSizeOutWidth = line_width
			
			line_width = 0.0
			TextSizeOutHeight += (font_size + screen_spacing_y) * scale
			continue
		}
		
		local character = font_chars[chr_idx]
		line_width += (character.advance + screen_spacing_x) * scale
	}
	
	if (line_width >= TextSizeOutWidth)
		TextSizeOutWidth = line_width
}