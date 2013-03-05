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

public class Boolean : BindingClass<bool> {
	protected static Boolean? self;

	public Boolean() {
		this.name = "bool";
	}

	public Object new_from_bool(bool val) {
		return new BindingObject<bool>(this, val);
	}

	public override Object build(ArrayList<Var> parameters) throws ExecutionError {
		return this.new_from_bool(false);
	}

	protected override Var exec_mono_operator(string name, Object operand) throws ExecutionError {
		var val = operand.to_bool();
		switch(name) {
			case "!":
				return this.new_from_bool(!val);
			default:
				return base.exec_mono_operator(name, operand);
		}
	}

	protected override Var exec_dual_operator(string name, Object left_operand, Object right_operand) throws ExecutionError {
		var val1 = left_operand.to_bool();
		var val2 = right_operand.to_bool();
		switch(name) {
			case "&&":
				return this.new_from_bool(val1 && val2);
			case "||":
				return this.new_from_bool(val1 || val2);
			case "=":
				return this.new_from_bool(val1 == val2);
			case "!=":
				return this.new_from_bool(val1 != val2);
			default:
				return base.exec_dual_operator(name, left_operand, right_operand);
		}
	}

	public override string to_string(Object object) throws ExecutionError {
		return this.get_object(object).to_string();
	}

	public override bool to_bool(Object object) throws ExecutionError {
		return this.get_object(object);
	}

	public static Boolean singleton() {
		if(self == null) {
			self = new Boolean();
		}
		return self;
	}
}
