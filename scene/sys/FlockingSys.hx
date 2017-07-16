package vexima.scene.sys;

import vexima.math.MathUtils;
import vexima.math.Vec3;
import vexima.scene.cmp.Spatial;
import vexima.scene.cmp.Boid;
import vexima.scene.cmp.Transform;
import vexima.scene.Types;
import vexima.scene.Scene;
import vexima.spatial.Types;

class FlockingSys implements ISceneSystem {
	public var scene:Scene;

	var transforms:TransformArray;
	var spatials:SpatialArray;
	var boids:BoidArray;

	var spatialDB:SpatialHash3D;

	public function new(_spatialDB:SpatialHash3D) {
		spatialDB = _spatialDB;
	}

	public function init() {
		transforms = scene.access(TransformArray);
		spatials = scene.access(SpatialArray);
		boids = scene.access(BoidArray);
	}

	public function deinit() {
		transforms = null;
		spatials = null;
		boids = null;
	}

	public function update(_dt:Float) {
		var time:Int = Std.int(haxe.Timer.stamp()*1000);

		// mark for all for update
		for (b in boids)
			boids.mark(b);

		// do multithreaded update
		boids.eachChange(function(_b:Boid) {

			// reset
			_b.accel.set(0, 0, 0);
			
			// calc factors
			var sep = _separate(_b);
			var ali = _alignAndCohesion(_b);

			// apply random weights
			sep *= 2;

			// now update
			_b.accel += sep;
			_b.accel += ali;

			_b.velocity += _b.accel;
			_limit(_b.velocity, _b.maxSpeed);
			
			var tr = transforms.getEntCmp(_b.entity());
			tr.position += _b.velocity;
			
			// wrap borders
			var r = 1000;
			if (tr.position.x < -r) tr.position.x = r;
			if (tr.position.y < -r) tr.position.y = r;
			if (tr.position.z < -r) tr.position.z = r;

			if (tr.position.x > r) tr.position.x = -r;
			if (tr.position.y > r) tr.position.y = -r;
			if (tr.position.z > r) tr.position.z = -r;

		}, function(_b:Boid) {
			var tr = transforms.getEntCmp(_b.entity());
			transforms.mark(tr);
			boids.done(_b);			
		});

		trace((Std.int(haxe.Timer.stamp()*1000) - time));
	}

	inline function _separate(_b:Boid):Vec3 {
		var desiredSep = 5.0;
		var sum = new Vec3(0,0,0);
		var count = 0;

		var tr = transforms.getEntCmp(_b.entity());
		var sps = spatialDB.querySphere(tr.position, desiredSep);
		for (ent in sps) {
			if (ent == _b.entity()) continue; // ignore yourself

			var other = transforms.getEntCmp(ent);
			if (other != null) {
				var diff = tr.position - other.position;
				var dist = diff.length();
		
				diff /= dist; // weight by distance
				sum += diff;
				count++;
			}
		}

		if (count > 0)
			sum /= count; // average

		return sum;
	}

	inline function _alignAndCohesion(_b:Boid):Vec3 {
		var neighborDist = 50.0;
		var aliSum = new Vec3(0,0,0);
		var aliCount = 0;

		var cohSum = new Vec3(0,0,0);
		var cohCount = 0;

		var tr = transforms.getEntCmp(_b.entity());
		var sps = spatialDB.querySphere(tr.position, neighborDist);
		for (ent in sps) {
			if (ent == _b.entity()) continue; // ignore yourself

			var other = boids.getEntCmp(ent);
			if (other != null) {
				aliSum += other.velocity;
				aliCount++;
			}
			var other2 = transforms.getEntCmp(ent);
			if (other2 != null) {
				cohSum += other2.position;
				cohCount++;
			}
		}

		if (aliCount > 0) { // average & limit
			aliSum /= aliCount; 
			_limit(aliSum, _b.maxForce);
		}

		if (cohCount > 0) {
			cohSum /= cohCount; // average
			cohSum = _steer(_b, tr, cohSum, false);
		}

		return aliSum + cohSum;
	}

	function _steer(_b:Boid, _tr:Transform, _target:Vec3, _slowdown:Bool) {
		var steer = new Vec3(0,0,0);
		var desired = _target - _tr.position;

		var d = desired.normalize();
		if (d > 0) {
			if (_slowdown && d < 10.0) 
				desired *= _b.maxSpeed * (d/10.0); // random damping?!?
			else
				desired *= _b.maxSpeed * (d/100.0);

			steer = desired - _b.velocity;

			_limit(steer, _b.maxForce);
		}
		return steer;
	}

	inline function _limit(_v:Vec3, _max:Float) {
		if (_v.lengthSquared() > _max*_max) {
			_v.normalize();
			_v *= _max;
		}
	}

	/*	
	inline function _calcFlock(_b:Boid):Vec3 {
		var range = 50.0;

		var sepSum = new Vec3(0,0,0);
		var sepCount = 0;

		var aliSum = new Vec3(0,0,0);
		var aliCount = 0;

		var cohSum = new Vec3(0,0,0);
		var cohCount = 0;

		var tr = transforms.getEntCmp(_b.entity());
		var sps = spatialDB.querySphere(tr.position, range);
		for (ent in sps) {
			if (ent == _b.entity()) continue; // ignore yourself			

			var other = transforms.getEntCmp(ent);
			if (other != null) {
				var diff = tr.position - other.position;
				var dist = diff.length();

				if (dist < 5.0) {
					diff /= dist; // weight by distance
					sepSum += diff;
					sepCount++;
				}

				cohSum += other.position;
				cohCount++;
			}


			var other2 = boids.getEntCmp(ent);
			if (other2 != null) {
				aliSum += other2.velocity;
				aliCount++;
			}
		}

		if (sepCount > 0)
			sepSum /= sepCount; // average

		if (aliCount > 0) { // average & limit
			aliSum /= sepCount; 
			_limit(aliSum, _b.maxForce);
		}

		if (cohCount > 0) {
			cohSum /= cohCount; // average
			cohSum = _steer(_b, tr, cohSum, false);
		}

		// apply random weights
		sepSum *= 2;
		sepSum += aliSum;
		sepSum += cohSum;
		return sepSum;
	}

	inline function _align2(_b:Boid):Vec3 {
		var neighborDist = 50.0;
		var sum = new Vec3(0,0,0);
		var count = 0;

		var tr = transforms.getEntCmp(_b.entity());
		var sps = spatialDB.querySphere(tr.position, neighborDist);
		for (ent in sps) {
			if (ent == _b.entity()) continue; // ignore yourself

			var other = boids.getEntCmp(ent);
			if (other != null) {
				sum += other.velocity;
				count++;
			}
		}

		if (count > 0) { // average & limit
			sum /= count; 
			_limit(sum, _b.maxForce);
		}

		return sum;
	}

	inline function _cohesion(_b:Boid):Vec3 {
		var neighborDist = 50.0;
		var sum = new Vec3(0,0,0);
		var count = 0;

		var tr = transforms.getEntCmp(_b.entity());
		var sps = spatialDB.querySphere(tr.position, neighborDist);
		for (ent in sps) {
			if (ent == _b.entity()) continue; // ignore yourself

			var other = transforms.getEntCmp(ent);
			if (other != null) {
				sum += other.position;
				count++;
			}
		}

		if (count > 0) {
			sum /= count; // average
			return _steer(_b, tr, sum, false);
		}

		return sum;
	}
	*/

	

}