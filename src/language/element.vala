/*
 * Copyright (C) Thomas Pellissier Tanon 2012 <thomaspt@hotmail.fr>
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
 * An element of the program tree like a struct
 */ 
public abstract class Element : GLib.Object {
	public int line { get; protected set; default = 0; }

    public Element (int line) {
		this.line = line;
    }

	public abstract Var? exec(Memory memory) throws ExecutionError;

	/**
	 * An element of the program tree like a struct
	 */ 
	public abstract string serialize(int line = 0);
}

/**
 * An element that only contains an expression
 */ 
public class VoidElement : Element {
	protected Operator expression;

    public VoidElement(int line, Operator expression) {
		base(line);
        this.expression = expression;
    }

	public override Var? exec(Memory memory) throws ExecutionError {
		this.expression.exec(memory);
		return null;
	}

	public override string serialize(int line = 0) {
		return string.nfill(line, '	') + this.expression.serialize() + "\n";
	}
}

/**
 * An assignation
 */ 
public class LetElement : Element {
	protected Operator expression;
	protected Operator variable;

    public LetElement(int line, Operator variable, Operator expression) {
		base(line);
        this.expression = expression;
		this.variable = variable;
    }

	public override Var? exec(Memory memory) throws ExecutionError {
		if(this.variable is ObjectMember) {
			var variable = this.variable as ObjectMember;
			var elem = variable.element.exec(memory);
			if(elem is Object) {
				var object = elem as Object;
				object.instanceOf.set_var(object, variable.get_name(), this.expression.exec(memory));
			} else if(elem is Class) {
				(elem as Class).set_static_var(variable.get_name(), this.expression.exec(memory));
			} else {
				throw new ExecutionError.VAR("The variable " + this.variable.serialize() + " is not a class or an object at line " + this.line.to_string() + ".");
			}
		} else if(this.variable is DualOperandOperator && this.variable.get_name() == "[]") {
			var assignation = this.variable as DualOperandOperator;
			var variable = assignation.left_operand.exec(memory);
			if(variable is Object) { //TODO errors
				var object = variable as Object;
				var params = new ArrayList<Var>();
				params.add(assignation.right_operand.exec(memory));
				params.add(this.expression.exec(memory));
				return object.instanceOf.exec_method(object, "set", params);
			} else {
				throw new ExecutionError.VAR("You can not set array value in a not object at line " + this.line.to_string() + ".");
			}	
		} else if(this.variable is VarOperator) {
			var variable = this.variable.get_name();
			memory[variable] = this.expression.exec(memory);
		} else {
			throw new ExecutionError.VAR("The variable " + this.variable.serialize() + " is not a variable at line " + this.line.to_string() + ".");
		}
		return null;
	}

	public override string serialize(int line = 0) {
		return string.nfill(line, '	') + this.variable.serialize() + " = " + this.expression.serialize() + "\n";
	}
}

/**
 * A return
 */ 
public class ReturnElement : Element {
	protected Operator expression;

	public ReturnElement(int line, Operator expression) {
		base(line);
        this.expression = expression;
    }

	public override Var? exec(Memory memory) throws ExecutionError {
		return this.expression.exec(memory);
	}

	public override string serialize(int line = 0) {
		return string.nfill(line, '	') + "return " + this.expression.serialize() + "\n";
	}
}
