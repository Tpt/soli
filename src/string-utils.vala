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

public class StringUtils : GLib.Object {
	public const unichar[] EMPTY_CHARS = { ' ', '\t' };

	public static List<string> split(string text, char tag) {
		var list = new List<string>();
		var temp = new StringBuilder();
		unichar c;
		for(int i = 0; text.get_next_char(ref i, out c);) {
			if(c == tag) {
				list.append(temp.str);
				temp.erase();
			} else {
				temp.append_unichar(c);
			}
		}
		if(c != tag) {
			list.append(temp.str);
		}
		return list;
	}

	public static bool contain(string text, char tag) {
		return tag in text.to_utf8();
	}

	public static bool is_empty(string text) {
		unichar c;
		for(int i = 0; text.get_next_char(ref i, out c);) {
			if(!(c in StringUtils.EMPTY_CHARS)) {
				return false;
			}
		}
		return true;
	}

	public static double atof(string s) {
		long num = 0;
		long radix = 1;
		bool dec = true;
		long neg = 1;
		int i = 0;
		if(s[i] == '-') {
			i++;
			neg = -1;
		}
		while(i < s.length) {
			if(s[i].isdigit()) {
				num = 10 * num + s[i].digit_value();
				if(!dec) {
					radix *= 10;
				}
			} else {
				dec = false;
			}
			i++;
		}
		return ((double) num/(double) radix) * neg;
	}

	public static string joinv(string delimiter, Gee.List<string> list) {
		string str = "";
		if(list.size == 0) {
			return str;
		}
		str += list[0];
		for(int i = 1; i < list.size; i++) {
			str += delimiter + list[i];
		}
		return str;
	}
}
