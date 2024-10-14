module lexer

import token
import grammer

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
	mut return_string := ''
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
			return_string += consume.ascii_str()
		} else {
			return_string += new_char.ascii_str()
		}
	}

	return token.Token{
		token_type: token.String{
			value: return_string
		}
		range:      [start_index + 1, p.get_x() - 1] // +1 to negate the extra starting " and - 1 to negate the extra ending "
	}
}

fn (mut p Process) match_identifier(first_char u8, start_index i64) !token.Token {
	mut return_str := first_char.ascii_str()

	for {
		peek := p.peek() or { break }

		if peek.is_letter() || peek.is_digit() || peek == `_` {
			return_str += peek.ascii_str()
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

	mut new_token := p.match_reserved_symbols(return_str)
	new_token.range = [start_index, p.get_x()]
	defer {
		unsafe {
			free(new_token)
		}
	}

	return new_token
}
