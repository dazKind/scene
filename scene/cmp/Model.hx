package vexima.scene.cmp;

import vexima.formats.InterQuakeModel;
import vexima.math.Aabb;
import vexima.math.DualQuat;
import vexima.rendering.Types;
import vexima.rendering.impl.RenderJob;
import vexima.scene.Types;

class Model 
	extends Component 
	implements IRenderable
{
	@:s public var geometry:String;

	public var localAabb:Aabb = new Aabb();
	public var joints:Array<IqmJoint>;
	public var poses:Array<IqmPose>;
	public var anims:Array<IqmAnim>;
	public var dqFrames:Array<DualQuat>;
	public var jointData:Array<Float>;
	public var meshJobs:Array<RenderJob>;
	public var jobs:Array<RenderJob>;

	public function new(_eid:Int, _geo:String) {
		super(_eid);
		geometry = _geo;
	}	

	inline public function getJobCount():Int {
		return jobs.length;
	}

    inline public function getJob(_index:Int):IRenderJob {
    	return jobs[_index];
    }
}

class ModelArray extends CArray<Model> implements hxbit.Serializable {
	@:s var _map:Map<Int, Array<Model>>;
	@:s var _pool:Array<Model>;
	@:s var _set:Map<Int, Bool>;
	public function new(){super(); _map = map; _pool = pool; _set = set;}
	override public function init() {super.init(); map = _map; pool = _pool; set = _set;}
}