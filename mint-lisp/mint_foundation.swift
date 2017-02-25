//
//  mint_foundation.swift
//  MINT
//
//  Created by NemuNeko on 2014/12/15.
//  Copyright (c) 2014年 Taizo A. All rights reserved.
//  
//  MINT Foundation structs and classes.
//  This file define basic data containers for Mint.
//  1. Vector  (struct) :
//  2. Vertex  (struct) :
//  3. Plane   (struct) :
//  4. Polygon (struct) :Polygon is consist of vertices array, and represent a 3D polygon
//  5. Mesh    (class)  :Mesh is consist of polygon array, and represend a 3D solid model
//  6. VxAttr  (class)  :VxAttr is collection of attribute of vertex, such as color and uv *TBI

import Foundation


// `epsilon` is the tolerance used by `splitPolygon()` to decide if a
// point is on the plane.
let epsilon = 1e-5


// Enum difinition for BSP /Boolean operation
// You cannot change order of cases because Planer.splitPolygon use it.
enum BSP : Int {
    case Coplanar = 0, Front, Back, Spanning, Coplanar_front, Coplanar_back
}

// # struct Vector
// Represents a 3D vector.
//


struct Vector {
    let x:Double
    let y:Double
    let z:Double
    
    init(x:Double, y:Double, z:Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    init(x:Double, y:Double) {
        self.x = x
        self.y = y
        self.z = 0
    }
    
    init(vector:Vector) {
        self = vector
    }
    
    init(_ array:[Double]) {
        switch array.count {
        case 0:
            self.x = 0
            self.y = 0
            self.z = 0
        case 1:
            self.x = array[0]
            self.y = array[0]
            self.z = array[0]
        case 2:
            self.x = array[0]
            self.y = array[1]
            self.z = 0
        default:
            self.x = array[0]
            self.y = array[1]
            self.z = array[2]
        }
    }
    
    func negated() -> Vector {
        return Vector(x:-self.x, y:-self.y, z:-self.z)
    }
    
    func abs() -> Vector {
        return Vector(x: fabs(self.x) , y: fabs(self.y) , z: fabs(self.z))
    }
    
    func times(_ k:Double) -> Vector {
        return Vector(x: k * self.x, y: k * self.y , z: k * self.z)
    }
    
    func dividedBy(_ k: Double) -> Vector {
        return Vector(x: self.x / k , y: self.y / k , z: self.z / k)
    }
    
    func dot(_ a: Vector) -> Double {
        return (self.x * a.x) + (self.y * a.y) + (self.z * a.z)
    }
    
    func cross(_ a: Vector) -> Vector {
        return Vector(x: self.y * a.z - self.z * a.y,y: self.z * a.x - self.x * a.z,z: self.x * a.y - self.y * a.x)
    }
    
    func lerp(vector a: Vector, k: Double) -> Vector {
        return Vector(vector: self + (a - self).times(k))
    }
    
    func lengthSquared() -> Double {
        return self.dot(self);
    }
    
    func length() -> Double {
        return sqrt(lengthSquared())
    }
    
    func unit() -> Vector {
        return self.dividedBy(self.length())
    }
    
    func distanceTo(_ a: Vector) -> Double {
        return (self - a).length()
    }
    
    func distanceToSquared(_ a: Vector) -> Double {
        return (self - a).lengthSquared()
    }
    
    func equals(_ a: Vector) -> Bool {
        return ((self.x == a.x) && (self.y == a.y) && (self.z == a.z))
    }
    
    func transform(_ matrix: Matrix4x4) -> Vector {
        return self * matrix
    }
    
    func toStlString() -> String {
        return "\(self.x) \(self.y) \(self.z)"
    }
    
    func toAMFString() -> String {
        return "<x>\(self.x)</x><y>\(self.y)</y><z>\(self.z)</z>"
    }
    
    func toString() -> String {
        return "(\(self.x), \(self.y), \(self.z))" //need to add fixedTo()
    }
    
    // find a vector that is somewhat perpendicular to this one
    func randomNonParallelVector() -> Vector {
        let abs = self.abs()
        
        if (abs.x <= abs.y) && (abs.x <= abs.z) {
            return Vector(x: 1,y: 0,z: 0)
        } else if (abs.y <= abs.x) && (abs.y <= abs.z) {
            return Vector(x: 0,y: 1,z: 0)
        } else {
            return Vector(x: 0,y: 0,z: 1)
        }
    }
    
    func min(_ a: Vector) -> Vector {
        return Vector(x: fmin(self.x, a.x), y: fmin(self.y, a.y), z: fmin(self.z, a.z))
    }
    
    func max(_ a: Vector) -> Vector {
        return Vector(x: fmax(self.x, a.x), y: fmax(self.y, a.y),z: fmax(self.z, a.z))
    }
}

func + (left: Vector, right:Vector) -> Vector {
    return Vector(x: left.x + right.x, y: left.y + right.y, z: left.z + right.z)
}

func - (left: Vector, right:Vector) -> Vector {
    return Vector(x: left.x - right.x, y: left.y - right.y, z: left.z - right.z)
}

func == (left: Vector, right: Vector) -> Bool {
    if (left.x == right.x) && (left.y == right.y) && (left.z == right.z) {
        return true
    } else {
        return false
    }
}

struct Vector2D {
    let x:Double
    let y:Double
    
