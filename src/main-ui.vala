/*
 * Copyright (C) Thomas Pellissier Tanon 2013 <thomaspt@hotmail.fr>
 *
 * soli is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * soli is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gtk;
using Config;

public class MainUi : Gtk.Application {
	protected string filename = "";
	protected ApplicationWindow window;
	protected SourceView source_view;

	protected const GLib.ActionEntry[] action_entries = {
		{ "quit",  quit_cb   },
		{ "about", on_about_clicked  }
	};

	public MainUi( string filename = "") {
		this.application_id = "org.gnome.soli";
		this.flags = ApplicationFlags.FLAGS_NONE;
		this.filename = filename;
		this.add_action_entries(action_entries, this);
	}

	public static int show(string[] args, string filename = "") {
		var app = new MainUi(filename);
		return app.run(args);
	}


	protected override void activate() {
		this.init_menu();
		this.init_window();
	}

	public void init_window() {
		this.window = new ApplicationWindow(this);
		this.window.set_default_size (500, 400);
		this.window.title = "SOL intepreter";

		var box = new Box(Gtk.Orientation.VERTICAL, 0);
		box.pack_start(this.make_toolbar(), false);
		var content = new ScrolledWindow(null, null);
		content.add(this.make_source_view());
		box.pack_start(content);
		this.window.add(box);
		this.window.show_all();
	}

	public Toolbar make_toolbar() {
		Toolbar bar = new Toolbar();
		bar.get_style_context().add_class(STYLE_CLASS_PRIMARY_TOOLBAR);

		var button_new = new ToolButton.from_stock(Gtk.Stock.NEW);
		button_new.clicked.connect(this.on_new_clicked);
		bar.add(button_new);

		var button_open = new ToolButton.from_stock(Gtk.Stock.OPEN);
		button_open.clicked.connect(this.on_open_clicked);
		bar.add(button_open);

		var button_save = new ToolButton.from_stock(Gtk.Stock.SAVE);
		button_save.clicked.connect(this.on_save_clicked);
		bar.add(button_save);

		var button_save_as = new ToolButton.from_stock(Gtk.Stock.SAVE_AS);
		button_save_as.clicked.connect(this.on_save_as_clicked);
		bar.add(button_save_as);

		bar.add(new Gtk.SeparatorToolItem());

		var button_undo = new ToolButton.from_stock(Gtk.Stock.UNDO);
		button_undo.clicked.connect(this.on_undo_clicked);
		bar.add(button_undo);

		var button_redo = new ToolButton.from_stock(Gtk.Stock.REDO);
		button_redo.clicked.connect(this.on_redo_clicked);
		bar.add(button_redo);

		bar.add(new Gtk.SeparatorToolItem());

		var button_cut = new ToolButton.from_stock(Gtk.Stock.CUT);
		button_cut.clicked.connect(this.on_cut_clicked);
		bar.add(button_cut);

		var button_copy = new ToolButton.from_stock(Gtk.Stock.COPY);
		button_copy.clicked.connect(this.on_copy_clicked);
		bar.add(button_copy);

		var button_paste = new ToolButton.from_stock(Gtk.Stock.PASTE);
		button_paste.clicked.connect(this.on_paste_clicked);
		bar.add(button_paste);

		bar.add(new Gtk.SeparatorToolItem());

		var button_exec = new ToolButton.from_stock(Gtk.Stock.EXECUTE);
		button_exec.clicked.connect(this.on_exec_clicked);
		bar.add(button_exec);

		return bar;
	}

	public SourceView make_source_view() {
		var lang_manager = SourceLanguageManager.get_default();
		var paths = lang_manager.get_search_path();
		paths += ".";
		lang_manager.set_search_path(paths);
		var lang = lang_manager.get_language("sol");
		var buffer = new SourceBuffer.with_language(lang);
		this.source_view = new SourceView();
		this.source_view.buffer = buffer;
		this.source_view.auto_indent = true;
		this.source_view.indent_on_tab = true;
		this.source_view.tab_width = 4;
		this.source_view.show_line_numbers = true;
		this.source_view.show_line_marks = true;
		return this.source_view;
	}

	public void init_menu() {
		var menu = new GLib.Menu();
		var section = new GLib.Menu();
		menu.append_section(null, section);
		//section.append("_Help", "app.help");
		section.append("_About", "app.about");
		section = new GLib.Menu();
		menu.append_section(null, section);
		section.append("_Quit", "app.quit");
		this.set_app_menu(menu);
	}

	public void on_new_clicked() {
		this.source_view.buffer.text = "";
		this.filename = "";
	}

	public void on_open_clicked() {
		var file_chooser = new FileChooserDialog("Open", this.window, FileChooserAction.OPEN, Stock.CANCEL, ResponseType.CANCEL, Stock.OPEN, ResponseType.ACCEPT);
		file_chooser.set_filter(this.get_file_filter());
		if(file_chooser.run() == ResponseType.ACCEPT) {
			this.filename = file_chooser.get_filename();
			this.open_file();
		}
		file_chooser.destroy();
	}

	public void on_save_clicked() {
		if(this.filename != "") {
			this.save_file();
		} else {
			this.on_save_as_clicked();
		}
	}
	
	public void on_save_as_clicked() {
		var file_chooser = new FileChooserDialog("Save", this.window, FileChooserAction.SAVE, Stock.CANCEL, ResponseType.CANCEL, Stock.SAVE, ResponseType.ACCEPT);
		file_chooser.set_filter(this.get_file_filter());
		if(this.filename != "") {
			file_chooser.set_filename(this.filename);
		} else {
			file_chooser.set_filename(".sol");
		}
		if(file_chooser.run() == ResponseType.ACCEPT) {
			this.filename = file_chooser.get_filename();
			this.save_file();
		}
		file_chooser.destroy();
	}

	private FileFilter get_file_filter() {
		var file_filter = new FileFilter();
		file_filter.set_name("SOL file");
		file_filter.add_mime_type("text/x-sol");
		file_filter.add_pattern("*.sol");
		return file_filter;
	}
	private void open_file() {
		try {
			string text;
			FileUtils.get_contents(this.filename, out text);
			this.source_view.buffer.text = text;
		} catch (Error e) {
			stderr.printf("Error: %s\n", e.message);
		}
	}

	private void save_file() {
		try {
			string text = this.source_view.buffer.text;
			FileUtils.set_contents(this.filename, text);
		} catch (Error e) {
			stderr.printf("Error: %s\n", e.message);
		}
	}

	public void on_exec_clicked() {
		string text = this.source_view.buffer.text;
		if(StringUtils.is_empty(text))
			return;
		try {
			var time = Main.get_time();
			long init_time = time.tv_usec + 1000000 * time.tv_sec;
			string? result = Main.exec_internal(text);
			time = Main.get_time();
			time.add(-1 * init_time);
			string msg = "";
			if(result != null) {
				msg = "Returns: " + result + "\n";
			} else {
				msg = "Returns nothing.\n";
			}
			msg += "Execution length: " + ((float) ((double) time.tv_sec) + ((double) time.tv_usec) / 1000000).to_string() + " seconds.";
			this.show_message(Gtk.MessageType.INFO, msg);
		} catch(ParserError e) {
			this.show_message(MessageType.ERROR, e.message);
		} catch(ExecutionError e) {
			this.show_message(MessageType.ERROR, e.message);
		}
	}

	public void on_undo_clicked() {
		this.source_view.undo();
	}

	public void on_redo_clicked() {
		this.source_view.redo();
	}
	
	public void on_cut_clicked() {
		this.source_view.cut_clipboard();
	}

	public void on_copy_clicked() {
		this.source_view.copy_clipboard();
	}

	public void on_paste_clicked() {
		this.source_view.paste_clipboard();
	}

	public void on_delete_clicked() {
		this.source_view.delete_from_cursor(DeleteType.CHARS, 0);
	}

	public void on_about_clicked() {
		show_about();
	}

	protected void show_about() {
		var about = new AboutDialog();
		about.version = Config.VERSION;
		about.program_name = "CIML";
		about.license_type = License.GPL_3_0;
		about.wrap_license = true;
		about.authors = Config.AUTHORS;
		about.website = Config.WEBSITE;
		about.copyright = "Copyright (C) Thomas Pellissier Tanon";
		about.comments = "A Small Object-oriented Language interpreter with a GTK+ GUI.";
		about.run();
		about.destroy();
	}

    protected void quit_cb() {
		this.window.destroy();
    }

	public void show_message(MessageType type, string message) {
		var dialog = new MessageDialog(this.window, DialogFlags.MODAL, type, ButtonsType.OK, message);
		dialog.run();
		dialog.destroy();
	}
}
