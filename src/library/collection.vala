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

public class Collection : BindingClass<Gee.List<Var>> {
	protected static Collection? self;

	public Collection() {
		this.name = "Collection";
	}

	public Object new_from_list(Gee.List<Var> list) {
		return new BindingObject<Gee.List<Var>>(this, list);
	}

	public override Object build(ArrayList<Var> parameters) throws ExecutionError {
		return this.new_from_list(new ArrayList<Var>());
	}

	public override Var get_var(Object object, string name) throws ExecutionError {
		var obj = (object as BindingObject<Gee.List<Var>>).val;
		switch(name) {
			case "length":
				return Integer.singleton().new_from_long(obj.size);
			case "isEmpty":
				return Boolean.singleton().new_from_bool(obj.is_empty);
			default:
				return base.get_var(object, name);
		}
	}

	protected override Var? exec_method(Object object, string name, ArrayList<Var> parameters) throws ExecutionError {
		var obj = this.get_object(object);
		switch(name) {
			case "set":
				if(parameters.size == 2 && parameters[0] is Object) {
					var index = parameters[0] as Object;
					if(index.instanceOf is Integer) {
						int i = (int) (index as BindingObject<long>).val;
						if(i < 0 || i >= obj.size) {
							throw new ExecutionError.TYPE(i.to_string() + " element does not exist in the collection " + object.to_string());
						}
						obj[i] = parameters[1];
						return null;
					}
					throw new ExecutionError.TYPE("Index parameter of a Collection must be a string. " + index.serialize() + " have been used.");
				}
				throw new ExecutionError.TYPE("Bad number of parameters for method set of a Collection.");
			case "add":
				if(parameters.size == 1) {
					obj.add(parameters[0]);
					return null;
				}
				throw new ExecutionError.TYPE("Bad number of parameters for method add of a Collection.");
			default:
				return base.exec_method(object, name, parameters);
		}
	}

	protected override Var exec_dual_operator(string name, Object left_operand, Object right_operand) throws ExecutionError {
		var val1 = this.get_object(left_operand);
		switch(name) {
			case "[]":
				if(!(right_operand.instanceOf is Integer)) {
					throw new ExecutionError.TYPE("You can only use integer to get Collection char.");
				}
				int val2 = (int) (right_operand as BindingObject<long>).val;
				if(val2 < 0 || val2 >= val1.size) {
					throw new ExecutionError.TYPE(val2.to_string() + " element does not exist in the collection " + left_operand.to_string());
				}
				return val1[val2];
			default:
				return base.exec_dual_operator(name, left_operand, right_operand);
		}
	}

	public override string to_string(Object object) throws ExecutionError {
		var vals = new ArrayList<string>();
		foreach(var val in this.get_object(object)) {
			vals.add(val.serialize());
		}
		return "[" + StringUtils.joinv(", ", vals) + "]";
	}

	public override bool to_bool(Object object) throws ExecutionError {
		return !this.get_object(object).is_empty;
	}

	public static Collection singleton() {
		if(self == null) {
			self = new Collection();
		}
		return self;
	}
}
