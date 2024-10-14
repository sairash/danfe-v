module lexer

import os
import token

pub struct Process {
pub mut:
	x               i64
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

pub fn (l &Lex) next() !token.Token {
	mut cur_file_process := l.file_process[l.cur_file] or {
		return ErrorFileIO{
			path: l.cur_file
		}
	}

	cur_file_process.skip_whitespace() or {
		return token.Token{
			token_type: token.EOF{}
			range:      [cur_file_process.x]
		}
	}

	next_char := cur_file_process.consume_char() or {
		return token.Token{
			token_type: token.EOF{}
			range:      [cur_file_process.x]
		}
	}

	defer {
		unsafe {
			free(cur_file_process)
			free(next_char)
		}
	}

	return cur_file_process.change_to_token(next_char)!
}

// convert the given u8 to token type
fn (mut p Process) change_to_token(next_char u8) !token.Token {
	match next_char {
		`\n` {
			return token.Token{
				token_type: token.EOL{}
				range:      [p.get_x()]
			}
		}
		`(`, `[`, `{` {
			return p.match_punctuation(next_char, true)
		}
		`)`, `]`, `}` {
			return p.match_punctuation(next_char, false)
		}
		`;`, `,` {
			return token.Token{
				token_type: token.Seperator{}
				range:      [p.get_x()]
			}
		}
		`+`, `-`, `*`, `/`, `\\`, `%`, `=`, `|`, `&`, `<`, `>` {
			return p.match_operators(next_char, p.get_x())
		}
		`0`...`9` {
			return p.match_number(next_char, p.get_x())
		}
		`#` { // comment
			for {
				consume := p.consume_char() or { break }
				if consume == `\n` {
					break
				}
			}
			return token.Token{
				token_type: token.Comment{}
				range:      [p.get_x()]
			}
		}
		`a`...`z`, `A`...`Z` {
			return p.match_identifier(next_char, p.get_x())
		}
		`'`, `"` {
			return p.match_string(next_char, p.get_x())
		}
		else {
			return ErrorUnexpectedToken{
				token: next_char.ascii_str()
			}
		}
	}
}

// Consume the current character
pub fn (mut p Process) consume_char() ?u8 {
	peek := p.peek() or { return none }
	if peek == `\n` {
		p.cur_col = 0
		p.cur_line += 1
	}

	p.x += 1
	p.cur_col += 1
	return peek
}

// skip all the whitespaces except \n
fn (mut p Process) skip_whitespace() ? {
	for {
		p.peek() or { return none }
		if p.file_data[p.x] == `\n` || !p.file_data[p.x].is_space() {
			break
		}
		p.consume_char()
	}
}

fn (p &Process) get_x() i64 {
	return p.x - 1
}

// Peek current character
fn (p &Process) peek() ?u8 {
	if p.x < p.file_len {
		return p.file_data[p.x]
	}

	return none
}

// go through a file
fn Lex.go_through_file(path string) !string {
	if os.is_file(path) == true {
		return os.read_file(path) or { return err }
	}

	return ErrorFileIO{
		path: path
	}
}

// Adds new file in the process of lexer
pub fn (mut l Lex) add_new_file_to_lex(path string, return_path string) ! {
	if path !in l.file_process {
		go_through_file_data := Lex.go_through_file(path)!
		l.file_process[path] = &Process{
			x:               0
			file_data:       go_through_file_data
			file_path:       path
			return_path:     return_path
			processed:       false
			file_len:        go_through_file_data.len
			cur_col:         1
			cur_line:        1
			bracket_balance: []
		}

		unsafe {
			free(go_through_file_data)
		}
	}
}

// Lexer Initializer
pub fn Lex.new(path string) !&Lex {
	mut lex := &Lex{
		cur_file:     path
		file_process: {}
	}

	lex.add_new_file_to_lex(path, '')!

	return lex
}
