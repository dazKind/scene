package vexima.scene.sys;

import vexima.scene.cmp.Spatial;
import vexima.scene.Types;
import vexima.scene.Scene;
import vexima.spatial.Types;

class SpatialSys implements ISceneSystem {
    public var scene:Scene;

    var spatials:SpatialArray;

    var spatialDB:SpatialHash3D;

    public function new(_spatialDB:SpatialHash3D) {
        spatialDB = _spatialDB;
    }

    public function init() {
        spatials = scene.access(SpatialArray);

        spatials.onAdd.add(_onAddSpatial);
        spatials.onRemove.add(_onRemoveSpatial);
    }

    public function deinit() {
        spatialDB.reset();

        spatials.onAdd.remove(_onAddSpatial);
        spatials.onRemove.remove(_onRemoveSpatial);

        spatials = null;
    }

    public function update(_dt:Float) {
        var time:Int = Std.int(haxe.Timer.stamp()*1000);
        
        spatials.eachChange(function(_sp:Spatial) {
            spatialDB.update(_sp.hashNode);
        }, function(_sp:Spatial) {
            spatials.done(_sp);
        });
        
        spatialDB.updateAbt();
        //trace(spatialDB);
        
        //trace("spatialDB Updates: " + (Std.int(haxe.Timer.stamp()*1000) - time));     
    }

    function _onAddSpatial(_cmp:Spatial) {
        spatialDB.add(_cmp.hashNode);
    }

    function _onRemoveSpatial(_cmp:Spatial) {
        spatialDB.remove(_cmp.hashNode);
    }
}