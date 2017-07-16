package vexima.scene;

import hxbit.Serializable;
import vexima.utils.Signal;

// Component Baseclass
class Component implements Serializable {
	@:s public var __eid:Int;

	public function new(_eid:Int) __eid = _eid;

	inline public function entity():Int return __eid;
}

// 
interface ISceneSystem {
	public var scene:Scene;	

	public function init():Void;
	public function deinit():Void;
	public function update(_dt:Float):Void;
}

// allow scene to make typed calls on arrays
interface IArrayAccess {
	function init():Void;
	function markAll():Void;
	function updateChangeset():Void;
	function removeAllOfEntity(_eid:Int):Void;
}

// generic ComponentArray
@:generic
class CArray<T:Component> implements IArrayAccess {
	var map:Map<Int, Array<T>>; // entity -> cmp-list
	var pool:Array<T>; // cmp-list
	var set:Map<Int, Bool>; // cmp-ids

	var changeset:Map<T, Bool>;

	public var onAdd:Signal<T->Void>;
	public var onRemove:Signal<T->Void>;
	public var onChanged:Signal<T->Void>;

	public function new() {
		map = new Map<Int, Array<T>>();
		pool = new Array<T>();
		set = new Map<Int, Bool>();

		changeset = new Map<T, Bool>();
		onAdd = new Signal<T->Void>();
		onRemove = new Signal<T->Void>();
		onChanged = new Signal<T->Void>();
	}

	public function dispose() {
		for (c in pool)
			onRemove.dispatch(c);
		onAdd.clear();
		onRemove.clear();
		onChanged.clear();

		onAdd = null;
		onRemove = null;
		pool = null;
		map = null;
		changeset = null;
		set = null;
	}

	public function init() {
		changeset = new Map<T, Bool>();
		onAdd.clear();
		onRemove.clear();
		onChanged.clear();
		onAdd = new Signal<T->Void>();
		onRemove = new Signal<T->Void>();
		onChanged = new Signal<T->Void>();
	}

	public function add(_cmp:T) {
		if (!set.exists(_cmp.__uid)) { // ignore double adds
			if (map.exists(_cmp.__eid))
				map.get(_cmp.__eid).push(_cmp);
			else
				map.set(_cmp.__eid, [_cmp]);
			pool.push(_cmp);
			set.set(_cmp.__uid, true);
			mark(_cmp);
			onAdd.dispatch(_cmp);
		} else
			throw "You added a component twice! Dont do that!";
	}

	public function remove(_cmp:T) {
		if (map.exists(_cmp.__eid)) {
			var ids = map.get(_cmp.__eid);
			if (ids.remove(_cmp)) {
				pool.remove(_cmp);
				changeset.remove(_cmp);
				onRemove.dispatch(_cmp);
				if (ids.length == 0)
					map.remove(_cmp.__eid);
			}
		}
	}

	public function removeAllOfEntity(_eid:Int) {
		if (map.exists(_eid)) {
			var cmps = map.get(_eid);
			for (c in cmps) {
				pool.remove(c);
				set.remove(c.__uid);
				changeset.remove(c);
				onRemove.dispatch(c);
			}
			map.remove(_eid);
		}	
	}

	public function updateChangeset() {
		for (k in changeset.keys())
			if (changeset.get(k) == true) { // was processed
				changeset.remove(k);
				onChanged.dispatch(k);
			}
	}

	public function contains(_e:Int)
		return map.exists(_e);

	public function getEntCmpList(_e:Int):Array<T>
		return map.get(_e);	

	public function getEntCmp(_e:Int):T {
		var res = null;
		if (map.exists(_e))
			res = map.get(_e)[0];
		return res;
	}

	inline public function markAll() {
		for (c in pool) mark(c);
	}

	inline public function mark(_cmp:T) {
		if (map.exists(_cmp.__eid))
			changeset.set(_cmp, false);
	}

	inline public function done(_cmp:T) {
		if (map.exists(_cmp.__eid))
			changeset.set(_cmp, true);
	}

	inline public function eachChange(_f:T->Void, _d:T->Void) {
		var itms:Array<T> = [];
		for (k in changeset.keys())
			itms.push(k);
		
		Core.xmp.parallel_for(itms, _f, _d);
        Core.xmp.wait();
	}

	@:arrayAccess
	public inline function poolRead(_i:Int):T
		return pool[_i];

	@:arrayAccess
	public inline function poolWrite(_i:Int, _v:T):T {
		pool[_i] = _v;
		return _v;
	}

	public function iterator():Iterator<T> return pool.iterator();
}
