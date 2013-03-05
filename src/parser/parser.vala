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
 * The parser
 * @todo optimizations everywhere
 */
public class Parser : GLib.Object {
	protected int current_parsed_line = 0;

	public static MonoStruct parse(string text) throws ParserError {
		var parser = new Parser();
		var root = MainTokenizer.tokenize(text);
		var lines = parser.parse_lines(root.get_sub_lines());
		return new MonoStruct(-1, lines);
    }

	/**
	 * Main loop
	 */
	protected ArrayList<Element> parse_lines(ArrayList<LineToken> line_tokens) throws ParserError {
		var elements = new ArrayList<Element>();
		Element? last_element = null;
		foreach(var token in line_tokens) {
			if(token is RealLineToken) {
				var line = token as RealLineToken;
				Element? element = this.parse_declaration(line, ref last_element);
				if(element != null) {
					elements.add(element);
					last_element = element;
				}
			}
		}
		return elements;
	}

	/**
	 * Parse a declaration (ie a line without any particularity)
	 */
	protected Element? parse_declaration(RealLineToken line_token, ref Element? last_element) throws ParserError {
		var tokens = line_token.tokens.get_tokens();
		this.current_parsed_line = line_token.line;
		uint length = tokens.size;
		if(length == 0) {
			return null;
		}
		if(!(tokens[0] is IdentifierToken)) {
			throw new ParserError.LINE("The line " + this.current_parsed_line.to_string() + " has not a correct syntax.");
		}
		switch(tokens[0].get_content()) {
			case "if":
				var lines = this.parse_lines(line_token.get_sub_lines());
				return new IfStruct(this.current_parsed_line, this.parse_expression(this.get_list_part(tokens, 1)), lines);
			case "else":
				if(last_element != null && last_element is IfStruct) {
					var lines = this.parse_lines(line_token.get_sub_lines());
					if(length > 1 && tokens[1] is IdentifierToken && tokens[1].get_content() == "if") {
						var if_struct = new IfStruct(this.current_parsed_line, this.parse_expression(this.get_list_part(tokens, 2)), lines);
						var content = new ArrayList<Element>();
						content.add(if_struct);
						(last_element as IfStruct).add_else(content);
						last_element = if_struct;
					} else {
						(last_element as IfStruct).add_else(lines);
					}
					return null;
				}
				throw new ParserError.LINE("The else at line " + this.current_parsed_line.to_string() + " does not belongs to any if.");
			case "while":
				var lines = this.parse_lines(line_token.get_sub_lines());
				return new WhileStruct(this.current_parsed_line, this.parse_expression(this.get_list_part(tokens, 1)), lines);
			case "for":
				if(length > 3) {
					if(length > 5 && tokens[1] is IdentifierToken && tokens[2] is IdentifierToken && tokens[2].get_content() == "from") {
						var from = new ArrayList<Token>();
						int i = 3;
						while(i < length && (!(tokens[i] is IdentifierToken) || tokens[i].get_content() != "to")) {
							from.add(tokens[i]);
							i++;
						}
						i++;
						if(i < length) {
							var to = new ArrayList<Token>();
							while(i < length) {
								to.add(tokens[i]);
								i++;
							}
							var lines = this.parse_lines(line_token.get_sub_lines());
							return new ForStruct(this.current_parsed_line, this.parse_expression(from), this.parse_expression(to), tokens[1].get_content(), lines);
						}
					} else if(tokens[1] is IdentifierToken && tokens[2] is IdentifierToken && tokens[2].get_content() == "in") {
						//TODO for i in array 
					}
				}
				throw new ParserError.LINE("The for loop at line " + this.current_parsed_line.to_string() + " has not a correct syntax.");
			case "return":
				return new ReturnElement(this.current_parsed_line, this.parse_expression(this.get_list_part(tokens, 1)));
			case "function":
				if(length == 3 && tokens[1] is IdentifierToken && tokens[2] is ContainerToken) {
					var container = tokens[2] as ContainerToken;
					if(container.kind == ContainerToken.Type.PARENTHESIS) {
						var struc = new MonoStruct(this.current_parsed_line, this.parse_lines(line_token.get_sub_lines())); //TODO màj de l'ajout de sous-lignes
						var function = new Function(struc, this.parse_param_list(container.get_tokens()));
						return new LetElement(this.current_parsed_line, new VarOperator(tokens[1].get_content()), function);
					}
				}
				throw new ParserError.LINE("The function declaration at line " + this.current_parsed_line.to_string() + " has not a correct syntax.");
			case "class":
				if(tokens[1] is IdentifierToken) {
					string? parent = null;
					var ifaces = new ArrayList<string>();
					int i = 2;
					//parent
					if(length >= 4 && tokens[2] is OperatorToken && tokens[2].get_content() == ":") {
						if(tokens[3] is IdentifierToken) {
							parent = tokens[3].get_content();
						} else {
							throw new ParserError.LINE("Bad parent class name at line " + this.current_parsed_line.to_string());
						}
						i += 2;
					}
					//interfaces
					if(length >= i + 2 && tokens[i] is IdentifierToken && tokens[i].get_content() == "implements") {
						i++;
						while(i < length) {
							if(tokens[i] is IdentifierToken) {
								ifaces.add(tokens[i].get_content());
							}
							i++;
						}
					}
					var current_class = new CustomClass(tokens[1].get_content(), parent, ifaces);
					ClassProvider.singleton().register(current_class);
					this.add_members_to_class(current_class, line_token.get_sub_lines());
					return null;
				}
				throw new ParserError.LINE("Invalid class declaration at line " + this.current_parsed_line.to_string());
			default:
				if(length > 1) {
					string[] assign_operators = { "=", "+=", "-=", "*=", "/=", "++", "--" };
					int assign = 1;
					while(assign < length && !(tokens[assign] is OperatorToken && tokens[assign].get_content() in assign_operators)) {
						assign++;
					}
					if(assign < length) {
						return this.parse_assignation(line_token, this.parse_variable(tokens, 0, assign - 1), assign);
					}					
				}
				return new VoidElement(this.current_parsed_line, this.parse_expression(tokens));
		}
	}

