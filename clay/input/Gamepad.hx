package clay.input;


import clay.Engine;
import clay.utils.Log.*;
import clay.utils.Bits;


@:allow(clay.core.Inputs)
@:access(clay.Engine, clay.input.GamepadEvent)
class Gamepads extends Input {


	// need to figure how gamepad is stored, and change map to array maybe
	var gamepads:Map<Int, Gamepad>;
	var gamepad_event:GamepadEvent;

	var gamepad_bindings:Map<String, Map<Int, Int>>;
	var binding:Bindings;


	function new(_engine:Engine) {
		
		super(_engine);

		gamepad_bindings = new Map();
		binding = Clay.input.binding;

	}

	public function get(_gamepad:Int):Gamepad {

		if(!active) {
			return null;
		}

		return gamepads.get(_gamepad);

	}

	override function enable() {

		if(active) {
			return;
		}

		gamepads = new Map();

		#if use_gamepad_input
		
		kha.input.Gamepad.notifyOnConnect(onconnect, ondisconnect);

		#end 

		gamepad_event = new GamepadEvent();

		super.enable();

	}

	override function disable() {
		
		if(!active) {
			return;
		}

		#if use_gamepad_input

		kha.input.Gamepad.removeConnect(onconnect, ondisconnect);
		for (g in gamepads) {
			g.unlisten_events();
		}

		#end 

		gamepads = null;
		gamepad_event = null;

		super.disable();

	}

	public function pressed(_gamepad:Int, _button:Int):Bool {

		var g = gamepads.get(_gamepad);
		if(g != null) {
			return g.pressed(_button);
		}

		return false;

	}

	public function released(_gamepad:Int, _button:Int):Bool {

		var g = gamepads.get(_gamepad);
		if(g != null) {
			return g.released(_button);
		}

		return false;

	}

	public function down(_gamepad:Int, _button:Int):Bool {

		var g = gamepads.get(_gamepad);
		if(g != null) {
			return g.down(_button);
		}

		return false;

	}

	public function axis(_gamepad:Int, _axis:Int):Float {

		var g = gamepads.get(_gamepad);
		if(g != null) {
			return g.axis(_axis);
		}

		return 0;

	}

    public function bind(_name:String, _gamepad:Int, _button:Int) {

    	var b = gamepad_bindings.get(_name);

    	if(b == null) {
    		b = new Map();
    		gamepad_bindings.set(_name, b);
    	}

    	b.set(_gamepad, _button);

    }

    public function unbind(_name:String) {

    	if(gamepad_bindings.exists(_name)) {
    		gamepad_bindings.remove(_name);
    		binding.remove_all(_name);
    	}

    }

    function check_binding(_gamepad:Int, _button:Int, _pressed:Bool) {

    	for (k in gamepad_bindings.keys()) { // todo: using this is broke hashlink build, ftw?
    		var g = gamepad_bindings.get(k);
    		if(g != null) {
    			if(g.exists(_gamepad)) {
    				var n = g.get(_gamepad);
		    		if(Bits.check(n, _button)) {
			    		binding.input_event.set_gamepad(k, gamepad_event);
				    	if(_pressed) {
				    		binding.inputpressed();
				    	} else {
							binding.inputreleased();
				    	}
				    	return;
		    		}
    			}
    		}
    	}

    }

	function reset() {

		for (g in gamepads) {
			g.clear();
		}

	}

	function onconnect(_gamepad:Int) {
		
		_debug('onconnect gamepad:$_gamepad');
		assert(!gamepads.exists(_gamepad), 'trying to add gamepad that already exists');

		var g = new Gamepad(_gamepad, this);
		g.listen_events();
		gamepads.set(_gamepad, g);

		gamepad_event.set(_gamepad, g.id, -1, -1, 0, GamepadEventState.device_added);

		engine.gamepadadd(gamepad_event);

	}

	function ondisconnect(_gamepad:Int) {
		
		_debug('ondisconnect gamepad:$_gamepad');
		assert(gamepads.exists(_gamepad), 'trying to remove gamepad that not exists');

		var g = gamepads.get(_gamepad);
		g.unlisten_events();
		gamepads.remove(_gamepad);

		gamepad_event.set(_gamepad, g.id, -1, -1, 0, GamepadEventState.device_removed);
		
		engine.gamepadremove(gamepad_event);

	}

}

