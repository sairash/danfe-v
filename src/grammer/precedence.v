module grammer

enum PrecedenceValue {
	lowest
	equals
	or_op
	and
	less_greater
	bit_and
	bit_or
	bit_shift
	add
	multiply
	prefix
}

pub const precedence = {
	"*": PrecedenceValue.multiply,
	"/": PrecedenceValue.multiply,
	"%": PrecedenceValue.multiply,
	"+": PrecedenceValue.add,
	"-": PrecedenceValue.add,
	"<<": PrecedenceValue.bit_shift, // Bitwise Left Shift
	">>": PrecedenceValue.bit_shift, // Bitwise Right Shift
	"&": PrecedenceValue.bit_and, // Bitwise And
	"^": PrecedenceValue.bit_or, // Bitwise XOR
	"==": PrecedenceValue.less_greater,
	"!=": PrecedenceValue.less_greater,
	"<": PrecedenceValue.less_greater,
	"<=": PrecedenceValue.less_greater,
	">": PrecedenceValue.less_greater,
	">=": PrecedenceValue.less_greater,
	"&&": PrecedenceValue.and,
	"||": PrecedenceValue.or_op,
}

