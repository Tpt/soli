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

/**
 * A sol definded class
 */
public class CustomClass : Class {
	protected Memory static_vals;
	protected HashMap<string,Operator> vars;
	protected HashMap<string,Operator> static_vars;
	protected HashMap<string,Function> methods;
	protected HashMap<string,Function> static_methods;

	public CustomClass(string name, string? parent, ArrayList<string> interfaces) {
		this.name = name;
		this.parent_name = parent;
		this.interfaces = interfaces;
		this.vars = new HashMap<string,Operator>();
		this.static_vars = new HashMap<string,Operator>();
		this.methods = new HashMap<string,Function>();
		this.static_methods = new HashMap<string,Function>();
		this.static_vals = new Memory();
	}

	public void add_var(string name, Operator val) {
		this.vars[name] = val;
	}

	public void add_static_var(string name, Operator val) {
		this.static_vars[name] = val;
	}

	public void add_method(string name, Function val) {
		this.methods[name] = val;
	}

	public void add_static_method(string name, Function val) {
		this.static_methods[name] = val;
	}

	public override void init() throws ExecutionError {
		if(this.parent_name != null && this.parent == null) {
			this.parent = ClassProvider.singleton().get_class(this.parent_name);
		}
		foreach (var entry in this.static_vars.entries) {
			this.static_vals[entry.key] = entry.value.exec(new Memory());
		}
		this.static_vars = new HashMap<string,Operator>();
	}

	public override Object build(ArrayList<Var> parameters) throws ExecutionError {
		var object = new CustomObject(this);
		foreach (var entry in this.vars.entries) {
			object.vals[entry.key] = entry.value.exec(new Memory());
		}
		if("contruct" in this.methods.keys) {
			this.exec_method(object, "contruct", parameters);
		}
		return object;
	}

	public override Var get_var(Object object, string name) throws ExecutionError {
		var obj = object as CustomObject;
		if(name in obj.vals.keys) {
			return obj.vals[name];
		} else {
			throw new ExecutionError.VAR("The property " + name + " of the class " + this.name + " does not exist");
		}
	}

	public override void set_var(Object object, string name, Var val) throws ExecutionError {
		var obj = object as CustomObject;
		obj.vals[name] = val;
	}

	public override Var get_static_var(string name) throws ExecutionError {
		if(name in this.static_vals.keys) {
			return this.static_vals[name];
		} else {
			throw new ExecutionError.VAR("The static property " + name + " of the class " + this.name + " does not exist");
		}
	}

	public override void set_static_var(string name, Var val) throws ExecutionError {
		this.static_vals[name] = val;
	}

	public override Var? exec_method(Object object, string name, ArrayList<Var> parameters) throws ExecutionError {
		if(name in this.methods.keys) {
			var function = this.methods[name];
			var param = new ArrayList<Var>();
			param.add(object);
			param.add(this);
			param.add_all(parameters);
			return function.exec_function(param);
		} else if(this.parent != null) {
			return this.parent.exec_method(object, name, parameters);
		} else {
			throw new ExecutionError.VAR("The method " + name + " of the class " + this.name + " does not exist");
		}
	}

	public override Var? exec_static_method(string name, ArrayList<Var> parameters) throws ExecutionError {
		if(name in this.static_methods.keys) {
			var function = this.static_methods[name];
			var param = new ArrayList<Var>();
			param.add(this);
			param.add_all(parameters);
			return function.exec_function(param);
		} else if(this.parent != null) {
			return this.parent.exec_static_method(name, parameters);
		} else {
			throw new ExecutionError.VAR("The static method " + name + " of the class " + this.name + " does not exist");
		}
	}

	public override Var exec_mono_operator(string name, Object operand) throws ExecutionError {
		var parameters = new ArrayList<Var>();
		return this.exec_method(operand, "operator" + name, parameters);
	}

	public override Var exec_dual_operator(string name, Object left_operand, Object right_operand) throws ExecutionError {
		var parameters = new ArrayList<Var>();
		parameters.add(right_operand);
		return this.exec_method(left_operand, "operator" + name, parameters);
	}

	public override string to_string(Object object) throws ExecutionError {
		if("toString" in this.methods.keys) {
			var result = this.exec_method(object, "toString", new ArrayList<Var>());
			if(result is Object) { //TODO improve?
				return (result as Object).to_string();
			} else {
				throw new ExecutionError.VAR("The method toString of the class " + this.name + " does not return a string.");
			}
		}
		throw new ExecutionError.VAR("The class " + this.name + " has no toString method.");
	}

	public override bool to_bool(Object object) throws ExecutionError {
		if("toBool" in this.methods.keys) {
			var result = this.exec_method(object, "toBool", new ArrayList<Var>());
			if(result is Object) { //TODO improve?
				return (result as Object).to_bool();
			} else {
				throw new ExecutionError.VAR("The method toBool of the class " + this.name + " does not return a bollean.");
			}
		}
		return true;
	}

	public override uint hash(Object object) {
		return direct_hash((object as CustomObject).vals);
	}

	public override string serialize(int level = 0) {
		string str = "class " + this.name;
		if(this.parent_name != null) {
			str += " : " + this.parent_name;
		}
		if(!this.interfaces.is_empty) {
			str += " implements " + StringUtils.joinv(", ", this.interfaces);
		}
		str += "\n";
		foreach(var entry in this.vars.entries) {
			str += "\t" + entry.key + " = " + entry.value.serialize() + "\n";
		}
		foreach(var entry in this.static_vars.entries) {
			str += "\tstatic " + entry.key + " = " + entry.value.serialize() + "\n";
		}
		foreach(var entry in this.methods.entries) {
			str += "\t" + entry.key + " = " + entry.value.serialize(level) + "\n";
		}
		foreach(var entry in this.static_methods.entries) {
			str += "\t" + entry.key + " = " + entry.value.serialize(level) + "\n";
		}
		return str;
	}
}
