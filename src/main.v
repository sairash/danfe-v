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
					println(pars)
					
					return
				}
			},
		]
	}
	app.setup()
	app.parse(os.args)
}