	/**
	 * Parse a variable name, including array content and clas properties
	 */
	protected Operator parse_variable(ArrayList<Token> tokens, int begin, int end) throws ParserError {
		if(end < begin) {
			throw new ParserError.LINE("Variable parsing error at line " + this.current_parsed_line.to_string());
		}
		if(tokens[end] is ContainerToken) {
			var param = tokens[end] as ContainerToken;
			if(param.kind == ContainerToken.Type.SQUARE) {
				return new DualOperandOperator("[]", this.parse_variable(tokens, begin, end - 1), this.parse_expression(param.get_tokens()));
			}
			throw new ParserError.LINE("Invalid bracket at line " + this.current_parsed_line.to_string());
		} else if(end - 2 >= begin && tokens[end] is IdentifierToken && tokens[end - 1] is OperatorToken && tokens[end - 1].get_content() == ".") {
			return new ObjectMember(this.parse_variable(tokens, begin, end - 2), tokens[end].get_content());
		} else if(end == begin && tokens[end] is IdentifierToken) {
			return new VarOperator(tokens[end].get_content());
		} else {
			throw new ParserError.LINE("Variable parsing error at line " + this.current_parsed_line.to_string());
		}
	}

	/**
	 * Parse members of a class (its sub LineTokens)
	 */
	protected void add_members_to_class(CustomClass current_class, ArrayList<LineToken> line_tokens) throws ParserError {
		foreach(var token in line_tokens) {
			if(!(token is RealLineToken)) {
				continue;
			}
			var line_token = token as RealLineToken;
			this.current_parsed_line = line_token.line;
			var tokens = line_token.tokens.get_tokens();
			int length = (int) tokens.size;
			if(length == 0) {
				continue;
			}
			int i = 0;
			bool isStatic = false;
			if(tokens[0] is IdentifierToken && tokens[0].get_content() == "static") {
				isStatic = true;
				i++;
			}
			if(!(tokens[i] is IdentifierToken)) {
				throw new ParserError.LINE("The line " + this.current_parsed_line.to_string() + " n'a pas une syntaxe correcte.");
			}

			if(tokens[i].get_content() == "function" || tokens[i].get_content() == "operator") {
				if(tokens[length - 1] is ContainerToken) {
					var container = tokens[length - 1] as ContainerToken;
					if(container.kind == ContainerToken.Type.PARENTHESIS) {
						var struc = new MonoStruct(line_token.line, this.parse_lines(line_token.get_sub_lines()));
						var param = new ArrayList<string>();
						if(!isStatic) {
							param.add("this");
						}
						param.add("self");
						param.add_all(this.parse_param_list(container.get_tokens()));
						var function = new Function(struc, param);
						if(tokens[i].get_content() == "operator") {
							string operator = "";
							for(int j = i + 1; j < length - 1; j++) {
								if(tokens[j] is ContainerToken) {
									if(container.kind == ContainerToken.Type.SQUARE) {
										operator += "[]";
									} else {
										throw new ParserError.LINE("Invalid operator declaration at line " + this.current_parsed_line.to_string());
									}
								} else {
									operator += tokens[j].get_content();
								}
							}
							current_class.add_method("operator" + OperandOperator.normalise_name(operator), function);
							continue;
						} else if(tokens[i + 1] is IdentifierToken) {
							if(isStatic) {
								current_class.add_static_method(tokens[i + 1].get_content(), function);
							} else {
								current_class.add_method(tokens[i + 1].get_content(), function);
							}
							continue;
						}
					}
				}
				throw new ParserError.LINE("The method declaration at line " + this.current_parsed_line.to_string() + " is not valid.");
			} else if( length > i + 1 && tokens[i + 1] is OperatorToken && tokens[i + 1].get_content() == "=") {
				var expr = this.parse_expression(this.get_list_part(tokens, i + 2));
				if(isStatic) {
					current_class.add_static_var(tokens[i].get_content(), expr);
				} else {
					current_class.add_var(tokens[i].get_content(), expr);
				}
			} else {
				if(isStatic) {
					current_class.add_static_var(tokens[i].get_content(), new NullObject());
				} else {
					current_class.add_var(tokens[i].get_content(), new NullObject());
				}
			}
		}
	}


