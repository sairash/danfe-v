module parser

import lexer
import token
import ast

struct Process {
pub mut:
	lex           lexer.Lex
	current_token token.Token
	next_token    token.Token
	ast           ast.Chunk
}

pub struct Parse {
pub mut:
	file_process  map[string]&Process
	cur_file      string
	starting_file string
}

pub fn (mut p Process) next() ! {
	p.current_token = p.next_token
	p.lex.next()!
}

pub fn (p &Process) check_token(tok token.Token) bool {
	return p.current_token.token_type == tok.token_type
}

pub fn (mut p Parse) walk() ! {
	for {
		proc := p.file_process[p.cur_file] or { return ErrorUnexpected{} }

		if proc.check_token(token.Token{ token_type: token.EOF{} }) {
			break
		}
	}
}

pub fn (mut p Parse) add_new_file_to_parse(path string, return_path string) ! {
	mut lex := lexer.Lex.new(path, '')!

	curr := lex.next()!
	next := lex.next()!
	p.file_process[path] = &Process{
		lex:           lex
		current_token: curr
		next_token:    next
		ast:           ast.Chunk{}
	}
}

// Create New Parser
pub fn Parse.new(path string) !&Parse {
	mut parse_file := &Parse{
		file_process:  {}
		cur_file:      path
		starting_file: path
	}
	parse_file.add_new_file_to_parse(path, '')!
	return parse_file
}