    init(x: Double ,y: Double) {
        self.x = x
        self.y = y
    }
}

////////////////////////////////////
// # struct Vertex
// Represents a vertex of a polygon.

struct Vertex {
    let pos : Vector
    var normal : Vector = Vector(x: 0, y: 0, z: 0)
    var color = [Float](repeating: 0.5, count: 3)
    var alpha : Float = 1.0
    //var tag:Int = Tag.get.newTag
    
    // defined by `CSG.Vertex`.
    init(pos: Vector) {
        self.pos = pos
    }
    
    // Return a vertex with all orientation-specific data (e.g. vertex normal) flipped. Called when the
    // orientation of a polygon is flipped.
    func flipped() -> Vertex {
        return self
    }
    
    // Create a new vertex between this vertex and `other` by linearly
    // interpolating all properties using a parameter of `t`. Subclasses should
    // override this to interpolate additional properties.
    func interpolate(_ other: Vertex, t: Double) -> Vertex {
        let newpos = self.pos.lerp(vector: other.pos, k: t)
        return Vertex(pos: newpos)
    }
    
    // Affine transformation of vertex. Returns a new Vertex
    func transform(_ matrix: Matrix4x4) -> Vertex {
        var newvex = Vertex(pos: pos.transform(matrix))
        newvex.color = color
        return newvex
    }
    
    func toStlString() -> String {
        return "vertex " + self.pos.toStlString() + "\n"
    }
    
    func toAMFString() -> String {
        return "<vertex><coordinates>" + self.pos.toAMFString() + "</coordinates></vertex>\n"
    }
    
    func toString() -> String {
        return self.pos.toString()
    }
}

///////////////////////////////////
// # struct Plane
// Represents a plane in 3D space.

struct Plane {
    let normal : Vector
    let w : Double
    //var tag:Int = Tag.get.newTag
    
    init(normal: Vector, w: Double) {
        self.normal = normal
        self.w = w
    }
    
    // init Plane with 3 vectors
    init(a: Vector, b: Vector, c: Vector) {
        self.normal  = ((b - a).cross(c - a)).unit()
        self.w = self.normal.dot(a)
    }
    
    // init Plane with 3 vertices
    init(a: Vertex, b: Vertex, c: Vertex) {
        self.init(a: a.pos, b: b.pos, c: c.pos)
    }
    
    // init Plane with 2 Vectors, normal and point
    init(normal: Vector, point: Vector) {
        self.normal = normal.unit()
        self.w = point.dot(normal)
    }
    
    // init Plane from polygon
    init(poly: Polygon) {
        self.init(a: poly.vertices[0], b: poly.vertices[1], c: poly.vertices[2])
    }
    
    func flipped()->Plane {
        return Plane(normal: self.normal.negated(),w: -self.w)
    }
    
    func getTag() -> Int {
        return 0//self.tag
    }
    
    func equals(_ plane: Plane) -> Bool {
        return self.normal.equals(plane.normal) && self.w == plane.w
    }
    
