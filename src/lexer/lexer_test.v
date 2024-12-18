module lexer

import token

fn test_go_through_file() {
	path := './test_inputs/lexer_test/test.df'
	expected_output := '      \n      a\nb\nc\nd\ne\nf\ng\nh\ni\nj'
	assert expected_output == Lex.go_through_file(path)!
}

fn test_new() {
	path := './test_inputs/lexer_test/test.df'
	lex := Lex.new(path)!
	assert lex.file_process[path] or { panic(ErrorFileIO{
		path: lex.cur_file
	}) }.file_data == Lex.go_through_file(path)!
}

fn test_add_file_to_lexer() {
	path := './test_inputs/lexer_test/test.df'
	path1 := './test_inputs/lexer_test/test1.df'
	mut lex := Lex.new(path)!
	lex.add_new_file_to_lex(path1, path)!
	assert lex.file_process.len == 2 && lex.file_process[path1] or {
		panic('New File not added in file process!')
	}.return_path == path
}

fn test_next() {
	path := './test_inputs/lexer_test/test.df'
	lex := Lex.new(path)!
	assert lex.next()!.range[0] == 6
}

fn test_identifier() {
	path := './test_inputs/lexer_test/identifier.df'
	lex := Lex.new(path)!
	mut first_ident := lex.next()!

	match mut first_ident.token_type {
		token.Identifier {
			assert first_ident.token_type.value == 'abcd1_2'
		}
		else {
			panic('Identifier mismatch')
		}
	}
}

fn test_string() {
	path := './test_inputs/lexer_test/string.df'
	lex := Lex.new(path)!
	mut first_ident := lex.next()!

	match mut first_ident.token_type {
		token.String {
			assert first_ident.token_type.value == 'hello'
		}
		else {
			panic('String mismatch')
		}
	}
}

fn test_symbol() {
	path := './test_inputs/lexer_test/symbol.df'
	lex := Lex.new(path)!
	mut first_ident := lex.next()!

	match mut first_ident.token_type {
		token.ReservedSymbol {
			assert first_ident.token_type.value == 'if'
		}
		else {
			panic('Symbol mismatch')
		}
	}
}

fn test_number() {
	path := './test_inputs/lexer_test/number.df'
	lex := Lex.new(path)!
	mut first_ident := lex.next()!

	match mut first_ident.token_type {
		token.Numeric {
			assert first_ident.token_type.value == '1234'
		}
		else {
			panic('Number mismatch')
		}
	}
}

fn test_operator() {
	path := './test_inputs/lexer_test/operator.df'
	lex := Lex.new(path)!
	mut first_ident := lex.next()!

	match mut first_ident.token_type {
		token.Operator {
			assert first_ident.token_type.value == '+'
		}
		else {
			panic('Operator mismatch')
		}
	}
}

fn test_punctuation() {
	path := './test_inputs/lexer_test/punctuation.df'
	lex := Lex.new(path)!
	mut first_ident := lex.next()!

	match mut first_ident.token_type {
		token.Punctuation {
			assert first_ident.token_type.open == true
			assert first_ident.token_type.value == '('
		}
		else {
			panic('punctuation mismatch')
		}
	}
}


fn test_comment() {
	path := './test_inputs/lexer_test/comment.df'
	lex := Lex.new(path)!
	mut first_ident := lex.next()!

	match mut first_ident.token_type {
		token.Comment {}
		else {
			panic('Comment mismatch')
		}
	}
}
