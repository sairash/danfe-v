module main

import parser
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
					mut pars := parser.Parse.new(cmd.args[0])!
					pars.walk()!
					pars_current := pars.file_process[pars.cur_file] or { 
						return error("")
					 }
					pars_current_body := pars_current.ast.body

					for i := 0;i < pars_current_body.len; i += 1 {
						pars_current_body[i].eval()!
					}
					return
				}
			},
		]
	}
	app.setup()
	app.parse(os.args)
}
