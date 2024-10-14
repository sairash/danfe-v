module lexer

fn test_go_through_file(){
	path := "./test_inputs/lexer_test/test.df"
	expected_output := "a\nb\nc\nd\ne\nf\ng\nh\ni\nj"
	assert expected_output == go_through_file(path)!
}
fn test_new() {
	path := "./test_inputs/lexer_test/test.df"
	lex := new(path)!
	assert lex.file_process[path].file_data == go_through_file(path)!
}

fn test_add_file_to_lexer(){
	path := "./test_inputs/lexer_test/test.df"
	path1 := "./test_inputs/lexer_test/test1.df"
	mut lex := new(path)!
	lex.add_new_file_to_lex(path1, path)!
	assert lex.file_process.len == 2 && lex.file_process[path1]or { panic("New File not added in file process!") }.return_path == path
}