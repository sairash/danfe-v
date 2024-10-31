module lexer

import os
import token
import errors_df

pub struct Lex {
pub mut:
	x               i64
	cur_line        int
	cur_col         int
	file_data       string
	file_len        int
	can_import      bool
	return_path     string
	file_path       string
	bracket_balance []u8
}

const size = 1024 * 256

pub fn (mut l Lex) next() !token.Token {
	l.skip_whitespace() or { return token.Token{
		token_type: token.EOF{}
		range:      [l.x]
	} }

	next_char := l.consume_char() or {
		return token.Token{
			token_type: token.EOF{}
			range:      [l.x]
		}
	}

	defer {
		unsafe {
			free(l)
			free(next_char)
		}
	}

	return l.change_to_token(next_char)!
}

// convert the given u8 to token type
fn (mut l Lex) change_to_token(next_char u8) !token.Token {
	match next_char {
		`\n` {
			return token.Token{
				token_type: token.EOL{}
				range:      [l.get_x()]
			}
		}
		`(`, `[`, `{` {
			l.can_import = false
			return l.match_punctuation(next_char, true)
		}
		`)`, `]`, `}` {
			l.can_import = false
			return l.match_punctuation(next_char, false)
		}
		`;`, `,` {
			l.can_import = false
			return token.Token{
				token_type: token.Seperator{
					value: next_char.ascii_str()
				}
				range:      [l.get_x()]
			}
		}
		`+`, `-`, `*`, `/`, `\\`, `%`, `=`, `|`, `&`, `<`, `>`, `^`, `?` {
			l.can_import = false
			return l.match_operators(next_char, l.get_x())
		}
		`0`...`9` {
			l.can_import = false
			return l.match_number(next_char, l.get_x())
		}
		`#` { // comment
			for {
				consume := l.consume_char() or { break }
				if consume == `\n` {
					break
				}
			}
			return token.Token{
				token_type: token.Comment{}
				range:      [l.get_x()]
			}
		}
		`a`...`z`, `A`...`Z`, `_` {
			return l.match_identifier(next_char, l.get_x())
		}
		`'`, `"` {
			return l.match_string(next_char, l.get_x())
		}
		else {
			return l.error_generator('token matching', errors_df.ErrorUnexpectedToken{
				token: next_char.ascii_str()
			})
		}
	}
}

// Consume the current character
pub fn (mut l Lex) consume_char() ?u8 {
	peek := l.peek()?
	if peek == `\n` {
		l.cur_col = 0
		l.cur_line += 1
	}

	l.x += 1
	l.cur_col += 1
	return peek
}

// skip all the whitespaces except \n
fn (mut l Lex) skip_whitespace() ? {
	for {
		l.peek()?
		if l.file_data[l.x] == `\n` || !l.file_data[l.x].is_space() {
			break
		}
		l.consume_char()
	}
}

fn (l &Lex) get_x() i64 {
	return l.x - 1
}

// Peek current character
fn (l &Lex) peek() ?u8 {
	if l.x < l.file_len {
		return l.file_data[l.x]
	}

	return none
}

fn (l &Lex) error_generator(extra_info string, error_data errors_df.ErrorInterface) errors_df.DfError {
	return errors_df.DfError{
		while:    'lexing'
		when:     extra_info
		path:     l.file_path
		cur_line: l.cur_line
		cur_col:  l.cur_col
		error:    error_data
	}
}

// go through a file
fn Lex.go_through_file(path string) !string {
	if os.is_file(path) == true {
		return os.read_file(path)!
	}

	return errors_df.DfError{
		while:    'lexing'
		when:     'going through file'
		path:     path
		cur_line: 0
		cur_col:  0
		error:    errors_df.ErrorFileIO{
			file_path: path
		}
	}
}

// Lexer Initializer
pub fn Lex.new(path string, return_path string) !Lex {
	go_through_file_data := Lex.go_through_file(path)!
	defer {
		unsafe {
			free(go_through_file_data)
		}
	}
	return Lex{
		x:               0
		file_data:       go_through_file_data
		file_path:       path
		return_path:     return_path
		can_import:      true
		file_len:        go_through_file_data.len
		cur_col:         1
		cur_line:        1
		bracket_balance: []
	}
}