    func transform(_ matrix: Matrix4x4) -> Plane {
        let
        ismirror = matrix.isMirroring()
        // get two vectors in the plane:
        let r = normal.randomNonParallelVector()
        let u = normal.cross(r)
        let v = normal.cross(u)
        // get 3 points in the plane:
        var point1 = normal.times(w)
        var point2 = point1 + u
        var point3 = point1 + v
        // transform the points:
        point1 = point1 * matrix
        point2 = point2 * matrix
        point3 = point3 * matrix
        // and create a new plane from the transformed points:
        var newplane = Plane(a: point1, b: point2, c: point3)
        if ismirror {
            // the transform is mirroring
            // We should mirror the plane:
            newplane = newplane.flipped()
        }
        return newplane
    }
    
    // Returns tuple:
    // .type:
    //   0: coplanar-front
    //   1: coplanar-back
    //   2: front
    //   3: back
    //   4: spanning
    // In case the polygon is spanning, returns:
    // .front: a Polygon of the front part, optional
    // .back: a Polygon of the back part, optional
    
    func splitPolygon(_ poly: Polygon) -> (type: BSP, front: Polygon?, back:Polygon?) {
        
        var polyType : Int = BSP.Coplanar.rawValue
        var types:[BSP] = []
        
        for vertex in poly.vertices {
            let t = self.normal.dot(vertex.pos) - self.w;
            let type : BSP = (t < -epsilon) ? BSP.Back : ((t > epsilon) ? BSP.Front : BSP.Coplanar)
            
            // Use bit operation to identify the polygon's relationship with Plane
            // 0 | 0 = 0 : coplanar
            // 0 | 1 = 1 : front
            // 0 | 2 = 2 : back
            // 1 | 2 = 3 : spanning
            
            polyType |= type.rawValue
            types += [type]
        }
        
        if let bspType = BSP(rawValue: polyType) {
            switch bspType {
            case BSP.Coplanar:
                let t = (self.normal.dot(Plane(poly: poly).normal) > 0 ? BSP.Coplanar_front : BSP.Coplanar_back)
                if t == BSP.Coplanar_front {
                    return (type: t, poly, nil)
                } else {
                    return (type: t, nil, poly)
                }
            case BSP.Front:
                return (type: BSP.Front, poly, nil)
            case BSP.Back:
                return (type: BSP.Back, nil, poly)
            case BSP.Spanning:
                var f : [Vertex] = []
                var b : [Vertex] = []
                
                for i in 0 ..< poly.vertices.count {
                    let j = (i + 1) % poly.vertices.count
                    let ti = types[i]
                    let tj = types[j]
                    let vi = poly.vertices[i]
                    let vj = poly.vertices[j];
                    
                    if ti != BSP.Back {
                        f += [poly.vertices[i]]
                    }
                    
                    if ti != BSP.Front {
                        b += [poly.vertices[i]]
                    }
                    
                    if ((ti.rawValue | tj.rawValue) == BSP.Spanning.rawValue) {
                        let t = (self.w - self.normal.dot(vi.pos)) / self.normal.dot(vj.pos - vi.pos)
                        let v = vi.interpolate(vj, t: t)
                        f += [v]
                        b += [v]
                    }
                }
                
                var front : Polygon? = nil
                var back : Polygon? = nil
                
                if f.count >= 3 {
                    front = Polygon(vertices: f)
                }
                if b.count >= 3 {
                    back = Polygon(vertices: b)
                }
                
                return (type: BSP.Spanning, front: front, back: back)
            default:
                print("Unexpected split polygon err", terminator: "\n")
            }
        }
        return (type: BSP.Coplanar, front: nil, back: nil)
    }
    
    // robust splitting of a line by a plane
    // will work even if the line is parallel to the plane
    func splitLineBetweenPoints(p1: Vector, p2: Vector) -> Vector{
        let direction = p2 - p1
        let angle: Double = self.normal.dot(direction)
        var labda: Double = 0
        
        if angle != 0 {
            labda = (self.w - self.normal.dot(p1)) / angle
        }else{
            labda = 0
        }
        
        if labda > 1 {
            labda = 1
        }
        
        if labda < 0 {
            labda = 0
        }
        
        return p1 + direction.times(labda)
    }
    
