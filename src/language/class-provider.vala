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
 * Class storage
 */
public class ClassProvider : Gee.HashMap<string,Class> {
	protected static ClassProvider? self;

	public new Class get_class(string name) throws ExecutionError {
		if(name in this.keys) {
			return this[name];
		} else {
			throw new ExecutionError.VAR("The class " + name + " doesn't exists");
		}
	}

	public void register(Class val) {
		this[val.name] = val;
	}

	public void initialize() throws ExecutionError {
		this.register_libs();
		foreach(var elem in this.values) {
			elem.init();
		}
	}

	public static ClassProvider singleton() {
		if(self == null) {
			self = new ClassProvider();
		}
		return self;
	}

	/**
	 * @todo make it extensible
	 */
	public void register_libs() {
		this.register(Boolean.singleton());
		this.register(Integer.singleton());
		this.register(String.singleton());
		this.register(Collection.singleton());
		this.register(Map.singleton());
	}
}