@:allow(clay.input.Gamepads)
@:access(clay.Engine, clay.input.Gamepads)
class Gamepad {


	public var id(default, null):String;
	public var gamepad(default, null):Int;
	public var deadzone:Float = 0.15;

	var buttons_pressed:UInt = 0;
	var buttons_released:UInt = 0;
	var buttons_down:UInt = 0;

	var axis_id:Int = -1;
	var axis_value:Float = 0;

	var gamepad_event:GamepadEvent;
	var gamepads:Gamepads;


	function new(_g:Int, _gamepads:Gamepads) {

		gamepad = _g;
		gamepads = _gamepads;
		id = kha.input.Gamepad.get(gamepad).id;
		gamepad_event = new GamepadEvent();

	}

	public inline function pressed(_b:Int):Bool {

		return Bits.check(buttons_pressed, _b);

	}

	public inline function released(_b:Int):Bool {

		return Bits.check(buttons_released, _b);

	}

	public inline function down(_b:Int):Bool {

		return Bits.check(buttons_down, _b);

	}

	public inline function axis(_a:Int):Float {

		if(_a == axis_id) {
			return axis_value;
		}

		return 0;

	}

	function listen_events() {

		kha.input.Gamepad.get(gamepad).notify(onaxis, onbutton);

	}

	function unlisten_events() {

		kha.input.Gamepad.get(gamepad).remove(onaxis, onbutton);

	}

	function clear() {

		buttons_pressed = 0;
		buttons_released = 0;
		axis_id = -1;
		axis_value = 0;

	}

	function onaxis(_a:Int, _v:Float) {

		if(Math.abs(_v) < deadzone) {
			return;
		}
		
		_debug('onaxis gamepad:$gamepad, axis:$_a, value:$value');

		axis_id = _a;
		axis_value = _v;

		gamepad_event.set(gamepad, id, -1, axis_id, axis_value, GamepadEventState.axis);

		gamepads.engine.gamepadaxis(gamepad_event);

	}

	function onbutton(_b:Int, _v:Float) {
		
		_debug('onbutton gamepad:$gamepad, button:$_b, value:$_v');

		if(_v > 0.5) {
			onpressed(_b);
		} else {
			onreleased(_b);
		}

	}

	inline function onpressed(_b:Int) {

		_debug('onpressed gamepad:$gamepad, button:$_b');

		buttons_pressed = Bits.set(buttons_pressed, _b);
		buttons_down = Bits.set(buttons_down, _b);

		gamepad_event.set(gamepad, id, _b, -1, 0, GamepadEventState.button_down);

		gamepads.check_binding(gamepad, _b, true);

		gamepads.engine.gamepaddown(gamepad_event);

	}

	inline function onreleased(_b:Int) {

		_debug('onreleased gamepad:$gamepad, button:$_b');

		buttons_pressed = Bits.clear(buttons_pressed, _b);
		buttons_down = Bits.clear(buttons_down, _b);
		buttons_released = Bits.set(buttons_released, _b);

		gamepad_event.set(gamepad, id, _b, -1, 0, GamepadEventState.button_up);

		gamepads.check_binding(gamepad, _b, false);

		gamepads.engine.gamepadup(gamepad_event);

	}


}


@:allow(clay.input.Gamepad)
class GamepadEvent {


	public var id (default, null):String;
	public var gamepad (default, null):Int;

	public var button (default, null):Int;
	public var axis (default, null):Int;
	public var value (default, null):Float;

	public var state (default, null):GamepadEventState;


	function new() {}

	inline function set(_gamepad:Int, _id:String, _button:Int, axis_id:Int, _value:Float, _state:GamepadEventState) {

		id = _id;
		gamepad = _gamepad;
		button = _button;
		axis = axis_id;
		value = _value;
		state = _state;

	}


}

@:enum abstract GamepadEventState(Int) from Int to Int {

    var none                = 0;
    var button_down         = 1;
    var button_up           = 2;
    var axis                = 3;
    var device_added    	= 4;
    var device_removed  	= 5;

}