    func intersectWithLine(_ line: Line) -> Vector {
        return line.intersectWithPlane(self)
    }
    
    // intersection of two planes
    func intersectWithPlane(_ plane: Plane) -> Line? {
        return Line(plane1: self, plane2: plane)
    }
    
    func signedDistanceToPoint(_ point: Vector) -> Double {
        return self.normal.dot(point) - self.w;
    }
    
    func toString() -> String {
        return "[normal: " + self.normal.toString() + ", w: \(self.w)]"
    }
    
    func mirrorPoint(_ point: Vector) -> Vector {
        let distance = self.signedDistanceToPoint(point)
        let mirrored = point - self.normal.times(distance * 2.0)
        return mirrored
    }
    
    func pointOnPlane(_ point: Vector) -> Vector {
        let distance = self.signedDistanceToPoint(point)
        let onplane = point - self.normal.times(distance)
        return onplane
    }
    
}

//////////////////////////////////////
// # struct Line

struct Line {
    
    let pos : Vector
    let direction : Vector
    
    init(origin: Vector, direction: Vector) {
        pos = origin
        self.direction = direction
    }
    
    init(pt1: Vector, pt2: Vector) {
        let dir = (pt2 - pt1).unit()
        pos = pt1
        direction = dir
    }
    
    init?(plane1: Plane, plane2: Plane) {
        let dir = plane1.normal.cross(plane2.normal)
        let l = dir.length()
        
        if l < 1e-10 {
            print("Parallel planes")
            return nil
        }
        
        direction = dir.times(1.0 / l);
    
        let mabsx = abs(direction.x)
        let mabsy = abs(direction.y)
        let mabsz = abs(direction.z)
        
        if (mabsx >= mabsy) && (mabsx >= mabsz) {
            // direction vector is mostly pointing towards x
            // find a point p for which x is zero:
            let r = solve2Linear(plane1.normal.y, b: plane1.normal.z, c: plane2.normal.y, d: plane2.normal.z, u: plane1.w, v: plane2.w)
            pos = Vector(x: 0, y: r.0, z: r.1)
        } else if((mabsy >= mabsx) && (mabsy >= mabsz)) {
            // find a point p for which y is zero:
            let r = solve2Linear(plane1.normal.x, b: plane1.normal.z, c: plane2.normal.x, d: plane2.normal.z, u: plane1.w, v: plane2.w)
            pos = Vector(x: r.0, y: 0, z: r.1)
        } else {
            // find a point p for which z is zero:
            let r = solve2Linear(plane1.normal.x, b: plane1.normal.y, c: plane2.normal.x, d: plane2.normal.y, u: plane1.w, v: plane2.w)
            pos = Vector(x: r.0, y: r.1, z: 0)
        }
    }
    
    func intersectWithPlane(_ plane: Plane) -> Vector {
        
       
        // plane: plane.normal * p = plane.w
        // line: p=line.point + labda * line.direction
        let labda = (plane.w - plane.normal.dot(self.pos)) / plane.normal.dot(self.direction)
        let point = pos + (direction.times(labda))
        return point
    }
    
    func clone() -> Line {
        return Line(origin: pos, direction: direction)
    }
    
    func reverse() -> Line {
        return Line(origin: pos, direction: direction.negated())
    }
    
    func transform(_ mat:Matrix4x4) -> Line{
        let newpoint = pos * mat
        let pointPlusDirection = pos + direction
        let newPointPlusDirection = pointPlusDirection * mat
        let newdirection = newPointPlusDirection - newpoint
        return Line(origin: newpoint, direction: newdirection)
    }
    
    func closestPointOnLine(_ point: Vector) -> Vector {
        let t = (point - pos).dot(direction) / direction.dot(direction)
        let closestpoint = pos + direction.times(t)
        return closestpoint
    }
    
    func distanceToPoint(_ point: Vector) -> Double {
        let closestpoint = closestPointOnLine(point)
        let distancevector = point - closestpoint
        let distance = distancevector.length()
        return distance
    }
    
