package vexima.scene.cmp;

import vexima.math.Frustum;
import vexima.math.Mat44;
import vexima.rendering.Types;
import vexima.scene.Types;

class Camera 
	extends Component 
	implements IView 
	implements ICamera 
{
	inline public static var ORTHO:Int = 0;
	inline public static var PERSP:Int = 1;

	var projectionType:Int;

	var fov:Float;
	var aspectRatio:Float;
	var orthoWidth:Float;
	var orthoHeight:Float;
	
	// ICamera	
	public var mViewInv:Mat44;
	public var mView:Mat44;
	public var mProj:Mat44;
	public var mProjInv:Mat44;
	public var mViewProj:Mat44;
	public var mViewProjInv:Mat44;
	public var fNearZ:Float;
	public var fFarZ:Float;
	public var vDepthCoefs:Array<Float>;

	// IView
	public var idView:Int;
	public var frustum:Frustum;
	var m_exclusiveContext:String;
	var m_visibleList:Array<IRenderable>;

	public function new(_eid:Int) {
		super(_eid);

		projectionType = PERSP;
		fov = 60;
		aspectRatio = 1.33333;
		orthoWidth = 1.0;
		orthoHeight = 1.0;
		fNearZ = 0.02;
		fFarZ = 10000;
		frustum = new Frustum();
		
		mViewInv = new Mat44();
		mView = new Mat44();
		mView.invert();

		mProj = Mat44.createPerspLH(fov, aspectRatio, fNearZ, fFarZ);
		mProjInv = Mat44.createFromMat44(mProj);
		mProjInv.invert();
		
		mViewProj = new Mat44();
		mViewProjInv = Mat44.createFromMat44(mViewProj);
		mViewProjInv.invert();

		vDepthCoefs = calcProjDepthCoefs();

		m_exclusiveContext = "";

		idView = vexima.net.Utils.uniqueId();
	}

	inline function calcProjDepthCoefs():Array<Float> {
		return [-1.0 / mProj[0], -1.0 / mProj[5]];
	}

	public function commitProjection():Void {
		switch (projectionType)
		{
			case ORTHO:
			{
				var w:Float = orthoWidth * 0.5;
				var h:Float = orthoHeight * 0.5;

				var tmp = Mat44.createOrthoLH( -w, w, -h, h, fNearZ, fFarZ);
				mProj.setFromMat44(tmp);
				mProjInv.setFromMat44(tmp);
				mProjInv.invert();
			}
			case PERSP:
			{
				var tmp = Mat44.createPerspLH(fov, aspectRatio, fNearZ, fFarZ);
				mProj.setFromMat44(tmp);
				mProjInv.setFromMat44(tmp);
				mProjInv.invert();
			}
		}

		vDepthCoefs = calcProjDepthCoefs(); // update!
	}

	inline public function addVisible(_r:IRenderable):Void {
		if (m_visibleList == null)
			m_visibleList = [];
		m_visibleList.push(_r);
	}

	inline public function clearVisible():Void {
		m_visibleList = [];
	}

	inline public function getVisibleCount():Int {
		return m_visibleList.length;
	}

	inline public function getVisible(_index:Int):IRenderable {
		return m_visibleList[_index];
	}

	inline public function getExclusiveContext():String {
		return m_exclusiveContext;
	}

	public function getRenderTarget():IRenderTarget {
		return null;
	}
}

class CameraArray extends CArray<Camera> implements hxbit.Serializable {
	@:s var _map:Map<Int, Array<Camera>>;
	@:s var _pool:Array<Camera>;
	@:s var _set:Map<Int, Bool>;
	public function new(){super(); _map = map; _pool = pool; _set = set;}
	override public function init() {super.init(); map = _map; pool = _pool; set = _set;}
}

