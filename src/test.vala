/*
/*
 * Copyright (C) Thomas Pellissier Tanon 2013 <thomaspt@hotmail.fr>
 *
 * sol is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * sol is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
using Gee;

protected class TestContent {
	public string name = "";
	public string val = "";
	public string content = "";
}

public class Test : GLib.Object {
	const string TEST_FILE = "./test.txt";

	private static ArrayList<TestContent> getTests() {
		var file = File.new_for_path(TEST_FILE);
		var tests = new ArrayList<TestContent>();
		if(!file.query_exists()) {
			stderr.printf("File '%s' doesn't exist.\n", file.get_path());
			return new ArrayList<TestContent>();
		}
		try {
			var dis = new DataInputStream(file.read());
			string line;
			int i = 0;
			var test = new TestContent();
			// Read lines until end of file (null) is reached
			while((line = dis.read_line(null)) != null) {
				if(line == "----") {
					tests.add(test);
					test = new TestContent();
					i = 0;
				} else {
					switch(i) {
						case 0:
							test.name = line;
							i++;
							break;
						case 1:
							test.val = line;
							i++;
							break;
						case 2:
							test.content += line + "\n";
							break;
					}
				}
			}
			return tests;
		} catch (Error e) {
			return new ArrayList<TestContent>();
		}
	}

	public static int run() {
		var tests = getTests();
		foreach(var test in tests) {
			print("Test %s: ", test.name);
			var result = Main.exec(test.content);
			if(result == null || result != test.val) {
				stderr.printf("Error: result was %s\n", result);
			} else {
				print("Ok");
			}
			print("\n");
		}
		return 0;
	}
}