    func equals(_ line: Line) -> Bool{
        if !(direction == line.direction) {
            return false
        }
        
        let distance = distanceToPoint(line.pos)
        if distance > 1e-8 {
            return false
        }
        return true
    }
}

//////////////////////////////////////
// # struct LineSegment

struct LineSegment {
    
    let points : [Vertex]
    
    var from : Vertex {
        get {
            return points[0]
        }
    }
    
    var to : Vertex {
        get {
            return points[1]
        }
    }
    
    init(from: Vertex, to: Vertex) {
        points = [from] + [to]
    }
    
    init(line: Line, length: Double) {
        
        let endpoint = line.pos + line.direction.times(length)
        
        points = [Vertex(pos: line.pos)] + [Vertex(pos:endpoint)]
    }
    
    func projectPtsOnPlane(_ plane: Plane) -> LineSegment {
        
        var newpoints : [Vertex] = []
        
        for pt in points {
            let distance = abs(plane.signedDistanceToPoint(pt.pos))
            if distance > epsilon {
                var newvex = Vertex(pos: plane.pointOnPlane(pt.pos))
                newvex.alpha = pt.alpha
                newvex.color = pt.color
                newvex.normal = plane.normal
                
                newpoints.append(newvex)
            } else {
                newpoints.append(pt)
            }
        }
        
        return LineSegment(from: newpoints[0], to: newpoints[1])
    }
    
    func projectPtsOnPlane() -> LineSegment {
        
        let plane : Plane = Plane(normal: Vector(x: 0, y: 0, z: 1), point: Vector(x: 0, y: 0, z: 0))
        
        return projectPtsOnPlane(plane)
    }
    
    func line() -> Line {
        
        let dir = (points[1].pos - points[0].pos).unit()
        
        return Line(origin: points[0].pos, direction: dir)
    }
}

//////////////////////////////////////
// # struct Path
// 'Path' represent path in 3d space.
// It don't have to be on same plane.

struct Path {
    
    var closed : Bool
    var points : [Vertex]
    
    var lines : [LineSegment] {
        get {
            
            let points = remove_duplicate_points().points
            var lines : [LineSegment] = []
            
            for i in stride(from:0, to: lines.count-1, by: 1) {
                lines.append(LineSegment(from: points[i], to: points[i+1]))
            }
            return lines
        }
    }
    
    var plane : Plane {
        get {
            if points.count > 2 {
                return Plane(a: points[0], b: points[1], c: points[2])
            } else {
                return Plane(normal: Vector(x: 0, y: 0, z: 1), point: Vector(x: 0, y: 0, z: 0))
            }
        }
    }
    
    init(points: [Vertex], closed : Bool) {
        self.closed = closed
        self.points = points
    }
    
    init(lines: [LineSegment]) {
        
        var acc : [Vertex] = []
        
        for ln in lines {
            acc += ln.points
        }
        
        closed = false
        
        if let first = acc.first, let last = acc.last {
            let distance = first.pos.distanceTo(last.pos)
            if distance < epsilon {
                closed = true
            }
        }
        
        points = acc
    }
    
    func remove_duplicate_points() -> Path {
        // re-parse the points into CSG.Vector2D
        // and remove any duplicate points
        var prevpoint : Vertex? = nil
        
        if closed && (points.count > 0) {
            prevpoint = Vertex(pos: points[points.count - 1].pos)
        }
        
        var newpoints : [Vertex] = []
        
        for pt in points {
            var skip = false
            
            if let prev = prevpoint {
                let distance = pt.pos.distanceTo(prev.pos)
                if distance < epsilon {
                    skip = true
                }
            }
            
            if !skip {
                newpoints += [pt]
            }
            
            prevpoint = pt
        }
        
        return Path(points: newpoints, closed: closed)
    }
    
    func projectPtsOnPlane(_ plane: Plane) -> Path {
        
        var newpoints : [Vertex] = []
        
        for pt in points {
            let distance = abs(plane.signedDistanceToPoint(pt.pos))
            if distance > epsilon {
                var newvex = Vertex(pos: plane.pointOnPlane(pt.pos))
                newvex.alpha = pt.alpha
                newvex.color = pt.color
                newvex.normal = plane.normal
                
                newpoints.append(newvex)
            } else {
                newpoints.append(pt)
            }
        }
        
        return Path(points: newpoints, closed: closed)
    }
    
