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
 * Tokenize a text
 */
public class MainTokenizer : GLib.Object {
	protected RootLineToken root;
	protected LineToken current_father_line;

	public static RootLineToken tokenize(string text) throws ParserError {
		var tokenizer = new MainTokenizer();
		tokenizer.work(text);
		return tokenizer.root;
	}

	protected void work(string text) throws ParserError {
		this.root = new RootLineToken();
		this.current_father_line = this.root as LineToken;
		var lines = StringUtils.split(text, '\n');
		int i = 0;
		foreach(string line in lines) {
			int level = 0;
			while(line[level] in StringUtils.EMPTY_CHARS) {
				level++;
			}
			if(line.length > level) {
				var token = new RealLineToken(i + 1, level, LineTokenizer.tokenize(line.substring(level)));
				this.set_in_tree(token as LineToken);
			}
			i++;
		}
	}

	protected void set_in_tree(LineToken line) {
		while(this.current_father_line.level >= line.level) {
			this.current_father_line = this.current_father_line.father;
		}
		line.father = this.current_father_line;
		this.current_father_line.add_sub_line(line);
		this.current_father_line = line;
	}
}


/**
 * Tokenize a line
 * @todo UTF-8 support
 */
public class LineTokenizer : GLib.Object {
	/*
	 * In order to make the tokenizer work, the operators should be sort by decreasing length.
	 */
	protected const string[] OPERATORS = {
		".", ",", "=", ":", //Generic operators
		"++", "+=", "+", "--", "-=", "-", "*=", "*", "/=", "/", "%=", "%", //Math operators
		"&&", "||", ">=", ">", "<=", "<", "!=", "!" //Bollean operators
		};
	protected string text = "";
	protected char[] chars = {};
	protected ContainerToken main_token;
	protected ContainerToken current_father_token;
	protected int length;

	protected LineTokenizer(string text) {
		this.text = text;
		this.chars = text.to_utf8();
		this.length = this.chars.length;
		this.main_token = new ContainerToken(ContainerToken.Type.MAIN);
		this.current_father_token = this.main_token;
	}

	public static ContainerToken tokenize(string text) throws ParserError {
		var tokenizer = new LineTokenizer(text);
		tokenizer.work();
		return tokenizer.main_token;
	}

	protected void work() throws ParserError {
		int next = 0;
		while(next < this.length) {
      		next = this.find_token(next);
    	}
	}

	/**
	 * Add the next token to the tree
	 */
	protected int find_token(int next) throws ParserError {
		var val = this.chars[next];
		if(val == ' ' || val == '\t') {
			return next + 1;
		} else if(val == '{') {
			return this.tokenize_open_bracket(ContainerToken.Type.CURLY, next);
		} else if(val == '}') {
			return this.tokenize_close_bracket(ContainerToken.Type.CURLY, next);
		} else if(val == '[') {
			return this.tokenize_open_bracket(ContainerToken.Type.SQUARE, next);
		} else if(val == ']') {
			return this.tokenize_close_bracket(ContainerToken.Type.SQUARE, next);
		} else if(val == '(') {
			return this.tokenize_open_bracket(ContainerToken.Type.PARENTHESIS, next);
		} else if(val == ')') {
			return this.tokenize_close_bracket(ContainerToken.Type.PARENTHESIS, next);
		} else if(val.isdigit()) {
			return this.tokenize_number(next);
		} else if(val.isalpha() || val == '_' || val == '$') {
			return this.tokenize_identifier(next);
		} else if(val == '"' || val == '\'') {
			return this.tokenize_string(val, next);
		} else if(val == '#') {
			return this.tokenize_sharp_comment(next);
		} else {
			return this.tokenize_operator(next);
		}
	}

	protected void add_token(Token token) {
		this.current_father_token.append(token);
	}

	protected void add_operator_token(string content) {
		var token = new OperatorToken(content);
		this.add_token(token);
	}

	protected int tokenize_open_bracket(ContainerToken.Type type, int next) {
		var token = new ContainerToken(type, this.current_father_token);
		this.current_father_token.append(token);
		this.current_father_token = token;
		return next + 1;
	}

	protected int tokenize_close_bracket(ContainerToken.Type type, int next) throws ParserError {
		if(this.current_father_token == null || this.current_father_token.kind != type) {
			throw new ParserError.LINE("Error in brackets in: " + this.text);
		} else {
			this.current_father_token = this.current_father_token.father;
		}
		return next + 1;
	}

	protected int tokenize_number(int next) {
		var builder = new StringBuilder();
		while(next < this.length && (this.chars[next].isdigit() || this.chars[next] == '.')) {
			builder.append_unichar(this.chars[next]);
			next++;
		}
		this.add_token(new NumberToken(builder.str));
		return next;
	}

