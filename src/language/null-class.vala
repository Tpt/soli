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
 * The class of the null object
 */
public class NullClass : Class {
	protected static NullClass? self;

	public NullClass() {
		this.name = "null";
	}

	public override void init() throws ExecutionError {
	}

	public override Object build(ArrayList<Var> parameters) throws ExecutionError {
		return new NullObject();
	}

	public override Var get_var(Object object, string name) throws ExecutionError {
		throw new ExecutionError.VAR("Try to get variable " + name + " from null.");
	}

	public override void set_var(Object object, string name, Var val) throws ExecutionError {
		throw new ExecutionError.VAR("Try set get variable " + name + " from null.");
	}

	public override Var get_static_var(string name) throws ExecutionError {
		throw new ExecutionError.VAR("Try to get static variable " + name + " from null.");
	}

	public override void set_static_var(string name, Var val) throws ExecutionError {
		throw new ExecutionError.VAR("Try to set static variable " + name + " from null.");
	}

	public override Var? exec_method(Object object, string name, ArrayList<Var> parameters) throws ExecutionError {
		throw new ExecutionError.VAR("Try to execute variable " + name + " from null.");
	}

	public override Var? exec_static_method(string name, ArrayList<Var> parameters) throws ExecutionError {
		throw new ExecutionError.VAR("Try to execute static method " + name + " from null.");
	}

	protected override Var exec_mono_operator(string name, Object operand) throws ExecutionError {
		throw new ExecutionError.VAR("Try to execute operator " + name + " from null.");
	}

	protected override Var exec_dual_operator(string name, Object left_operand, Object right_operand) throws ExecutionError {
		throw new ExecutionError.VAR("Try to execute operator " + name + " from null.");
	}

	public override string to_string(Object object) throws ExecutionError {
		return "null";
	}

	public override bool to_bool(Object object) throws ExecutionError {
		return false;
	}

	public override string serialize(int level = 0) {
		return "";
	}

	public override uint hash(Object object) {
		return 0;
	}

	public static NullClass singleton() {
		if(self == null) {
			self = new NullClass();
		}
		return self;
	}
}
