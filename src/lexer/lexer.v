module lexer

// import token
import os

pub struct Process {
pub mut:
	x               int
	cur_line        int
	cur_col         int
	file_data       string
	file_len        int
	processed       bool
	return_path     string
	file_path       string
	bracket_balance []u8
}

pub struct Lex {
pub mut:
	file_process map[string]&Process
	cur_file     string
}

const size = 1024 * 256

pub fn (l &Lex) next() {
}

pub fn (l &Lex) peek() !u8 {
	cur_file_process := l.file_process[l.cur_file] or { return error('Current file Not found') }

	defer {
		unsafe {
			free(cur_file_process)
		}
	}

	if cur_file_process.x <= cur_file_process.file_len {
		return cur_file_process.file_data[cur_file_process.x]
	}

	return error('End of File')
}

// go through a file
fn go_through_file(path string) !string {
	if os.is_file(path) == true {
		return os.read_file(path) or { return err }
	}

	return error('no file at the path: ${path}')
}

// Adds new file in the process of lexer
pub fn (mut l Lex) add_new_file_to_lex(path string, return_path string) ! {
	if path !in l.file_process {
		go_through_file_data := go_through_file(path)!
		l.file_process[path] = &Process{
			file_data:   go_through_file_data
			file_path:   path
			return_path: return_path
			processed:   false
			file_len:    go_through_file_data.len
		}

		unsafe {
			free(go_through_file_data)
		}
	}
}

// Lexer Initializer
pub fn new(path string) !&Lex {
	mut lex := &Lex{
		cur_file:     path
		file_process: {}
	}

	lex.add_new_file_to_lex(path, '')!

	return lex
}
