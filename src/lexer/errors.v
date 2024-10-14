module lexer

struct ErrorFileIO  implements IError {
	Error
	path string
}

fn (err ErrorFileIO) msg() string {
	return "Failed to open path: ${err.path}."
}

struct ErrorMissingExpectedSymbol implements IError {
	Error
	expected string
	found string 
}

fn (err ErrorMissingExpectedSymbol) msg() string {
	return "Was expecting ${err.expected}, but found ${err.found}."
}

struct ErrorUnexpectedToken implements IError {
	Error
	token string
}

fn (err ErrorUnexpectedToken) msg() string {
	return "There was an unexpected token: ${err.token}"
}

struct ErrorUseOfMultipleFloatPoints implements IError {
	Error
}

fn (err ErrorUseOfMultipleFloatPoints) msg() string {
	return "Attempting the use of multiple floating points \".\" in number."
}

struct ErrorUnexpectedEOF implements IError {
	Error
}

fn (err ErrorUnexpectedEOF) msg() string {
	return "Unexpected End of File"
}