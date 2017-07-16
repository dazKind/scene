package vexima.scene.cmp;

import vexima.math.Aabb;
import vexima.math.Mat44;
import vexima.math.Quat;
import vexima.math.Vec3;
import vexima.scene.Types;
import vexima.spatial.Types;

class Boid extends Component {
	
	@:s public var velocity:Vec3;
	@:s public var accel:Vec3;

	public var maxForce:Float; // max steering force
	public var maxSpeed:Float; // max movement speed
	
	public function new(_eid:Int, _f:Float, _s:Float) {
		super(_eid);
		accel = new Vec3(0,0,0);
		velocity = new Vec3(
			vexima.math.MathUtils.frandRange(-1, 1),
			vexima.math.MathUtils.frandRange(-1, 1),
			vexima.math.MathUtils.frandRange(-1, 1)
		);
		maxForce = _f;
		maxSpeed = _s;
	}
}

class BoidArray extends CArray<Boid> implements hxbit.Serializable {
	@:s var _map:Map<Int, Array<Boid>>;
	@:s var _pool:Array<Boid>;
	@:s var _set:Map<Int, Bool>;
	public function new(){super(); _map = map; _pool = pool; _set = set;}
	override public function init() {super.init(); map = _map; pool = _pool; set = _set;}
}