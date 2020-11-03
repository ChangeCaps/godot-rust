tool
extends EditorPlugin


const MainPanel = preload("res://addons/gd_rust/main_panel.tscn");
const CARGO_TARGETS = {
	"Windows": "x86_64-pc-windows-msvc",
	"x11": "x64_64-unknown-linux-gnu",
};
const TARGET_LIB_NAMES = {
	"Windows": "gd_crate.dll",
	"x11": "",
};

var main_panel_instance;


func copy_recursive(from, to):
	var directory = Directory.new()
	
	# If it doesn't exists, create target directory
	if not directory.dir_exists(to):
		directory.make_dir_recursive(to)
	
	# Open directory
	var error = directory.open(from)
	if error == OK:
		# List directory content
		directory.list_dir_begin(true)
		var file_name = directory.get_next()
		while file_name != "":
			if directory.current_is_dir():
				copy_recursive(from + "/" + file_name, to + "/" + file_name)
			else:
				directory.copy(from + "/" + file_name, to + "/" + file_name)
			file_name = directory.get_next()
	else:
		print("Error copying " + from + " to " + to)


func _enter_tree():
	main_panel_instance = MainPanel.instance();
	
	get_editor_interface().get_editor_viewport().add_child(main_panel_instance);
	
	make_visible(false);
	
	var directory: Directory = Directory.new();
	
	if !directory.dir_exists("gdrust"):
		copy_recursive("addons/gd_rust/template", "gdrust");


func _exit_tree():
	pass


func build() -> bool:
	print("Starting rust compilation");
	
	var os_name = OS.get_name();
	var target = CARGO_TARGETS[os_name];
	
	print("Target: ", target);
	
	var output = [];
	var args = [
		"build", 
		"--release", 
		"--manifest-path", 
		"gdrust/crate/Cargo.toml", 
		"--target", 
		target, 
		"--quiet"
	];
	var return_code = OS.execute("cargo", args, true, output);
	
	if return_code != 0:
		printerr(output);
		return false;
	
	var directory = Directory.new();
	
	var lib_name = TARGET_LIB_NAMES[os_name];
	
	var org = "gdrust/crate/target/" + target + "/release/" + lib_name;
	var trg = "gdrust/lib/" + target + "/" + lib_name;
	
	directory.make_dir("gdrust/lib/" + target);
	directory.copy(org, trg);
	
	return return_code == 0;


func has_main_screen():
	return true;


func make_visible(visible):
	pass;


func get_plugin_name():
	return "GDRust";


func get_plugin_icon():
	return get_editor_interface().get_base_control().get_icon("Node", "EditorIcons");
