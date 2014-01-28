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

public class String : BindingClass<string> {
	protected static String? self;

	public String() {
		this.name = "string";
	}

	public Object new_from_string(string str) {
		return new BindingObject<string>(this, str);
	}

	public override Object build(ArrayList<Var> parameters) throws ExecutionError {
		return this.new_from_string("");
	}

	public override Var get_var(Object object, string name) throws ExecutionError {
		var obj = (object as BindingObject<string>).val;
		switch(name) {
			case "length":
				return Integer.singleton().new_from_long(obj.length);
			case "isEmpty":
				return Boolean.singleton().new_from_bool(obj.length == 0);
			default:
				return base.get_var(object, name);
		}
	}

	protected override Var exec_dual_operator(string name, Object left_operand, Object right_operand) throws ExecutionError {
		var val1 = left_operand.to_string();
		switch(name) {
			case "+":
				var val2 = right_operand.to_string();
				return this.new_from_string(val1 + val2);
			case "=":
				var val2 = right_operand.to_string();
				return Boolean.singleton().new_from_bool(val1 == val2);
			case "!=":
				var val2 = right_operand.to_string();
				return Boolean.singleton().new_from_bool(val1 != val2);
			case "[]":
				if(!(right_operand.instanceOf is Integer)) {
					throw new ExecutionError.TYPE("You can only use integer to get string char.");
				}
				long val2 = (right_operand as BindingObject<long>).val;
				if(val2 < 0 || val2 >= val1.length) {
					throw new ExecutionError.TYPE(val2.to_string() + " character does not exist in the string \"" + val1 + "\".");
				}
				return String.singleton().new_from_string(val1[val2].to_string());
			default:
				return base.exec_dual_operator(name, left_operand, right_operand);
		}
	}

	public override string to_string(Object object) throws ExecutionError {
		return this.get_object(object);
	}

	public override bool to_bool(Object object) throws ExecutionError {
		return this.get_object(object) != "";
	}

	public override uint hash(Object object) {
		return str_hash((object as BindingObject<string>).val);
	}

	public static String singleton() {
		if(self == null) {
			self = new String();
		}
		return self;
	}
}