	/**
	 * Parse an assignation (the "= 1 + 2" part of "a[b] = 1 + 2")
	 */
	protected LetElement parse_assignation(RealLineToken line_token, Operator set_variable, int i = 0) throws ParserError {
		var tokens = line_token.tokens.get_tokens();
		if(tokens[i] is OperatorToken) {
			switch(tokens[i].get_content()) {
				case "=":
					if(tokens.size == i + 3 && tokens[i + 1] is IdentifierToken && tokens[i + 1].get_content() == "function") {
						if(tokens[i + 2] is ContainerToken) {
							var param = tokens[i + 2] as ContainerToken;
							if(param.kind == ContainerToken.Type.PARENTHESIS) {
								var struc = new MonoStruct(this.current_parsed_line, this.parse_lines(line_token.get_sub_lines()));
								var function = new Function(struc, this.parse_param_list((tokens[i + 2] as ContainerToken).get_tokens()));
								var let = new LetElement(this.current_parsed_line, set_variable, function);
								return let;
							}
						}
						throw new ParserError.LINE("The function declaration at line " + this.current_parsed_line.to_string() + " has not a correct syntax.");
					} else {
						return new LetElement(this.current_parsed_line, set_variable, this.parse_expression(this.get_list_part(tokens, i + 1)));
					}
				case "+=":
					var operator = new DualOperandOperator("+", set_variable, this.parse_expression(this.get_list_part(tokens, i + 1)));
					return new LetElement(this.current_parsed_line, set_variable, operator);
				case "-=":
					var operator = new DualOperandOperator("-", set_variable, this.parse_expression(this.get_list_part(tokens, i + 1)));
					return new LetElement(this.current_parsed_line, set_variable, operator);
				case "*=":
					var operator = new DualOperandOperator("*", set_variable, this.parse_expression(this.get_list_part(tokens, i + 1)));
					return new LetElement(this.current_parsed_line, set_variable, operator);
				case "/=":
					var operator = new DualOperandOperator("/", set_variable, this.parse_expression(this.get_list_part(tokens, i + 1)));
					return new LetElement(this.current_parsed_line, set_variable, operator);
				case "++":
					var operator = new DualOperandOperator("+", set_variable, Integer.singleton().new_from_long(1));
					return new LetElement(this.current_parsed_line, set_variable, operator);
				case "--":
					var operator = new DualOperandOperator("_", set_variable, Integer.singleton().new_from_long(1));
					return new LetElement(this.current_parsed_line, set_variable, operator);
			}
		}
		throw new ParserError.LINE("Unknown assignation for " + set_variable.serialize() + " at line " + this.current_parsed_line.to_string());
	}

