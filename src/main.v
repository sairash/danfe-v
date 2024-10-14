module main

import lexer
import token
import os
import cli

fn main() {
	mut app := cli.Command{
		name:        'example-app'
		description: 'example-app'
		execute:     fn (cmd cli.Command) ! {
			println('hello app')
			return
		}
		commands:    [
			cli.Command{
				name:          'run'
				required_args: 1
				execute:       fn (cmd cli.Command) ! {
					mut lex := lexer.Lex.new(cmd.args[0])!
					lex.add_new_file_to_lex('./test_inputs/lexer_test/test1.df', cmd.args[0])!
					for {
						token_val := lex.next()!
						if token_val.token_type == token.TokenType(token.EOF{}) {
							break
						}
						println(token_val)
					}
					return
				}
			},
		]
	}
	app.setup()
	app.parse(os.args)
}