    func projectPtsOnPlane() -> Path {
        return projectPtsOnPlane(plane)
    }
}

///////////////////////////////////////////
//# struct Shape
//
// 'Shape' represent 2D geometry, which is enclosed and on same plane.
// Also, it can be manipulated with CGS style operation when all 'shapes" are on same plane.

struct Shape {
    var linesegs : [LineSegment]
    var plane : Plane
    
    init(path: Path) {
        
        let projected = path.projectPtsOnPlane()
        
        plane = projected.plane
        linesegs = projected.lines
        
        if !projected.closed {
            if let firstpt = projected.lines.first?.from, let lastpt = projected.lines.last?.to {
                linesegs.append(LineSegment(from: firstpt, to: lastpt))
            }
        }
    }
    
    init(path: Path, plane: Plane) {
        
        let projected = path.projectPtsOnPlane(plane)
        
        self.plane = plane
        linesegs = projected.lines
        
        if !projected.closed {
            if let firstpt = projected.lines.first?.from, let lastpt = projected.lines.last?.to {
                linesegs.append(LineSegment(from: firstpt, to: lastpt))
            }
        }
    }
    
    init(lines: [LineSegment]) {
        let path = Path(lines: lines).projectPtsOnPlane()
        
        plane = path.plane
        self.linesegs = path.lines
        
        if !path.closed {
            if let firstpt = path.lines.first?.from, let lastpt = path.lines.last?.to {
                linesegs.append(LineSegment(from: firstpt, to: lastpt))
            }
        }
    }
    
    
    init(lines: [LineSegment], plane: Plane) {
        let path = Path(lines: lines).projectPtsOnPlane(plane)
        
        self.plane = plane
        self.linesegs = path.lines
        
        if !path.closed {
            if let firstpt = path.lines.first?.from, let lastpt = path.lines.last?.to {
                linesegs.append(LineSegment(from: firstpt, to: lastpt))
            }
        }
    }
}

//# struct Polygon
// Represents a convex polygon. The vertices used to initialize a polygon must
// be coplanar and form a convex loop.
//
// Each convex polygon has a `shared` property, which is shared between all
// polygons that are clones of each other or were split from the same polygon.
// This can be used to define per-polygon properties (such as surface color).
//
// The plane of the polygon is calculated from the vertex coordinates
// To avoid unnecessary recalculation, the plane can alternatively be
// passed as the third argument

struct Polygon {
    var vertices : [Vertex]
    //let shared : Int
    let plane : Plane
    
    var boxBound : (min: Vector, max: Vector)? = nil
    var sphereBound : (middle:Vector ,radius: Double)? = nil
    
    init(vertices : [Vertex], shared : Int, plane : Plane) {
        self.vertices = vertices
        //self.shared = shared
        self.plane = plane
        
        // After initalize properties, setup normals.
        if vertices.count >= 3 {
            self.generateNormal()
        }
    }
    
    init(vertices : [Vertex], plane : Plane) {
        self.vertices = vertices
        self.plane = plane
        
        // After initalize properties, setup normals.
        if vertices.count >= 3 {
            self.generateNormal()
        }
    }
    
    init(vertices: [Vertex]) {
        self.vertices = vertices
        self.plane = Plane(a: vertices[0],b: vertices[1],c: vertices[2])
        
        // After initalize properties, setup normals.
        if vertices.count >= 3 {
            self.generateNormal()
        }
    }
    
    // check whether the polygon is convex (it should be, otherwise we will get unexpected results)
    func checkIfConvex() -> Bool {
        
        return verticesConvex(self.vertices, normal: self.plane.normal)
        
        /*
        // original method. comment outed
        
        if verticesConvex(self.vertices, normal: self.plane.normal) {
            verticesConvex(self.vertices, normal: self.plane.normal)
            print("Not Convex polygon found!")
            //throw new Error("Not convex!")
        }

        */
    }
    
