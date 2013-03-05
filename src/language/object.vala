/*
 * Copyright (C) Thomas Pellissier Tanon 2013 <thomaspt@hotmail.fr>
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

public abstract class Object : Var {
	public Class instanceOf { get; protected set; }

	public override string serialize(int level = 0) {
		return this.to_string();
	}

	public string to_string() throws ExecutionError {
		return this.instanceOf.to_string(this);
	}

	public bool to_bool() throws ExecutionError {
		return this.instanceOf.to_bool(this);
	}
}

public class NullObject : Object {
	public NullObject() {
		this.instanceOf = NullClass.singleton();
	}	

	public override string serialize(int level = 0) {
		return "null";
	}
}

/**
 * A binding object T is the class bindinged
 */
public class BindingObject<T> : Object {
	public T val;

	public BindingObject(Class instanceOf, T val) {
		this.instanceOf = instanceOf;
		this.val = val;
	}
}

public class CustomObject : Object {
	public Memory vals { get; protected set; }

	public CustomObject(Class instanceOf) {
		this.instanceOf = instanceOf;
		this.vals = new Memory();
	}
}
