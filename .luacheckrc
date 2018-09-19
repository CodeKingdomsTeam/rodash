std = "lua51"

files["spec/*.lua"] = {
	std = "+busted"
}

ignore = {
	"212", -- Unused argument.
	"213", -- Unused loop variable.
	"423", -- Shadowing a loop variable.
	"431", -- Shadowing an upvalue.
	"432" -- Shadowing an upvalue argument.
}

-- prevent max line lengths
max_code_line_length = false
max_string_line_length = false
max_comment_line_length = false
