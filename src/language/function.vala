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
 * A function
 */
public class Function : Var {
	public MonoStruct content {get; protected set;}
	public ArrayList<string> var_names {get; protected set;}

	public Function(MonoStruct content, ArrayList<string> var_names) {
		base();
		this.var_names = var_names;
		this.content = content;
		this.name = "fonction";
	}

	public new Var? exec_function(ArrayList<Var> parameters) throws ExecutionError {
		if(parameters.size != this.var_names.size) {
			throw new ExecutionError.EXPRESSION("The number of parameters at the call for the function is bad.");
		}
		var memory = new Memory();
		int i = 0;
		foreach(var param in parameters) {
			memory[this.var_names[i]] = param;
			i++;
		}
		return content.exec(memory);
	}

	public override string serialize(int line = 0) {
		return "function(" + StringUtils.joinv(", ", this.var_names) + ")" + "\n" + this.content.serialize(line + 1);
	}
}

/**
 * An operator that call a function and returns its value
 */
public class FunctionOperator : Operator {
	public ArrayList<Operator> parameters {get; protected set;}
	protected Operator element;

	public FunctionOperator(Operator element, ArrayList<Operator> parameters) {
		this.element = element;
		this.parameters = parameters;
	}
	
	public override Var exec(Memory memory) throws ExecutionError {
		var executed_params = new ArrayList<Var>();
		foreach(var param in this.parameters) {
			executed_params.add(param.exec(memory));
		}

		if(this.element is ObjectMember) {
			var element = this.element as ObjectMember;
			var elem = element.element.exec(memory);
			if(elem is Object) {
				var object = elem as Object;
				return object.instanceOf.exec_method(object, element.get_name(), executed_params);
			} else if(elem is Class) {
				return (elem as Class).exec_static_method(element.get_name(), executed_params);
			} else {
				throw new ExecutionError.VAR("The variable " + element.element.serialize() + " is not a class or an object.");
			}
		} else {
			var element = this.element.exec(memory);
			if(element is Function) {
				return (element as Function).exec_function(executed_params);
			} else {
				throw new ExecutionError.VAR("" + this.element.serialize() + " is not a function or method.");
			}
		}
	}

	public override string serialize(int line = 0) {
		string[] strparams = new string[this.parameters.size];
		int i = 0;
		foreach(var parameter in this.parameters) {
			strparams[i] = parameter.serialize();
			i++;
		}
		return this.element.serialize() + "(" + string.joinv(", ", strparams) + ")";
	}
}