	protected int tokenize_identifier(int next) {
		var builder = new StringBuilder();
		while(next < this.length && (this.chars[next].isalpha() || this.chars[next].isdigit() || this.chars[next] == '_' || this.chars[next] == '$')) {
			builder.append_unichar(this.chars[next]);
			next++;
		}
		this.add_token(new IdentifierToken(builder.str));
		return next;
	}

	protected int tokenize_string(unichar delimiter, int next) {
		var builder = new StringBuilder();
		next++;
		while(next < this.length && this.chars[next] != delimiter) {
			if(this.chars[next] == '\\' && next + 1 < this.length && this.chars[next + 1] == delimiter) {
				next++;
			}
			builder.append_unichar(this.chars[next]);
			next++;
		}
		this.add_token(new StringToken(builder.str));
		return next + 1;
	}

	protected int tokenize_operator(int next) throws ParserError {
		foreach(string op in OPERATORS) {
			int i = 0;
			int j = next;
			while(i < op.length && j < this.length && op[i] == this.chars[j]) {
				i++;
				j++;
			}
			if(i == op.length) {
				this.add_operator_token(op);
				return j;
			}
		}
		throw new ParserError.LINE("Unknown operator in: " + this.text );
	}

	protected int tokenize_sharp_comment(int next) {
		next++;
		while(next < length && this.chars[next] != '#') {
			next++;
		}
		return next + 1;
	}
}


/**
 * A token
 */
public abstract class Token : GLib.Object {
	public abstract string get_content();

	/**
	 * Returns the token tree as string
	 */
	public abstract string serialize();
}

/**
 * Generic token
 */
public abstract class ValueToken : Token {
	public string content;

	public ValueToken(string content) {
		this.content = content;
	}

	public override string get_content() {
		return this.content;
	}

	public override string serialize() {
		return this.content;
	}
}

/**
 * A string
 */
public class StringToken : ValueToken {
	public StringToken(string content) {
		base(content);
	}

	public override string serialize() {
		return "\"" + this.content + "\"";
	}
}

/**
 * An identifier (variable, function and class names, language keywords...)
 */
public class IdentifierToken : ValueToken {
	public IdentifierToken(string content) {
		base(content);
	}
}

/**
 * A number (int or float)
 */
public class NumberToken : ValueToken {
	public NumberToken(string content) {
		base(content);
	}
}

/**
 * An operator
 */
public class OperatorToken : ValueToken {
	public OperatorToken(string content) {
		base(content);
	}
}


/**
 * A token that contains some other token. It can have no special meaning (MAIN type) or represent brackets.
 */
public class ContainerToken : Token {
	public enum Type { MAIN, CURLY, SQUARE, PARENTHESIS }
	protected ArrayList<Token> tokens = new ArrayList<Token>();
	public Type kind { get; protected set; }
	public ContainerToken? father { get; protected set; }

	public ContainerToken(Type kind, ContainerToken? father = null) {
		this.kind = kind;
		this.father = father;
		this.tokens = new ArrayList<Token>();
	}

	public override string get_content() {
		return "";
	}

	public void append(Token token) {
		this.tokens.add(token);
	}

	public override string serialize() {
		string open = "";
		string close = "";
		switch(this.kind) {
			case Type.CURLY:
				open = "{";
				close = "}";
				break;
			case Type.SQUARE:
				open = "[";
				close = "]";
				break;
			case Type.PARENTHESIS:
				open = "(";
				close = ")";
				break;
		}
		string str = open;
		foreach(var token in this.tokens)  {
			str += token.serialize() + " ";
		}
		return str + close;
	}

	public ArrayList<Token> get_tokens() {
		return this.tokens;
	}
}


/**
 * A line
 */
public abstract class LineToken : GLib.Object {
	protected ArrayList<LineToken> sub_lines = new ArrayList<LineToken>();
	public LineToken? father;
	public int level { get; protected set; default = 0; }

	public void add_sub_line(LineToken line) {
		this.sub_lines.add(line);
	}

	public abstract string serialize();

	public ArrayList<LineToken> get_sub_lines() {
		return this.sub_lines;
	}
}

/**
 * A line that exists really (ie not the "line" that contains the code tokenized).
 */
public class RealLineToken : LineToken {
	public ContainerToken tokens { get; protected set; }
	public int line { get; protected set; default = -1; }

	public RealLineToken(int line, int level, ContainerToken tokens) {
		this.line = line;
		this.level = level;
		this.tokens = tokens;
	}

	public override string serialize() {
		string str = this.level.to_string() + ": " + tokens.serialize() + "\n<-";
		foreach(var line in this.sub_lines)  {
			str += line.serialize();
		}
		return str + "->";
	}
}

public class RootLineToken : LineToken {

	public RootLineToken() {
		this.level = -1;
	}

	public override string serialize() {
		string str = "";
		foreach(var line in this.sub_lines)  {
			str += line.serialize();
		}
		return str;
	}
}

