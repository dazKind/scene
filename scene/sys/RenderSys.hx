package vexima.scene.sys;

import vexima.rendering.Types;
import vexima.rendering.impl.RenderJob;
import vexima.resource.impl.Iqm;
import vexima.resource.Resource;
import vexima.scene.cmp.Camera;
import vexima.scene.cmp.Model;
import vexima.scene.cmp.Spatial;
import vexima.scene.cmp.Transform;
import vexima.scene.Types;
import vexima.scene.Scene;
import vexima.spatial.Types;

#if vex_client
import foo3d.RenderDevice;
#end

@:access(vexima.scene.cmp.Model)
class RenderSys implements ISceneSystem {
    public var scene:Scene;

    public var mainView:Int = 0;

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

        models.onAdd.add(_onAddModel);
        models.onRemove.add(_onRemoveModel);
    }

    public function deinit() {
        models.onAdd.remove(_onAddModel);
        models.onRemove.remove(_onRemoveModel);

        transforms = null;
        cameras = null;
        models = null;
        spatials = null;
    }

    public function update(_dt:Float) {     
        var time:Int = Std.int(haxe.Timer.stamp()*1000);

#if vex_client
        var view = cameras.getEntCmp(mainView);

        // do the culling and assemble the viewsets for submission
        var res:Array<IView> = [];
        if (!Std.is(view, ICustomView))
            view.clearVisible();        
        res.push(view);
        
        var sps = spatialDB.queryFrustum(view.frustum);
        for (id in sps)
            view.addVisible(models.getEntCmp(id));

        Core.renderer.submitInterpolated(res);
#end
        //trace((Std.int(haxe.Timer.stamp()*1000) - time));
    }

    function _onAddModel(_cmp:Model) {
        
        _cmp.meshJobs = [];
        _cmp.jobs = [];
        _cmp.joints = [];
        _cmp.poses = [];
        _cmp.anims = [];
        _cmp.jointData = [];

        // grab the resources
        _cmp.localAabb.beginExtend();

        var tr = transforms.getEntCmp(_cmp.entity());

        Core.res.get(_cmp.geometry, true, 
            function _onGeoLoaded(_geo:IResourceData) { // onLoad
                var geo = cast(_geo, Iqm);

                _cmp.anims = geo.anims;
                _cmp.joints = geo.joints;
                _cmp.dqFrames = geo.dqFrames;
                _cmp.poses = geo.poses;

                for (i in 0..._cmp.poses.length) {
                    // prep the dualquat
                    _cmp.jointData.push(0.0);
                    _cmp.jointData.push(0.0);
                    _cmp.jointData.push(0.0);
                    _cmp.jointData.push(1.0);
                    _cmp.jointData.push(0.0);
                    _cmp.jointData.push(0.0);
                    _cmp.jointData.push(0.0);
                    _cmp.jointData.push(1.0);
                }

                for (m in geo.meshes) 
                {
#if vex_client
                    var rj:RenderJob = RenderJob.create(
                        new MeshData( 
                            RDIPrimType.TRIANGLES,
                            m.vstart, m.bcount
                        ),
                        cast Core.res.get(_cmp.geometry, false),
                        cast Core.res.get(m.material, false),
                        tr.matWorld,
                        m.aabb
                    );

                    if (_cmp.poses.length > 0) {
                        rj.uniforms = {
                            "jointData[0]": {type: RDIShaderConstType.FLOAT2x4, value: _cmp.jointData}
                        };
                    }
                    _cmp.meshJobs.push(rj);
                    _cmp.jobs.push(rj);
#end
                    _cmp.localAabb.extendByAabb(m.aabb);
                }

                // TODO: This might leak the resource-handle if the scene resets and the component is gone!
                models.mark(_cmp);
            }
            ,
            function _onGeoUnloaded(_geo:IResourceData) { // onUnLoad
                _cmp.joints = [];
                _cmp.jobs = [];
                _cmp.dqFrames = [];
                _cmp.poses = [];
                _cmp.jointData = [];
                _cmp.meshJobs = [];
            }
        );
    }

    function _onRemoveModel(_cmp:Model) {
        Core.res.release(_cmp.geometry);

        _cmp.meshJobs = null;
        _cmp.jobs = null;
        _cmp.joints = null;
        _cmp.poses = null;
        _cmp.anims = null;
        _cmp.jointData = null;
    }

}