module ast

import os
import time

type StdFunction = fn (process_id []&Process, arguments []Node) !EvalOutput

struct STD {
	path        string
	func        StdFunction @[required]
}

const std_functions = {
	// os
	'os_read_file_2661209820506494319':  STD{
		path:        '/packages/std/os.df'
		func:        fn (process_id []&Process, arguments []Node) !EvalOutput {
			return EvalOutput(os.read_file(arguments[0].eval(process_id)! as string)!)
		}
	}
	'os_write_file_8609329803011309513': STD{
		path:        '/packages/std/os.df'
		func:        fn (process_id []&Process, arguments []Node) !EvalOutput {
			os.write_file(arguments[0].eval(process_id)! as string, arguments[1].eval(process_id)!.get_as_string())!
			return i64(1)
		}
	}
	'os_ls_file_8433091393709237347':    STD{
		path:        '/packages/std/os.df'
		func:        fn (process_id []&Process, arguments []Node) !EvalOutput {
			mut table_data := map[string]EvalOutput{}
			list_of_files := os.ls(arguments[0].eval(process_id)! as string)!
			for i := 0; i < list_of_files.len; i++ {
				table_data['${i}'] = list_of_files[i]
			}
			return Table{table_data, table_data.len, true}
		}
	}
	'os_move_1459546098699018584':       STD{
		path:        '/packages/std/os.df'
		func:        fn (process_id []&Process, arguments []Node) !EvalOutput {
			os.mv_by_cp(arguments[0].eval(process_id)! as string, arguments[1].eval(process_id)! as string,
				os.MvParams{
				overwrite: true
			})!
			return i64(1)
		}
	}
	'os_mkdir_325329633659613679':       STD{
		path:        '/packages/std/os.df'
		func:        fn (process_id []&Process, arguments []Node) !EvalOutput {
			os.mkdir_all(arguments[0].eval(process_id)! as string)!
			return i64(1)
		}
	}
	'os_isdir_3352910224302066040':      STD{
		path:        '/packages/std/os.df'
		func:        fn (process_id []&Process, arguments []Node) !EvalOutput {
			if os.is_dir(arguments[0].eval(process_id)! as string) {
				return i64(1)
			}
			return i64(0)
		}
	}
	'os_isfile_2816429377265257685':     STD{
		path:        '/packages/std/os.df'
		func:        fn (process_id []&Process, arguments []Node) !EvalOutput {
			if os.is_file(arguments[0].eval(process_id)! as string) {
				return i64(1)
			}
			return i64(0)
		}
	}






	// Time
	'time_now_9079766339132815114':      STD{
		path: '/packages/std/time.df'
		func:        fn (process_id []&Process, arguments []Node) !EvalOutput {
			return time.now().str()
		}
	}

	'time_now_unix_nano_7349991598584833416':      STD{
		path: '/packages/std/time.df'
		func:        fn (process_id []&Process, arguments []Node) !EvalOutput {
			return time.now().unix_nano()
		}
	}

}