	/**
	 * Returns a part of a list
	 */
	protected ArrayList<Token> get_list_part(ArrayList<Token> list, int beginning) {
		var new_list = new ArrayList<Token>();
		int i = 0;
		foreach(var elem in list) {
			if(i >= beginning) {
				new_list.add(elem);
			}
			i++;
		}
		return new_list;
	}

	/**
	 * Parse an expression like "1 > 2 + -1"
	 */
	protected Operator parse_expression(ArrayList<Token> tokens) throws ParserError {
		return do_expression_parse(
			tokens,
			{ "or", "||" },
			parse_and_expression
		);
	}
	protected Operator parse_and_expression(ArrayList<Token> tokens) throws ParserError {
		return do_expression_parse(
			tokens,
			{ "and", "&&" },
			parse_eq_expression
		);
	}
	protected Operator parse_eq_expression(ArrayList<Token> tokens) throws ParserError {
		return do_expression_parse(
			tokens,
			{ ">", "<", "<=", ">=", "=", "!=" },
			parse_num_expression
		);
	}
	protected Operator parse_num_expression(ArrayList<Token> tokens) throws ParserError {
		return do_expression_parse(
			tokens,
			{ "+", "-" },
			parse_prod_expression
		);
	}
	protected Operator parse_prod_expression(ArrayList<Token> tokens) throws ParserError {
		return do_expression_parse(
			tokens,
			{ "*", "/", "%" },
			parse_value
		);
	}


	/**
	 * Make a step of the operation parser: find operators of the same level and ask recursively for the parse of remanings tokens
	 */
	protected Operator do_expression_parse(ArrayList<Token> tokens, string[] operators, ExpressionParser inside_parser) throws ParserError {
		uint length = tokens.size;
		if(length == 0) {
			throw new ParserError.LINE("Empty expression at line " + this.current_parsed_line.to_string());
		}
		var sub_tokens = new ArrayList<Token>();
		string operator = "";
		Operator? tree = null;
		foreach(var token in tokens) {
			if( !sub_tokens.is_empty && (token is OperatorToken || token is IdentifierToken) && token.get_content() in operators) {
				if(tree == null) {
					tree = inside_parser(sub_tokens);
				} else {
					tree = new DualOperandOperator(operator, tree, inside_parser(sub_tokens));
				}
				operator = token.get_content();
				sub_tokens = new ArrayList<Token>();
			} else {
				sub_tokens.add(token);
			}
		}
		if(tree == null) {
			return inside_parser(sub_tokens);
		} else {
			return new DualOperandOperator(operator, tree, inside_parser(sub_tokens));
		}
	}
	protected delegate Operator ExpressionParser(ArrayList<Token> tokens) throws ParserError;


	/**
	 * Parse a value like -1.2, "test", class.method(12)...
	 */
	protected Operator parse_value(ArrayList<Token> tokens) throws ParserError {
		return parse_value_internal(tokens, 0, tokens.size - 1);
	}

