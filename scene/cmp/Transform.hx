package vexima.scene.cmp;

import vexima.math.Aabb;
import vexima.math.Mat44;
import vexima.math.Quat;
import vexima.math.Vec3;
import vexima.scene.Types;



class Transform extends Component {	
	@:s public var position:Vec3;
	@:s public var scale:Vec3;
	@:s public var orientation:Quat;

	public var matWorld:Mat44 = new Mat44();

	public function new(_eid:Int) {
		super(_eid);
		position = new Vec3(0,0,0);
		scale = new Vec3(1,1,1);
		orientation = new Quat(0,0,0,1);
	}
}

class TransformArray extends CArray<Transform> implements hxbit.Serializable {
	@:s var _map:Map<Int, Array<Transform>>;
	@:s var _pool:Array<Transform>;
	@:s var _set:Map<Int, Bool>;
	public function new(){super(); _map = map; _pool = pool; _set = set;}
	override public function init() {super.init(); map = _map; pool = _pool; set = _set;}
}