module lexer

import token
import grammer

fn (p &Process) map_balance(c u8) u8 {
	match c {
		`{` {
			return 125 // }
		}
		`(` {
			return 41 // )
		}
		`[` {
			return 93 // ]
		}
		`}` {
			return 123 // {
		}
		`)` {
			return 40 // (
		}
		`]` {
			return 91 // [
		}
		else {
			return 0 // default
		}
	}
}

fn (mut p Process) match_punctuation(c u8, open bool) !token.Token {
	if open {
		p.bracket_balance << c
	} else {
		len_brackets := p.bracket_balance.len - 1

		if len_brackets < 0 {
			return ErrorUnexpectedToken{
				token: c.ascii_str()
			}
		}

		if p.bracket_balance[len_brackets] != p.map_balance(c) {
			return ErrorMissingExpectedSymbol{
				expected: p.map_balance(p.bracket_balance[len_brackets]).ascii_str()
				found:    c.ascii_str()
			}
		} else {
			p.bracket_balance.pop()
		}
	}
	return token.Token{
		token_type: token.Punctuation{
			open:  open
			value: c
		}
	}
}

fn (mut p Process) match_number(start u8, start_index i64) !token.Token {
	mut return_number := [start]
	mut return_hint := token.NumericType.i64

	for {
		peek := p.peek() or { break }
		if peek.is_digit() {
			return_number << peek
			p.consume_char()
		} else if peek == `.` {
			match return_hint {
				.f64 {
					return ErrorUseOfMultipleFloatPoints{}
				}
				else {
					return_hint = token.NumericType.f64
					return_number << peek
					p.consume_char()
				}
			}
		} else if peek == `_` {
			p.consume_char()
		} else if peek.is_letter() {
			return ErrorMissingExpectedSymbol{
				expected: 'value of number type'
				found:    "\"${peek.ascii_str()}\" of type identifer."
			}
		} else {
			unsafe {
				free(peek)
			}
			break
		}
	}

	defer {
		unsafe {
			free(return_number)
			free(return_hint)
		}
	}

	return token.Token{
		token_type: token.Numeric{
			value: return_number.str()
			hint:  return_hint
		}
		range:      [start_index, p.get_x()]
	}
}

fn (mut p Process) match_operators(start u8, start_index i64) !token.Token {
	mut return_operator := [start]

	peek := p.peek() or { return ErrorUnexpectedEOF{} }

	if peek == `=` && (start == `+` || start == `-` || start == `=` || start == `>`
		|| start == `<` || start == `%`) {
		return_operator << peek
		p.consume_char()
	} else if peek == `|` && start == `|` {
		return_operator << peek
		p.consume_char()
	} else if peek == `&` && start == `&` {
		return_operator << peek
		p.consume_char()
	} else if peek == `+` && start == `+` {
		return_operator << peek
		p.consume_char()
	} else if peek == `-` && start == `-` {
		return_operator << peek
		p.consume_char()
	}

	defer {
		unsafe {
			free(return_operator)
			free(peek)
		}
	}

	return token.Token{
		token_type: token.Operator{
			value: return_operator.str()
		}
		range:      [start_index, p.get_x()]
	}
}

fn (p &Process) match_reserved_symbols(identifier string) token.Token {
	if identifier in grammer.reserved_symbols {
		return token.Token{
			token_type: token.ReservedSymbol{
				value: identifier
			}
			range:      []
		}
	} else {
		return token.Token{
			token_type: token.Identifier{
				value: identifier
			}
			range:      []
		}
	}
}

fn (mut p Process) match_string(start_symbol u8, start_index i64) !token.Token {
	mut return_string := []u8{}
	for {
		new_char := p.consume_char() or {
			return ErrorMissingExpectedSymbol{
				expected: start_symbol.ascii_str()
				found:    'EOF'
			}
		}

		if new_char == start_symbol {
			unsafe {
				free(new_char)
			}
			break
		} else if new_char == `\\` {
			consume := p.consume_char() or {
				return ErrorMissingExpectedSymbol{
					expected: start_symbol.ascii_str()
					found:    'EOF'
				}
			}
			return_string << consume
		} else {
			return_string << new_char
		}
	}

	return token.Token{
		token_type: token.String{
			value: return_string.str()
		}
		range:      [start_index + 1, p.get_x() - 1] // +1 to negate the extra starting " and - 1 to negate the extra ending "
	}
}

fn (mut p Process) match_identifier(first_char u8, start_index i64) !token.Token {
	mut return_str := [first_char]

	for {
		peek := p.peek() or { break }

		if peek.is_letter() || peek.is_digit() || peek == `_` {
			return_str << peek
			p.consume_char()
		} else {
			unsafe {
				free(peek)
			}
			break
		}
	}

	defer {
		unsafe {
			free(return_str)
			free(start_index)
		}
	}

	mut new_token := p.match_reserved_symbols(return_str.str())
	new_token.range = [start_index, p.get_x()]
	defer {
		unsafe {
			free(new_token)
		}
	}

	return new_token
}
