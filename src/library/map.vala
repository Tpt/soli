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

public class Map : BindingClass<AbstractMap<Object,Var>> {
	protected static Map? self;

	public Map() {
		this.name = "Map";
	}

	public Object new_from_map(AbstractMap<Object,Var> list) {
		return new BindingObject<AbstractMap<Object,Var>>(this, list);
	}

	public override Object build(ArrayList<Var> parameters) throws ExecutionError {
		return this.new_from_map(new HashMap<Object,Var>(Map.do_hash, Class.object_equal));
	}

	public override Var get_var(Object object, string name) throws ExecutionError {
		var obj = (object as BindingObject<AbstractMap<Object,Var>>).val;
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
					obj[parameters[0] as Object] = parameters[1];
					return null;
				}
				throw new ExecutionError.TYPE("Bad number of parameters for method set of a Map.");
			default:
				return base.exec_method(object, name, parameters);
		}
	}

	protected override Var exec_dual_operator(string name, Object left_operand, Object right_operand) throws ExecutionError {
		var val1 = this.get_object(left_operand);
		switch(name) {
			case "[]":
				if(!val1.has_key(right_operand)) {
					throw new ExecutionError.TYPE(right_operand.to_string() + " key does not exist in the map " + left_operand.to_string());
				}
				return val1[right_operand];
			default:
				return base.exec_dual_operator(name, left_operand, right_operand);
		}
	}

	public override string to_string(Object object) throws ExecutionError {
		var vals = new ArrayList<string>();
		foreach(var val in this.get_object(object).entries) {
			vals.add(val.key.serialize() + ":" + val.value.serialize());
		}
		return "{" + StringUtils.joinv(", ", vals) + "}";
	}

	public override bool to_bool(Object object) throws ExecutionError {
		return !this.get_object(object).is_empty;
	}

	public static Map singleton() {
		if(self == null) {
			self = new Map();
		}
		return self;
	}

	public static uint do_hash(Object object) {
		return object.instanceOf.hash(object);
	}
}
