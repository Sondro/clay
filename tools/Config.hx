package;


import Yaml;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;


class Config {

	public static function create_khafile(config:ConfigData):String {

		var project = config.project;
		var compiler = config.compiler;

		var kfile = 'let p = new Project("${project.title}");\n';

		for (s in project.sources) {
			kfile += 'p.addSources("${s}");\n';
		}

		kfile += 'p.addLibrary("${CLI.engine_name}");\n';

		for (s in project.libraries) {
			kfile += 'p.addLibrary("${s}");\n';
		}

		for (s in project.shaders) {
			kfile += 'p.addShaders("${s}");\n';
		}

		kfile += 'p.addShaders("${Path.join([CLI.engine_dir, 'assets/shaders'])}");\n';

		// inputs
		if(config.input != null) {
			if(config.input.mouse) {
				kfile += 'p.addDefine("use_mouse_input");\n';
			}
			if(config.input.keyboard) {
				kfile += 'p.addDefine("use_keyboard_input");\n';
			}
			if(config.input.gamepad) {
				kfile += 'p.addDefine("use_gamepad_input");\n';
			}
			if(config.input.touch) {
				kfile += 'p.addDefine("use_touch_input");\n';
			}
			if(config.input.pen) {
				kfile += 'p.addDefine("use_pen_input");\n';
			}
		} else {
			kfile += 'p.addDefine("use_mouse_input");\n';
			kfile += 'p.addDefine("use_keyboard_input");\n';
			kfile += 'p.addDefine("use_gamepad_input");\n';
			kfile += 'p.addDefine("use_touch_input");\n';
			// kfile += 'p.addDefine("use_pen_input");\n';
		}

		var no_default_font = false;

		for (s in project.defines) {
			kfile += 'p.addDefine("${s}");\n';
			if(s == 'no_default_font') {
				no_default_font = true;
			}
		}

		for (s in compiler.parameters) {
			kfile += 'p.addParameter("${s}");\n';
		}

		if(!no_default_font) {
			var fp = Path.join([CLI.engine_dir, 'assets/fonts']);
			kfile += 'p.addAssets("${fp}", {destination: "assets/{name}", noprocessing: true, notinlist: true});\n';
		}
		
		for (s in project.assets) {
			kfile += 'p.addAssets("${s}/**", {nameBaseDir: "${s}", destination: "${s}/{dir}/{name}", name: "{dir}/{name}", noprocessing: true, notinlist: true});\n';
		}

		if(config.html5 != null){
			if(config.html5.canvas != null) {
				kfile += 'p.targetOptions.html5.canvasId = "${config.html5.canvas}";\n';
			}
			if(config.html5.script != null) {
				kfile += 'p.targetOptions.html5.scriptName = "${config.html5.script}";\n';
			}
			if(config.html5.webgl != null) {
				kfile += 'p.targetOptions.html5.webgl = ${config.html5.webgl};\n';
			}
		}

		if(config.android != null){
			if(config.android.orientation != null) {
				kfile += 'p.targetOptions.android.screenOrientation = "${config.android.orientation}";\n';
			}
			if(config.android.permissions != null) {
				kfile += 'p.targetOptions.android.permissions = "${config.android.permissions}";\n';
			}
			if(untyped __js__('config.android.package')) {
				kfile += 'p.targetOptions.android.package = "${untyped __js__('config.android.package')}";\n';
			}
		}

		if(config.ios != null){
			if(config.ios.orientation != null) {
				kfile += 'p.targetOptions.ios.screenOrientation = "${config.ios.orientation}";\n';
			}
		}


		kfile += "resolve(p);";

		return kfile;

	}

	public static function get():ConfigData {
	    
		var config_path = Path.join([CLI.user_dir, 'project.yml']);
		if (!FileSystem.exists(config_path)) {
			CLI.error('Cant find project.yml in: ${CLI.user_dir}');
		}
		var data = File.getContent(config_path);
		var config:ConfigData = Yaml.safeLoad(data);

		return config;
	}

}

typedef ConfigData = {
	var project:ProjectConfig;
	var compiler:CompilerConfig;
	var app:AppConfig;
	var input:InputConfig;

	var html5:HtmlConfig;

	var windows:WindowsConfig;
	var osx:OSXConfig;
	var linux:LinuxConfig;

	var uwp:UWPConfig;
	var android:AndroidConfig;
	var ios:IOSConfig;

	// internal
	var target:String;
	var debug:Bool;
	var onlydata:Bool;
	var compile:Bool;
}

typedef InputConfig = {
	var pen:Bool;
	var touch:Bool;
	var gamepad:Bool;
	var mouse:Bool;
	var keyboard:Bool;
}

typedef ProjectConfig = {
	var title:String;
	var version:String;
	var sources:Array<String>;
	var authors:Array<String>;
	var libraries:Array<String>;
	var assets:Array<String>;
	var defines:Array<String>;
	var shaders:Array<String>;
}

typedef CompilerConfig = {
	var parameters:Array<String>;
	var options:Array<String>;
	var haxe:String;
	var kha:String;
	var ffmpeg:String;
}

typedef AppConfig = {
	var name:String;
	var icon:String;
}

typedef WindowsConfig = {
	var graphics:String;
	var audio:String;
}

typedef OSXConfig = {}

typedef LinuxConfig = {
	var graphics:String;
}

typedef UWPConfig = {
	var graphics:String;
	var audio:String;
	var orientation:String;
}

typedef AndroidConfig = {
	// var package:String;
	var orientation:String;
	var permissions:Array<String>;
}
typedef IOSConfig = {
	var orientation:String;
}

typedef HtmlConfig = {
	var webgl:Bool;
	var canvas:String;
	var script:String;
	var favicon:String;
	var width:Int;
	var height:Int;
	var html_file:String;
	var server_port:Int;
	var minify:Bool;
}