	protected Operator parse_value_internal(ArrayList<Token> tokens, int begin, int end) throws ParserError {
		if(end < begin) {
			throw new ParserError.LINE("Empty value at line " + this.current_parsed_line.to_string());
		}
		if(tokens[begin] is OperatorToken || tokens[begin] is IdentifierToken && tokens[begin].get_content() == "not") {
			//Unary operator
			string[] unary_operators = {"-", "!", "not"};
			if(!(tokens[begin].get_content() in unary_operators)) {
				throw new ParserError.LINE("Unknown unary operator " + tokens[0].get_content() + "at line " + this.current_parsed_line.to_string());
			}
			return new MonoOperandOperator(tokens[0].get_content(), this.parse_value_internal(tokens, begin + 1, end));
		} else if(end > begin && tokens[end] is ContainerToken) {
			//function and array call
			var param = tokens[end] as ContainerToken;
			switch(param.kind) {
				case ContainerToken.Type.PARENTHESIS:
					if(tokens[begin] is IdentifierToken && tokens[begin].get_content() == "new") {
						//class instantiation
						return new InstanceOperator(this.parse_value_internal(tokens, begin + 1, end - 1), this.parse_function_params(param.get_tokens()));
					} else {
						return new FunctionOperator(this.parse_value_internal(tokens, begin, end - 1), this.parse_function_params(param.get_tokens()));
					}
				case ContainerToken.Type.SQUARE:
					return new DualOperandOperator("[]", this.parse_value_internal(tokens, begin, end - 1), this.parse_expression(param.get_tokens()));
				default:
					throw new ParserError.LINE("Invalid Parenthesis at line " + this.current_parsed_line.to_string());
			}
			throw new ParserError.LINE("Invalid bracket at line " + this.current_parsed_line.to_string());
		} else if(end - 2 >= begin && tokens[end] is IdentifierToken && tokens[end - 1] is OperatorToken && tokens[end - 1].get_content() == ".") {

			//object parameter call
			return new ObjectMember(this.parse_value_internal(tokens, begin, end - 2), tokens[end].get_content());
		}
		if(begin != end) {
			throw new ParserError.LINE("Unknown value at line " + this.current_parsed_line.to_string());
		}
		var token = tokens[begin];
		if(token is StringToken) {
			return String.singleton().new_from_string(token.get_content());
		} else if(token is NumberToken) {
			var val = token.get_content();
			if(StringUtils.contain(val, '.') || StringUtils.contain(val, ',')) {
				return Float.singleton().new_from_string(val);
			} else {
				return Integer.singleton().new_from_string(val);
			}
		} else if(token is ContainerToken) {
			var container = token as ContainerToken;
			switch(container.kind) {
				case ContainerToken.Type.PARENTHESIS:
					return this.parse_expression(container.get_tokens());
				case ContainerToken.Type.SQUARE:
					return new CollectionOperator(this.parse_function_params(container.get_tokens()));
				default:
					throw new ParserError.LINE("Invalid Parenthesis at line " + this.current_parsed_line.to_string());
			}
		} else {
			switch(token.get_content()) {
				case "true":
					return Boolean.singleton().new_from_bool(true);
				case "false":
					return Boolean.singleton().new_from_bool(false);
				case "null":
					return new NullObject();
				default:
					return new VarOperator(token.get_content());
			}
		}
	}


	/**
	 * Parse the declaration of function parameters like "a, b, c"
	 */
	protected ArrayList<string> parse_param_list(ArrayList<Token> tokens) throws ParserError {
		var var_names = new ArrayList<string>();
		foreach(var token in tokens) {
			if(token is IdentifierToken) {
				var_names.add(token.get_content());
			}
		}
		return var_names;
    }

	/**
	 * Parse list of parameters given to a function
	 */
	protected ArrayList<Operator> parse_function_params(ArrayList<Token> tokens) throws ParserError {
		var parameters = new ArrayList<Operator>();
		var buffer = new ArrayList<Token>();
		foreach(var token in tokens) {
			if(token is OperatorToken && token.get_content() == ",") {
				parameters.add(this.parse_expression(buffer));
				buffer = new ArrayList<Token>();
			} else {
				buffer.add(token);
			}
		}
		if(buffer.size != 0) {
			parameters.add(this.parse_expression(buffer));
		}
		return parameters;
    }
}
