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
 * A class that is related to a Vala class T
 */
public abstract class BindingClass<T> : Class {

	public override void init() throws ExecutionError {
	}

	/**
	 * Returns the Vala native object from the Object
	 */
	protected T get_object(Object object) throws ExecutionError {
		/*if(!(object is BindingObject<T>)) {
			throw new ExecutionError.VAR("The variable " + name + " is not a valid " + this.name + " object.");
		} TODO */
		return (object as BindingObject<T>).val;
	}

	public override Var get_var(Object object, string name) throws ExecutionError {
		if(this.parent != null) {
			return this.parent.get_var(object, name);
		} else {
			throw new ExecutionError.VAR("The variable " + name + " of the class " + this.name + " does not exist.");
		}
	}

	public override void set_var(Object object, string name, Var val) throws ExecutionError {
		if(this.parent != null) {
			this.parent.set_var(object, name, val);
		} else {
			throw new ExecutionError.VAR("The variable " + name + " of the class " + this.name + " does not exist.");
		}
	}

	public override Var get_static_var(string name) throws ExecutionError {
		if(this.parent != null) {
			return this.parent.get_static_var(name);
		} else {
			throw new ExecutionError.VAR("The static variable " + name + " of the class " + this.name + " does not exist.");
		}
	}

	public override void set_static_var(string name, Var val) throws ExecutionError {
		if(this.parent != null) {
			this.parent.set_static_var(name, val);
		} else {
			throw new ExecutionError.VAR("The static variable " + name + " of the class " + this.name + " does not exist.");
		}
	}

	public override Var? exec_method(Object object, string name, ArrayList<Var> parameters) throws ExecutionError {
		switch(name) {
			case "toString":
				return String.singleton().new_from_string(this.to_string(object));
		}
		if(this.parent != null) {
			return this.parent.exec_method(object, name, parameters);
		} else {
			throw new ExecutionError.VAR("The method " + name + " of the class " + this.name + " does not exist.");
		}
	}

	public override Var? exec_static_method(string name, ArrayList<Var> parameters) throws ExecutionError {
		if(this.parent != null) {
			return this.parent.exec_static_method(name, parameters);
		} else {
			throw new ExecutionError.VAR("The static method " + name + " of the class " + this.name + " does not exist.");
		}
	}

	protected override Var exec_mono_operator(string name, Object operand) throws ExecutionError {
		if(this.parent != null) {
			return this.parent.exec_mono_operator(name, operand);
		} else {
			throw new ExecutionError.VAR("The mono operand operator " + name + " is not supported by class " + this.name + ".");
		}
	}

	protected override Var exec_dual_operator(string name, Object left_operand, Object right_operand) throws ExecutionError {
		if(this.parent != null) {
			return this.parent.exec_dual_operator(name, left_operand, right_operand);
		} else {
			throw new ExecutionError.VAR("The dual operand operator " + name + " is not supported by class " + this.name + ".");
		}
	}

	public override string to_string(Object object) throws ExecutionError {
		return this.name;
	}

	public override bool to_bool(Object object) throws ExecutionError {
		return true;
	}

	public override string serialize(int level = 0) {
		return "";
	}

	public override uint hash(Object object) {
		return direct_hash((object as BindingObject<T>).val);
	}
}
