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

public class Integer : BindingClass<long> {
	protected static Integer? self;

	public Integer() {
		this.name = "int";
	}

	public Object new_from_long(long val) {
		return new BindingObject<long>(this, val);
	}

	public Object new_from_string(string str) {
		return this.new_from_long(long.parse(str));
	}

	public override Object build(ArrayList<Var> parameters) throws ExecutionError {
		return this.new_from_long(0);
	}

	protected override Var exec_mono_operator(string name, Object operand) throws ExecutionError {
		var val = this.get_object(operand);
		switch(name) {
			case "-":
				return this.new_from_long(-val);
			default:
				return base.exec_mono_operator(name, operand);
		}
	}

	protected override Var exec_dual_operator(string name, Object left_operand, Object right_operand) throws ExecutionError {
		if(right_operand.instanceOf is Float) {
			right_operand.instanceOf.exec_dual_operator(name, right_operand, left_operand);
		}
		if(!(right_operand.instanceOf is Integer)) {
			throw new ExecutionError.VAR("You can do only the operation " + name + " with integers.");
		}
		var val1 = this.get_object(left_operand);
		var val2 = this.get_object(right_operand);
		switch(name) {
			case "+":
				return this.new_from_long(val1 + val2);
			case "-":
				return this.new_from_long(val1 - val2);
			case "*":
				return this.new_from_long(val1 * val2);
			case "/":
				return this.new_from_long(val1 / val2);
			case "%":
				return this.new_from_long(val1 % val2);
			case "=":
				return Boolean.singleton().new_from_bool(val1 == val2);
			case "!=":
				return Boolean.singleton().new_from_bool(val1 != val2);
			case "<":
				return Boolean.singleton().new_from_bool(val1 < val2);
			case "<=":
				return Boolean.singleton().new_from_bool(val1 <= val2);
			case ">":
				return Boolean.singleton().new_from_bool(val1 > val2);
			case ">=":
				return Boolean.singleton().new_from_bool(val1 >= val2);
			default:
				return base.exec_dual_operator(name, left_operand, right_operand);
		}
	}

	public override string to_string(Object object) throws ExecutionError {
		return this.get_object(object).to_string();
	}

	public override bool to_bool(Object object) throws ExecutionError {
		return this.get_object(object) != 0;
	}

	public static Integer singleton() {
		if(self == null) {
			self = new Integer();
		}
		return self;
	}
}
