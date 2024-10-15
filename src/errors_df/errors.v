module errors_df

pub struct ErrorFileIO  implements IError {
	Error
	pub mut:
	path string
}

fn (err ErrorFileIO) msg() string {
	return "Failed to open path: ${err.path}."
}

pub struct ErrorMismatch implements IError {
	Error
	pub mut:
	expected string
	found string 
}

fn (err ErrorMismatch) msg() string {
	return "Was expecting ${err.expected}, but found ${err.found}."
}

pub struct ErrorUnexpectedToken implements IError {
	Error
	pub mut:
	token string
}

fn (err ErrorUnexpectedToken) msg() string {
	return "There was an unexpected token: ${err.token}"
}

pub struct ErrorUseOfMultipleFloatPoints implements IError {
	Error
}

fn (err ErrorUseOfMultipleFloatPoints) msg() string {
	return "Attempting the use of multiple floating points \".\" in number."
}

pub struct ErrorUnexpectedEOF implements IError {
	Error
}

fn (err ErrorUnexpectedEOF) msg() string {
	return "Unexpected End of File"
}

pub struct ErrorUnexpected implements IError {
	Error
}

fn (err ErrorUnexpected) msg() string {
	return "Unexpected Error In the compiler. Raise an Issue in Github"
}
