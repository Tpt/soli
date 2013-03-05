/*
 * Copyright (C) Thomas Pellissier Tanon 2012 <thomaspt@hotmail.fr>
 *
 * cilm is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * cilm is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
using Gee;

public abstract class Operator : GLib.Object {
	protected string name = "";

	public abstract Var exec(Memory memory) throws ExecutionError;

	public string get_name()  {
		return this.name;
	}

	public abstract string serialize(int level = 0);
}

public class CollectionOperator : Operator {
	protected ArrayList<Operator> elements;

	public CollectionOperator(ArrayList<Operator> elements) {
		this.elements = elements;
		this.name = "collection";
	}
	
	public override Var exec(Memory memory) throws ExecutionError {
		var vals = new ArrayList<Var>();
		foreach(var val in this.elements) {
			vals.add(val.exec(memory));
		}
		return Collection.singleton().new_from_list(vals);
	}

	public override string serialize(int level = 0) {
		var vals = new ArrayList<string>();
		foreach(var val in this.elements) {
			vals.add(val.serialize());
		}
		return "[" + StringUtils.joinv(", ", vals) + "]";
	}
}

public class VarOperator : Operator {

	public VarOperator(string name) {
		this.name = name;
	}
	
	public override Var exec(Memory memory) throws ExecutionError {
		if(name in memory.keys) {
			return memory[name];
		} if(name in ClassProvider.singleton().keys) {
			return ClassProvider.singleton().get_class(name);
		} else {
			throw new ExecutionError.VAR("The variable " + name + " doesn't exists");
		}
	}

	public override string serialize(int level = 0) {
		return this.name;
	}
}

public abstract class OperandOperator : Operator {
	public static string normalise_name(string name) {
		switch(name) {
			case "and":
				return "&&";
			case "or":
				return "||";
			case "not":
				return "!";
			default:
				return name;
		}
	}
}

public class MonoOperandOperator : OperandOperator {
	protected Operator operand;

	public MonoOperandOperator(string name, Operator operand) {
		this.name = normalise_name(name);
		this.operand = operand;
	}
	
	public override Var exec(Memory memory) throws ExecutionError {
		var executed_operand = this.operand.exec(memory);
		if(executed_operand is Object) {
			var object = executed_operand as Object;
			return object.instanceOf.exec_mono_operator(this.name, object);
		}
		throw new ExecutionError.TYPE("Operation on non objects.");
	}

	public override string serialize(int level = 0) {
		return "(" + this.name + this.operand.serialize(level + 1) + ")";
	}
}

public class DualOperandOperator : OperandOperator {
	public Operator left_operand { get; protected set; }
	public Operator right_operand { get; protected set; }

	public DualOperandOperator(string name, Operator left_operand, Operator right_operand) {
		this.name = normalise_name(name);
		this.left_operand = left_operand;
		this.right_operand = right_operand;
	}
	
	public override Var exec(Memory memory) throws ExecutionError {
		//TODO clever typing
		var executed_left_operand = this.left_operand.exec(memory);
		var executed_right_operand = this.right_operand.exec(memory);
		if(executed_left_operand is Object && executed_right_operand is Object) {
			var left_object = executed_left_operand as Object;
			var right_object = executed_right_operand as Object;
			return left_object.instanceOf.exec_dual_operator(this.name, left_object, right_object);
		}
		throw new ExecutionError.TYPE("Operation on non objects.");
	}

	public override string serialize(int level = 0) {
		return "(" + this.left_operand.serialize(level + 1) + " " + this.name + " " + this.right_operand.serialize(level + 1) + ")";
	}
}
