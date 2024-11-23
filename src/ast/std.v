module ast

import os

type StdFunction = fn (process_id []string, arguments []Node) !EvalOutput

struct STD {
	path string
	func StdFunction @[required]
}

const std_functions = {
	// os
	'os_read_file_2661209820506494319':  STD{
		path: '/packages/std/os.df'
		func: fn (process_id []string, arguments []Node) !EvalOutput {
			return EvalOutput(os.read_file(arguments[0].eval(process_id)! as string)!)
		}
	}
	'os_write_file_8609329803011309513': STD{
		path: '/packages/std/os.df'
		func: fn (process_id []string, arguments []Node) !EvalOutput {
			os.write_file(arguments[0].eval(process_id)! as string, arguments[1].eval(process_id)!.get_as_string()) or {
				return i64(0)
			}
			return i64(1)
		}
	}
	'os_ls_file_8433091393709237347':    STD{
		path: '/packages/std/os.df'
		func: fn (process_id []string, arguments []Node) !EvalOutput {
			mut table_data := map[string]EvalOutput{}
			list_of_files := os.ls(arguments[0].eval(process_id)! as string) or { [] }
			for i := 0; i < list_of_files.len; i++ {
				table_data['${i}'] = list_of_files[i]
			}
			return Table{table_data, table_data.len, true}
		}
	}
}
