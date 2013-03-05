/*
 * Copyright (C) Thomas Pellissier Tanon 2013 <thomaspt@hotmail.fr>
 *
 * soli is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * soli is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public errordomain ParserError {
	LINE, VAR
}

public errordomain ExecutionError {
	VAR, EXPRESSION, TYPE
}


public class Main : GLib.Object {
	public static bool with_ui = false;
	public static string filename = "";
	public static bool run_tests = false;

	public static const OptionEntry[] entries = {
		{ "interface", 'i', 0, OptionArg.NONE, ref Main.with_ui, "Show the graphical user interface", null },
		{ "file", 'f', 0, OptionArg.FILENAME, ref Main.filename, "Execute file content", "FILE_NAME" },
		{ "tests", 't', 0, OptionArg.NONE, ref Main.run_tests, "Execute software tests", null },
		{ null }
	};

	/**
	 * Entry point
	 */
	static int main(string[] args) {
		var context = new OptionContext("- Small Object-oriented Language interpreter with a GTK+ GUI.");
		context.add_main_entries(entries, null);
		context.add_group(Gtk.get_option_group(true));
		try {
			context.parse(ref args);
		} catch (Error e) {
			stderr.printf("Error: %s\n", e.message);
			return 1;
		}
		if(filename == null) {
			filename = "";
		}

		if(run_tests) {
			return Test.run();
		} else if(filename != "" && !with_ui) {
			try {
				string text;
				FileUtils.get_contents(filename, out text);
				var result = exec(text);
				if(result != null) {
					print("Retourns: " + result);
				}
				return 0;
			} catch (Error e) {
				stderr.printf("Error: %s\n", e.message);
			}
			return 0;
		} else {
			Main.with_ui = true;
			return MainUi.show(args, filename);
		}
	}

	/**
	 * Exec the program and return it as string
	 */
	public static string? exec(string text) {
		try {
			return exec_internal(text);
		} catch (Error e) {
			stderr.printf("Error: %s\n", e.message);
			return null;
		}
	}

	public static string? exec_internal(string text) throws ParserError, ExecutionError {
		var tree = Parser.parse(text);
/* Useful to debug
foreach(var elem in ClassProvider.singleton().values) {
	print(elem.serialize());
}
print("\n" + tree.serialize() + "\n");*/
		ClassProvider.singleton().initialize();
		var val = tree.exec(new Memory());
		ClassProvider.singleton().clear();
		if(val is Object) {
			var obj = val as Object;
			return obj.instanceOf.to_string(obj);
		} else {
			return null;
		}
	}

	public static GLib.TimeVal get_time() {
		var time = TimeVal();
		time.get_current_time();
		return time;
	}
}
