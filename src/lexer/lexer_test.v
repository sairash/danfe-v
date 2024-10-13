module lexer

fn test_new() {
	path := "./test_inputs/lexer_test/test.df"
	lex := new(path)!
	assert lex.file_process[path].file_data == go_through_file(path)!
}