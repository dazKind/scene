package vexima.scene.sys;

import vexima.scene.cmp.Camera;
import vexima.scene.cmp.Model;
import vexima.scene.cmp.Spatial;
import vexima.scene.cmp.Transform;
import vexima.scene.Types;
import vexima.scene.Scene;
import vexima.spatial.Types;

class TransformSys implements ISceneSystem {
	public var scene:Scene;

	var transforms:TransformArray;
	var cameras:CameraArray;
	var models:ModelArray;
	var spatials:SpatialArray;

	var spatialDB:SpatialHash3D;

	public function new(_spatialDB:SpatialHash3D) {
		spatialDB = _spatialDB;
	}

	public function init() {
		transforms = scene.access(TransformArray);
		cameras = scene.access(CameraArray);
		models = scene.access(ModelArray);
		spatials = scene.access(SpatialArray);
	}

	public function deinit() {
		transforms = null;
		cameras = null;
		models = null;
		spatials = null;
	}

	public function update(_dt:Float) {
		var time:Int = Std.int(haxe.Timer.stamp()*1000);

		// deal with changes
		transforms.eachChange(function(_t:Transform) {
			_t.matWorld.recompose(_t.orientation, _t.scale, _t.position);
		}, function(_t:Transform) {
			// check if we need to update a related dependency as well
			if (cameras.contains(_t.entity()))
				cameras.mark(cameras.getEntCmp(_t.entity()));
			
			if (models.contains(_t.entity()))
				models.mark(models.getEntCmp(_t.entity()));

			if (spatials.contains(_t.entity()))
				spatials.mark(spatials.getEntCmp(_t.entity()));

			transforms.done(_t);
		});

		cameras.eachChange(function(_c:Camera) {
			// get the first transform of the entity and use it as camera root
			var tr = transforms.getEntCmp(_c.entity());

			// set camera matrices
			_c.mView.setFromMat44(tr.matWorld);
			_c.mView.invert();

			_c.mViewInv.setFromMat44(tr.matWorld);
			_c.mViewProj = _c.mProj * _c.mView;

			_c.mViewProjInv.setFromMat44(_c.mViewProj);
			_c.mViewProjInv.invert();

			// update the frustum
			_c.frustum.initFromMatrices(tr.matWorld, _c.mViewProj, _c.mViewProjInv);

			// update the aabb
			/*
			var sp = spatials.getEntCmp(_c.entity());
			sp.aabb.beginExtend();
			sp.aabb.extendByFrustum(_c.frustum); // corners in worldspace
			*/
		}, function(_c:Camera) {
			/*
			var sp = spatials.getEntCmp(_c.entity());
			spatials.mark(sp);
			*/
			cameras.done(_c);
		});

		models.eachChange(function(_m:Model) {
			// update the aabb
			var tr = transforms.getEntCmp(_m.entity());
			var sp = spatials.getEntCmp(_m.entity());
			sp.aabb = _m.localAabb.copy();
			sp.aabb.transformByMat44(tr.matWorld);
		}, function(_m:Model) {
			var sp = spatials.getEntCmp(_m.entity());
			spatials.mark(sp);
			models.done(_m);
		});
		//trace((Std.int(haxe.Timer.stamp()*1000) - time));
	}
}