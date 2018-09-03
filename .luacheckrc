std = "lua51"

files["spec/*.lua"] = {
	std = "+busted"
}

-- prevent max line lengths
max_code_line_length = false
max_string_line_length = false
max_comment_line_length = false
