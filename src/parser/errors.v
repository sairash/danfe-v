module parser

struct ErrorUnexpected implements IError {
	Error
}

fn (err ErrorUnexpected) msg() string {
	return "Unexpected Error In the compiler. Raise an Issue in Github"
}