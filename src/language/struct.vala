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
 * A structure like if/else, while...
 */
public abstract class Struct : Element {	

    public Struct(int level) {
		base(level);
    }

	protected Var? exec_list(ArrayList<Element> elements, Memory memory) throws ExecutionError {
		Var? final_value;
		foreach(var element in elements) {
			final_value = element.exec(memory);
			if(final_value != null) {
				return final_value;
			}
		}
		return null;
	}

	/**
	 * Ecec the expression and returns a boolean value. Useful for subclasses
	 */
	protected bool exec_to_bool(Operator expression, Memory memory) throws ExecutionError {
		var val = expression.exec(memory);
		if(val is Object) {
			return (val as Object).to_bool();
		}
		throw new ExecutionError.TYPE("The condition does not return an object at line " + this.line.to_string() + ".");
	}
}

/**
 * A structure that contains only one list ob sub-elements
 */
public class MonoStruct : Struct {	
	protected ArrayList<Element> elements;

    public MonoStruct(int line, ArrayList<Element> elements) {
		base(line);
		this.elements = elements;
    }

	public override Var? exec(Memory memory) throws ExecutionError {
		return this.exec_list(this.elements, memory);
	}

	public override string serialize(int level = 0) {
		string str = "";
		foreach(var element in elements) {
			str += element.serialize(level + 1);
		}
		return str;
	}
}

public class WhileStruct : MonoStruct {
	protected Operator condition;

    public WhileStruct(int line, Operator condition, ArrayList<Element> elements) {
		base(line, elements);
        this.condition = condition;
    }

	public override Var? exec(Memory memory) throws ExecutionError {
		int i = 0;
		Var? final_value;
		var cond = this.exec_to_bool(this.condition, memory);
		while(cond && i < 1000) {
			final_value = this.exec_list(this.elements, memory);
			if(final_value != null)
				return final_value;
			cond = this.exec_to_bool(this.condition, memory);
			i++;
		}
		return null;
	}

	public override string serialize(int level = 0) {
		string str = string.nfill(level, '	') + "while " + this.condition.serialize() + "\n";
		foreach(var element in elements) {
			str += element.serialize(level + 1);
		}
		return str;
	}
}

public class ForStruct : MonoStruct {
	protected Operator begin;
	protected Operator end;
	protected string variable;

    public ForStruct(int line, Operator begin, Operator end, string variable, ArrayList<Element> elements) {
		base(line, elements);
        this.begin = begin;
		this.end = end;
		this.variable = variable;
    }

	public override Var? exec(Memory memory) throws ExecutionError {
		var begin_var = this.begin.exec(memory);
		if(!(begin_var is Object) || !((begin_var as Object).instanceOf is Integer)) {
			throw new ExecutionError.TYPE("The begin parameter of the for loop must be an integer at line " + this.line.to_string() + ".");
		}
		long begin = (begin_var as BindingObject<long>).val;

		var end_var = this.end.exec(memory);
		if(!(end_var is Object) || !((end_var as Object).instanceOf is Integer)) {
			throw new ExecutionError.TYPE("The end parameter of the for loop must be an integer at line " + this.line.to_string() + ".");
		}
		long end = (end_var as BindingObject<long>).val;

		Var? final_value;
		for(long i = begin; i <= end; i++) {
			memory[this.variable] = Integer.singleton().new_from_long(i);
			final_value = this.exec_list(this.elements, memory);
			if(final_value != null)
				return final_value;
		}
		return null;
	}

	public override string serialize(int level = 0) {
		string str = string.nfill(level, '	') + "for " + this.begin.serialize() + " to " + this.end.serialize() + "\n";
		foreach(var element in elements) {
			str += element.serialize(level + 1);
		}
		return str;
	}
}

/**
 * a structure that contains two lists of sub-elements
 */
public class DualStruct : Struct {	
	protected ArrayList<Element> elements1;
	protected ArrayList<Element> elements2;

    public DualStruct(int line, ArrayList<Element> elements1, ArrayList<Element> elements2) {
		base(line);
        this.elements1 = elements1;
		this.elements2 = elements2;
    }

	public override Var? exec(Memory memory) throws ExecutionError {
		Var? final_value;
		final_value = this.exec_list(this.elements1, memory);
		if(final_value != null)
			return final_value;
		else
			return this.exec_list(this.elements2, memory);
	}

	public override string serialize(int level = 0) {
		string str = "";
		foreach(var element in elements1) {
			str += element.serialize(level + 1);
		}
		str += "\n";
		foreach(var element in elements2) {
			str += element.serialize(level + 1);
		}
		return str;
	}
}

public class IfStruct : DualStruct {
	protected Operator condition;

    public IfStruct(int line, Operator condition, ArrayList<Element> elements1) {
		base(line, elements1, new ArrayList<Element>());
        this.condition = condition;
    }

	public void add_else(ArrayList<Element> elements) {
		this.elements2 = elements;
	}

	public override Var? exec(Memory memory) throws ExecutionError {
		var cond = this.exec_to_bool(this.condition, memory);
		if(cond) {
			return this.exec_list(this.elements1, memory);
		} else {
			return this.exec_list(this.elements2, memory);
		}
	}

	public override string serialize(int level = 0) {
		string str = string.nfill(level, '	') + "if " + this.condition.serialize() + "\n";
		foreach(var element in elements1) {
			str += element.serialize(level + 1);
		}
		str += string.nfill(level, '	') + "else\n";
		foreach(var element in elements2) {
			str += element.serialize(level + 1);
		}
		return str;
	}
}
