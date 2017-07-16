package vexima.scene;

import vexima.scene.Types;

@:coreType abstract ClassKey from Class<Dynamic> to {} {}

class Scene implements hxbit.Serializable {
    @:s var eid:Int = 0;

    @:s var entities:Map<Int, Bool>;
    var deadEntities:Array<Int>;

    var storage:haxe.ds.ObjectMap<ClassKey, Dynamic>;

    public var systems:Array<ISceneSystem>;

    public function new(_cmps:Array<Dynamic>, _sys:Array<ISceneSystem> = null) {
        entities = new Map<Int, Bool>();
        deadEntities = [];
        storage = new haxe.ds.ObjectMap<ClassKey, Dynamic>();
        
        for (c in _cmps)
            _setupArray(c);
    
        systems = _sys != null ? _sys : [];
        for (s in systems)
            s.scene = this;
    }

    function _setupArray<T>(_cl:Class<T>) {
        storage.set(_cl, Type.createInstance(_cl, []));
    }

    inline public function access<T>(_cl:Class<T>):T {
        return storage.get(_cl);
    }

    inline public function add<T>(_k:Class<T>, _cl:T) {
        storage.set(_k, _cl);
    }

    inline public function remove<T>(_cl:Class<T>):Bool {
        return storage.remove(_cl);
    }

    public function init() {
        for (s in systems)
            s.init();
    }

    public function deinit() {
        for (s in systems)
            s.deinit();

        for (s in storage) 
            remove(s);
    }

    public function update(_dt:Float) {
        for (s in systems)
            s.update(_dt);
        
        for (s in storage) {
            var a = cast(s, IArrayAccess);
            a.updateChangeset();
        }

        if (deadEntities.length > 0) {
            for (e in deadEntities)
                for (s in storage){
                    var a = cast(s, IArrayAccess);
                    a.removeAllOfEntity(e);
                }
            deadEntities = [];
        }
    }

    public function create():Int {
        var ent = eid++;
        entities.set(ent, true); // mark as alive
        return ent;
    }

    public function destroy(_eid) {
        if (entities.exists(_eid)) {
            entities.set(_eid, false); // mark as dead
            deadEntities.push(_eid);
        }
    }

    public function save():haxe.io.Bytes {
        var s = new hxbit.Serializer();
        return s.serialize(this);
    }

    public function load(_bytes:haxe.io.Bytes) {
        // shutdown everything
        deinit();

        var s = new hxbit.Serializer();
        var loaded = s.unserialize(_bytes, Scene);

        // move stuff over
        eid = loaded.eid;
        entities = loaded.entities;
        storage = loaded.storage;

        // make sure we kill off dead entities
        for (e in entities.keys())
            if (entities.get(e) == false)
                entities.remove(e);

        // startup
        init();
    }

    @:keep
    public function customSerialize(ctx : hxbit.Serializer) {
        var storages = Lambda.array(storage);
        ctx.addInt(storages.length);
        for (s in storages) {
            // store the classname
            ctx.addString(Type.getClassName(Type.getClass(s)));
            // now store the CArray
            var ser = new hxbit.Serializer();
            ser.beginSave();
            ser.addKnownRef(s);
            ctx.addBytes(ser.endSave());
        }
    }

    @:keep
    public function customUnserialize(ctx : hxbit.Serializer) {
        var length = ctx.getInt();
        storage = new haxe.ds.ObjectMap<ClassKey, Dynamic>();
        for (i in 0...length) {
            // load the classname
            var className = ctx.getString();
            var cl = Type.resolveClass(className);
            // now load the CArray
            var bytes = ctx.getBytes();
            var ser = new hxbit.Serializer();
            ser.beginLoad(bytes);
            var array = cast(ser.getKnownRef(cl), IArrayAccess);
            storage.set(cl, array);
            ser.endLoad();
            array.init();
            array.markAll();
        }
    }    
}