    mutating func generateNormal() {
        let a = self.vertices[1].pos - self.vertices[0].pos
        let b = self.vertices[2].pos - self.vertices[0].pos
        
        let polyNormal = a.cross(b).unit()
        
        for i in 0 ..< self.vertices.count {
            self.vertices[i].normal = polyNormal
        }
    }
    
    
    // returns an array with a CSG.Vector3D (center point) and a radius
    mutating func boundingSphere() -> (middle: Vector, radius: Double) {
        if let ischached = sphereBound {
            return ischached
        } else {
            let box = boundingBox()
            let middle = (box.min + box.max).times(0.5)
            let radius3 = box.max - middle
            let radius = radius3.length()
            
            sphereBound = (middle: middle, radius: radius)
            
            return (middle: middle, radius: radius)
        }
    }
    
    // returns an tuple of two Vectors (minimum coordinates and maximum coordinates)
    mutating func boundingBox() -> (min: Vector, max: Vector) {
        if let iscached = boxBound {
            return iscached
        } else {
            var minpoint : Vector , maxpoint : Vector
            
            if vertices.count > 0 {
                minpoint = vertices[0].pos
            } else {
                minpoint = Vector(x: 0, y: 0, z: 0)
            }
            
            maxpoint = minpoint
            
            for vex in vertices {
                let point = vex.pos;
                minpoint = minpoint.min(point)
                maxpoint = maxpoint.max(point)
            }
            boxBound = (min: minpoint, max: maxpoint)
            return (min: minpoint, max: maxpoint)
        }
    }
    
    func flipped() -> Polygon {
        let newvertices : [Vertex] = Array(vertices.reversed())
        var newPoly = Polygon(vertices: newvertices)
        newPoly.generateNormal()
        //var newplane = plane.flipped()
        return newPoly
    }
    
    func toStlString() -> String {
        var result = ""
        if(self.vertices.count >= 3) // should be!
        {
            // STL requires triangular polygons. If our polygon has more vertices, create
            // multiple triangles:
            let firstVertexStl = self.vertices[0].toStlString()
            for i in 0 ..< self.vertices.count - 2 {
                result += "facet normal " + self.plane.normal.toStlString() + "\nouter loop\n"
                result += firstVertexStl
                result += self.vertices[i + 1].toStlString()
                result += self.vertices[i + 2].toStlString()
                result += "endloop\nendfacet\n"
            }
        }
        return result
    }
    
    func toString() -> String {
        var result = "Polygon plane: " + self.plane.toString() + "\n"
        
        for vertex in self.vertices {
            result += "  " + vertex.toString() + "\n";
        }
        return result
    }
    
    func triangulationConvex() -> [Polygon] {
        
        var triangles : [Polygon] = []
        
        for i in stride(from: 2, to: vertices.count, by: 1) {
            let vexs = [vertices[0], vertices[i-1], vertices[i]]
            triangles += [Polygon(vertices: vexs)]
        }
        
        return triangles
    }
    
    func verticesConvex(_ vertices: [Vertex], normal: Vector) -> Bool {
        if vertices.count > 2 {
            var prevprevpos = vertices[vertices.count - 2].pos
            var prevpos = vertices[vertices.count - 1].pos
            
            for i in 0 ..< vertices.count {
                let pos = vertices[i].pos
                if !isConvexPoint(prevprevpos, point: prevpos, nextpoint: pos, normal: normal) {
                    return false
                }
                prevprevpos = prevpos
                prevpos = pos
            }
        }
        return true
    }
    
    func isConvexPoint(_ prevpoint: Vector, point: Vector, nextpoint: Vector, normal: Vector) -> Bool {
        let crossproduct = point - prevpoint.cross(nextpoint - point)
        let crossdotnormal = crossproduct.dot(normal)
        return (crossdotnormal >= 0)
    }
}

class Mesh {
    var mesh:[Polygon] = []
    var boxBound : (min: Vector, max: Vector)? = nil
    
    init(m: [Polygon]) {
        mesh = m;
    }
    
