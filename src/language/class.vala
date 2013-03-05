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
 * A class
 */
public abstract class Class : Var {
	public new string name { get; protected set; }
	protected Class? parent;
	protected string? parent_name; //Store the parent class name waiting for its creation
	protected ArrayList<string> interfaces;

	/**
	 * Initialize the class
	 */
	public abstract void init() throws ExecutionError;

	/**
	 * Returns if a class implement an interface
	 */
	public bool implements(string iface) {
		return this.name == iface
			|| iface in this.interfaces
			|| (this.parent != null && this.parent.implements(iface));
	}

	public abstract Object build(ArrayList<Var> parameters) throws ExecutionError;

	public abstract Var get_var(Object object, string name) throws ExecutionError;

	public abstract void set_var(Object object, string name, Var val) throws ExecutionError;

	public abstract Var get_static_var(string name) throws ExecutionError;

	public abstract void set_static_var(string name, Var val) throws ExecutionError;

	public abstract Var? exec_method(Object object, string name, ArrayList<Var> parameters) throws ExecutionError;

	public abstract Var? exec_static_method(string name, ArrayList<Var> parameters) throws ExecutionError;

	public abstract Var exec_mono_operator(string name, Object operand) throws ExecutionError;

	public abstract Var exec_dual_operator(string name, Object left_operand, Object right_operand) throws ExecutionError;

	public abstract string to_string(Object object) throws ExecutionError;

	public abstract bool to_bool(Object object) throws ExecutionError;

	/**
	 * Returns the hash for an object of the class
	 */
	public abstract uint hash(Object object);

	/**
	 * Check if two objects are equals
	 * @todo doesn't work fine with calls that does not implements "=" operator
	 */
	public static bool object_equal(Object a, Object b) {
		try {
			var result = a.instanceOf.exec_dual_operator("=", a, b);
			if(result is Object) {
				var obj = result as Object;
				if(obj.instanceOf is Boolean) {
					return (obj as BindingObject<bool>).val;
				}
			}
			return a == b;
		} catch(ExecutionError e) {
			return a == b;
		}		
	}
}


/**
 * A property of an object
 */
public class ObjectMember : Var {
	public Operator element { get; protected set; }

	public ObjectMember(Operator element, string name) {
		this.name = name;
		this.element = element;
	}

	public override Var exec(Memory memory) throws ExecutionError {
		var element = this.element.exec(memory);
		if(element is Object) {
			var object = element as Object;
			return object.instanceOf.get_var(object, this.name);
		} else if(element is Class) {
			return (element as Class).get_static_var(this.name);
		} else {
			throw new ExecutionError.VAR("The variable " + this.element.serialize() + " is not a class or an object.");
		}
	}

	public override string serialize(int level = 0) {
		return this.element.serialize() + "." + this.name;
	}
}


/**
 * Operator that contruct a new object
 */
public class InstanceOperator : Operator {
	public ArrayList<Operator> parameters {get; protected set;}
	protected Operator element;

	public InstanceOperator(Operator element, ArrayList<Operator> parameters) {
		this.element = element;
		this.parameters = parameters;
	}
	
	public override Var exec(Memory memory) throws ExecutionError {
		var element = this.element.exec(memory);

		var executed_params = new ArrayList<Var>();
		foreach(var param in this.parameters) {
			executed_params.add(param.exec(memory));
		}
		if(element is Class) {
			return (element as Class).build(executed_params);
		} else {
			throw new ExecutionError.VAR("You can not instanciate variable " + this.element.serialize() + " that is not a class.");
		}
	}

	public override string serialize(int level = 0) {
		string[] strparams = new string[this.parameters.size];
		int i = 0;
		foreach(var parameter in this.parameters) {
			strparams[i] = parameter.serialize();
			i++;
		}
		return "new " + this.element.serialize() + "(" + string.joinv(", ", strparams) + ")";
	}
}
