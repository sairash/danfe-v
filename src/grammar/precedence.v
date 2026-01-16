module grammar

pub const precedence = {
	"*": 9,
	"/": 9,
	"%": 9,
	"+": 8,
	"-": 8,
	"<<": 7, // Bitwise Left Shift
	">>": 7, // Bitwise Right Shift
	"&": 6, // Bitwise And
	"^": 5, // Bitwise XOR
	"==": 4,
	"!=": 4,
	"<": 4,
	"<=": 4,
	">": 4,
	">=": 4,
	"&&": 3,
	"||": 2,
}

