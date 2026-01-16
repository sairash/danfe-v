module lexer

import token
import grammar
import errors_df

fn (l &Lex) map_balance(c u8) u8 {
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

fn (mut l Lex) match_punctuation(c u8, open bool) !token.Token {
	if open {
		l.bracket_balance << c
	} else {
		len_brackets := l.bracket_balance.len - 1

		if len_brackets < 0 {
			return l.error_generator('match punctuation', errors_df.ErrorUnexpectedToken{
				token: c.ascii_str()
			})
		}

		if l.bracket_balance[len_brackets] != l.map_balance(c) {
			return l.error_generator('match punctuation', errors_df.ErrorMismatch{
				expected: l.map_balance(l.bracket_balance[len_brackets]).ascii_str()
				found:    c.ascii_str()
			})
		} else {
			l.bracket_balance.pop()
		}
	}
	return token.Token{
		token_type: token.Punctuation{
			open:  open
			value: c.ascii_str()
		}
	}
}

fn (mut l Lex) match_number(start u8, start_index i64) !token.Token {
	mut return_number := start.ascii_str()
	mut return_hint := token.NumericType.i64

	for {
		peek := l.peek() or { break }
		if peek.is_digit() {
			return_number += peek.ascii_str()
			l.consume_char()
		} else if peek == `.` {
			match return_hint {
				.f64 {
					return l.error_generator('match number', errors_df.ErrorUseOfMultipleFloatPoints{})
				}
				else {
					return_hint = token.NumericType.f64
					return_number += peek.ascii_str()
					l.consume_char()
				}
			}
		} else if peek == `_` {
			l.consume_char()
		} else if peek.is_letter() {
			return l.error_generator('match number', errors_df.ErrorMismatch{
				expected: 'value of number type'
				found:    "\"${peek.ascii_str()}\" of type identifer."
			})
		} else {
			break
		}
	}

	return token.Token{
		token_type: token.Numeric{
			value: return_number
			hint:  return_hint
		}
		range:      [start_index, l.get_x()]
	}
}

fn (mut l Lex) match_operators(start u8, start_index i64) !token.Token {
	mut return_operator := start.ascii_str()

	peek := l.peek() or {
		return l.error_generator('match operator', errors_df.ErrorUnexpectedEOF{})
	}

	if peek == `=` && (start == `+` || start == `-` || start == `=` || start == `>`
		|| start == `<` || start == `%` || start == `!` || start == `?`) {
		return_operator += peek.ascii_str()
		l.consume_char()
	} else if (peek == `>` && start == `>`) || (peek == `<` && start == `<`) {
		return_operator += peek.ascii_str()
		l.consume_char()
	} else if peek == `>` && start == `=` {
		return_operator += peek.ascii_str()
		l.consume_char()
	} else if peek == `|` && start == `|` {
		return_operator += peek.ascii_str()
		l.consume_char()
	} else if peek == `&` && start == `&` {
		return_operator += peek.ascii_str()
		l.consume_char()
	} else if peek == `+` && start == `+` {
		return_operator += peek.ascii_str()
		l.consume_char()
	} else if peek == `-` && start == `-` {
		return_operator += peek.ascii_str()
		l.consume_char()
	}

	return token.Token{
		token_type: token.Operator{
			value: return_operator
		}
		range:      [start_index, l.get_x()]
	}
}

fn (l Lex) check_if_in_reserved_symbol(identifier string) string {
	for key, value in grammar.reserved_symbols {
		if identifier == key || identifier in value {
			return key
		}
	}
	return ''
}

fn (mut l Lex) match_reserved_symbols(identifier string, identifier_split []string) !token.Token {
	mut ret_ident := token.Identifier{
		value:     identifier
		sep_value: identifier_split
		reserved:  l.check_if_in_reserved_symbol(identifier)
	}

	if ret_ident.reserved != 'import' && ret_ident.reserved != 'as' {
		if !l.skip_next_can_import {
			l.can_import = false
		} else {
			l.skip_next_can_import = false
		}
	} else {
		l.skip_next_can_import = true
	}

	return token.Token{
		token_type: ret_ident
		range:      []
	}
}

fn (mut l Lex) match_string(start_symbol u8, start_index i64) !token.Token {
	mut return_string := ''
	for {
		new_char := l.consume_char() or {
			return l.error_generator('match string', errors_df.ErrorMismatch{
				expected: start_symbol.ascii_str()
				found:    'EOF'
			})
		}

		if new_char == start_symbol {
			break
		} else if new_char == `\\` {
			consume := l.consume_char() or {
				return l.error_generator('match string', errors_df.ErrorMismatch{
					expected: start_symbol.ascii_str()
					found:    'EOF'
				})
			}
			match consume.ascii_str() {
				'e' {
					return_string += '\e' // Command Escape
				}
				'n' {
					return_string += '\n' // Line feed (New Line)
				}
				't' {
					return_string += '\t' // Horizontal tab
				}
				'a' {
					return_string += '\a' // Bell
				}
				'b' {
					return_string += '\b' // Backspace
				}
				'v' {
					return_string += '\v' // Vertical Tab
				}
				'f' {
					return_string += '\f' // Form Feed
				}
				'r' {
					return_string += '\r' // Carriage return
				}
				'0' {
					return_string += '\0' // Null Byte
				}
				else {
					return_string += consume.ascii_str()
				}
			}
		} else {
			return_string += new_char.ascii_str()
		}
	}

	return token.Token{
		token_type: token.String{
			value: return_string
		}
		range:      [start_index + 1, l.get_x() - 1] // +1 to negate the extra starting " and - 1 to negate the extra ending "
	}
}

fn (mut l Lex) match_identifier(first_char u8, start_index i64) !token.Token {
	mut return_str := ''

	mut return_str_sep := first_char.ascii_str()

	mut check_string_has_reserved := false

	mut modules_sep := []string{}

	for {
		peek := l.peek() or { break }
		if peek.is_letter() || peek.is_digit() || peek == `_` {
			return_str_sep += peek.ascii_str()
			l.consume_char()
		} else if peek == `.` {
			check_string_has_reserved = true
			return_str += return_str_sep + peek.ascii_str()
			modules_sep << return_str_sep
			return_str_sep = ''
			l.consume_char()
		} else {
			break
		}
	}

	return_str += return_str_sep
	modules_sep << return_str_sep

	if check_string_has_reserved {
		for key, value in grammar.reserved_symbols {
			if key in modules_sep {
				return l.error_generator('"." character', errors_df.ErrorTryingToUseReservedIdentifier{
					identifier: key
				})
			}
			for _, v in value {
				if v in modules_sep {
					return l.error_generator('"." character', errors_df.ErrorTryingToUseReservedIdentifier{
						identifier: v
					})
				}
			}
		}
	}

	if return_str[return_str.len - 1] == `.` {
		return l.error_generator('match identifier', errors_df.ErrorDotCantBeEndOfIdent{
			token: return_str
		})
	}

	mut new_token := l.match_reserved_symbols(return_str, modules_sep)!
	new_token.range = [start_index, l.get_x()]
	return new_token
}
