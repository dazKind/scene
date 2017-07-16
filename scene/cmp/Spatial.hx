package vexima.scene.cmp;

import vexima.math.Aabb;
import vexima.math.Mat44;
import vexima.math.Quat;
import vexima.math.Vec3;
import vexima.scene.Types;
import vexima.spatial.Types;

class Spatial extends Component {
    
    public var aabb(get, set):Aabb;

    function get_aabb() return hashNode.aabb;
    function set_aabb(_bb:Aabb):Aabb {
        if (hashNode == null)
            hashNode = new SpatialHashNode(__eid);
        hashNode.aabb = _bb;
        return _bb;
    }

    public var hashNode:SpatialHashNode;
    
    public function new(_eid:Int) {
        super(_eid);
        aabb = new Aabb();
    }
}

class SpatialArray extends CArray<Spatial> implements hxbit.Serializable {
    @:s var _map:Map<Int, Array<Spatial>>;
    @:s var _pool:Array<Spatial>;
    @:s var _set:Map<Int, Bool>;
    public function new(){super(); _map = map; _pool = pool; _set = set;}
    override public function init() {super.init(); map = _map; pool = _pool; set = _set;}
}