    func meshArray() -> [Double] {
        
        var mesharray:[Double] = []
        
        for polygon in mesh {
            
            if polygon.vertices.count == 3 {
                for vertex in polygon.vertices {
                    mesharray += [vertex.pos.x, vertex.pos.y, vertex.pos.z]
                }
            } else if polygon.vertices.count > 3 {
                // if polygon is not triangle, split it to triangle polygons
                
                //if polygon.checkIfConvex() {
                    
                    let triangles = polygon.triangulationConvex()
                    
                    for tri in triangles {
                        for vertex in tri.vertices {
                            mesharray += [vertex.pos.x, vertex.pos.y, vertex.pos.z]
                        }
                    }
                    
                //} else {
                    
                //}
            }
        }
        
        return mesharray
    }
    
    func normalArray() -> [Double] {
        var normals:[Double] = []
        
        for polygon in mesh {
            if polygon.vertices.count == 3 {
                for vertex in polygon.vertices {
                    normals += [vertex.normal.x, vertex.normal.y, vertex.normal.z]
                }
            } else if polygon.vertices.count > 3 {
                // if polygon is not triangle, split it to triangle polygons
                
                //if polygon.checkIfConvex() {
                
                var triangles = polygon.triangulationConvex()
                
                for i in stride(from: 0, to: triangles.count, by: 1) {
                    triangles[i].generateNormal()
                    for vertex in triangles[i].vertices {
                        normals += [vertex.normal.x, vertex.normal.y, vertex.normal.z]
                    }
                }
                
                //} else {
                
                //}
            }
        }
        
        return normals
    }
    
    func colorArray() -> [Float] {
        var colors:[Float] = []
        
        for polygon in mesh {
            
            if polygon.vertices.count == 3 {
                for vertex in polygon.vertices {
                    colors += vertex.color
                }
            } else if polygon.vertices.count > 3 {
                // if polygon is not triangle, split it to triangle polygons
                
                //if polygon.checkIfConvex() {
                
                let triangles = polygon.triangulationConvex()
                
                for tri in triangles {
                    for vertex in tri.vertices {
                        colors += vertex.color
                    }
                }
                
                //} else {
                
                //}
            }

        }
        
        return colors
    }
    
    // returns an tuple of two Vectors (minimum coordinates and maximum coordinates)
    func getBounds() -> (min: Vector, max: Vector) {
        if let isCached = boxBound {
            return isCached
        } else {
            var minpoint = Vector(x: 0, y: 0, z: 0)
            var maxpoint = Vector(x: 0, y: 0, z: 0)
            
            for i in stride(from: 0, to: mesh.count, by: 1) {
				let bounds = mesh[i].boundingBox()
                
                minpoint = minpoint.min(bounds.min)
                maxpoint = maxpoint.max(bounds.max)
            }
            boxBound = (minpoint, maxpoint)
            return (minpoint, maxpoint)
        }
    }
    
    // returns true if there is a possibility that the two solids overlap
    // returns false if we can be sure that they do not overlap
    func mayOverlap(_ other: Mesh) -> Bool {
    
        if (mesh.count == 0) || (other.mesh.count == 0) {
            return false
        } else {
            let mybounds = getBounds()
            let otherbounds = other.getBounds()
            // [0].x/y
            //    +-----+
            //    |     |
            //    |     |
            //    +-----+
            //          [1].x/y
            //return false;
            //echo(mybounds,"=",otherbounds);
            if mybounds.max.x < otherbounds.min.x {
                return false
            }
            if mybounds.min.x > otherbounds.max.x {
                return false
            }
            if mybounds.max.y < otherbounds.min.y {
                return false
            }
            if mybounds.min.y > otherbounds.max.y {
                return false
            }
            if mybounds.max.z < otherbounds.min.z {
                return false
            }
            if mybounds.min.z > otherbounds.max.z {
                return false
            }
            return true
        }
    }
}

///////////////////////////////
// # Utilities

// solve 2x2 linear equation:
// [ab][x] = [u]
// [cd][y]   [v]

func solve2Linear(_ a: Double, b: Double, c: Double, d: Double, u: Double, v: Double) -> (Double, Double) {
    let det = a * d - b * c
    let invdet = 1.0 / det
    var x = u * d - b * v
    var y = -u * c + a * v
    x *= invdet
    y *= invdet
    return (x, y)
}
