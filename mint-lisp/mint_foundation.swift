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


// Enum difinition for BSP /Boolean operation
// You cannot change order of cases because Planer.splitPolygon use it.
enum BSP : Int {
    case Coplanar = 0, Front, Back, Spanning, Coplanar_front, Coplanar_back
}

// # struct Vector
// Represents a 3D vector.
//
// Example usage:
//
//     new Vector(x: 1,y: 2,z: 3)
//     new Vector([1, 2, 3])
//     new Vector(x: 1, y: 2) // assume z=0
//     new Vector([1, 2]) // assume z=0

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
    
    func times(k:Double) -> Vector {
        return Vector(x: k * self.x, y: k * self.y , z: k * self.z)
    }
    
    func dividedBy(k: Double) -> Vector {
        return Vector(x: self.x / k , y: self.y / k , z: self.z / k)
    }
    
    func dot(a: Vector) -> Double {
        return (self.x * a.x) + (self.y * a.y) + (self.z * a.z)
    }
    
    func cross(a: Vector) -> Vector {
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
    
    func distanceTo(a: Vector) -> Double {
        return (self - a).length()
    }
    
    func distanceToSquared(a: Vector) -> Double {
        return (self - a).lengthSquared()
    }
    
    func equals(a: Vector) -> Bool {
        return ((self.x == a.x) && (self.y == a.y) && (self.z == a.z))
    }
    
    func transform(matrix: Matrix4x4) -> Vector {
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
    
    func min(a: Vector) -> Vector {
        return Vector(x: fmin(self.x, a.x), y: fmin(self.y, a.y), z: fmin(self.z, a.z))
    }
    
    func max(a: Vector) -> Vector {
        return Vector(x: fmax(self.x, a.x), y: fmax(self.y, a.y),z: fmax(self.z, a.z))
    }
}

func + (left: Vector, right:Vector) -> Vector {
    return Vector(x: left.x + right.x, y: left.y + right.y, z: left.z + right.z)
}

func - (left: Vector, right:Vector) -> Vector {
    return Vector(x: left.x - right.x, y: left.y - right.y, z: left.z - right.z)
}

// # struct Vector2D

struct Vector2D {
    let x:Double
    let y:Double
}


// # struct Vertex
// Represents a vertex of a polygon. Use your own vertex class instead of this
// one to provide additional features like texture coordinates and vertex
// colors. Custom vertex classes need to provide a `pos` property
// `flipped()`, and `interpolate()` methods that behave analogous to the ones
// defined by `CSG.Vertex`.

struct Vertex {
    let pos : Vector
    var normal : Vector = Vector(x: 0, y: 0, z: 0)
    var color = [Float](count: 3, repeatedValue: 0.5)
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
    func interpolate(other: Vertex, t: Double) -> Vertex {
        var newpos = self.pos.lerp(vector: other.pos, k: t)
        return Vertex(pos: newpos)
    }
    
    // Affine transformation of vertex. Returns a new Vertex
    func transform(matrix: Matrix4x4) -> Vertex {
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

// # struct Plane
// Represents a plane in 3D space.

struct Plane {
    let normal : Vector
    let w : Double
    //var tag:Int = Tag.get.newTag
    
    // `epsilon` is the tolerance used by `splitPolygon()` to decide if a
    // point is on the plane.
    static let epsilon = 1e-5
    
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
    
    func equals(plane: Plane) -> Bool {
        return self.normal.equals(plane.normal) && self.w == plane.w
    }
    
    func transform(matrix: Matrix4x4) -> Plane {
        var ismirror = matrix.isMirroring()
        // get two vectors in the plane:
        var r = normal.randomNonParallelVector()
        var u = normal.cross(r)
        var v = normal.cross(u)
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
    
    func splitPolygon(poly: Polygon) -> (type: BSP, front: Polygon?, back:Polygon?) {
        
        var polyType : Int = BSP.Coplanar.rawValue
        var types:[BSP] = []
        
        for vertex in poly.vertices {
            let t = self.normal.dot(vertex.pos) - self.w;
            var type : BSP = (t < -Plane.epsilon) ? BSP.Back : ((t > Plane.epsilon) ? BSP.Front : BSP.Coplanar)
            
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
                var t = (self.normal.dot(Plane(poly: poly).normal) > 0 ? BSP.Coplanar_front : BSP.Coplanar_back)
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
                
                for var i = 0; i < poly.vertices.count; i++ {
                    var j = (i + 1) % poly.vertices.count
                    var ti = types[i]
                    var tj = types[j]
                    var vi = poly.vertices[i]
                    var vj = poly.vertices[j];
                    
                    if ti != BSP.Back {
                        f += [poly.vertices[i]]
                    }
                    
                    if ti != BSP.Front {
                        b += [poly.vertices[i]]
                    }
                    
                    if ((ti.rawValue | tj.rawValue) == BSP.Spanning.rawValue) {
                        var t = (self.w - self.normal.dot(vi.pos)) / self.normal.dot(vj.pos - vi.pos)
                        var v = vi.interpolate(vj, t: t)
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
                println("Unexpected split polygon err")
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
    
    /*
    // returns CSG.Vector3D
    intersectWithLine: function(line3d) {
    return line3d.intersectWithPlane(this);
    },
    
    // intersection of two planes
    intersectWithPlane: function(plane) {
    return CSG.Line3D.fromPlanes(this, plane);
    },
    */
    
    func signedDistanceToPoint(point: Vector) -> Double {
        return self.normal.dot(point) - self.w;
    }
    
    func toString() -> String {
        return "[normal: " + self.normal.toString() + ", w: \(self.w)]"
    }
    
    func mirrorPoint(point: Vector) -> Vector {
        var distance = self.signedDistanceToPoint(point)
        var mirrored = point - self.normal.times(distance * 2.0)
        return mirrored
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
            println("Not Convex polygon found!")
            //throw new Error("Not convex!")
        }

        */
    }
    
    mutating func generateNormal() {
        let a = self.vertices[1].pos - self.vertices[0].pos
        let b = self.vertices[2].pos - self.vertices[0].pos
        
        let polyNormal = a.cross(b).unit()
        
        for var i = 0; i < self.vertices.count; i++ {
            self.vertices[i].normal = polyNormal
        }
    }
    
    
    // returns an array with a CSG.Vector3D (center point) and a radius
    mutating func boundingSphere() -> (middle: Vector, radius: Double) {
        if let ischached = sphereBound {
            return ischached
        } else {
            var box = boundingBox()
            var middle = (box.min + box.max).times(0.5)
            var radius3 = box.max - middle
            var radius = radius3.length()
            
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
                var point = vex.pos;
                minpoint = minpoint.min(point)
                maxpoint = maxpoint.max(point)
            }
            boxBound = (min: minpoint, max: maxpoint)
            return (min: minpoint, max: maxpoint)
        }
    }
    
    func flipped() -> Polygon {
        var newvertices : [Vertex] = vertices.reverse()
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
            var firstVertexStl = self.vertices[0].toStlString()
            for var i = 0; i < self.vertices.count - 2; i++ {
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
        
        for var i = 2; vertices.count > i; i++ {
            let vexs = [vertices[0], vertices[i-1], vertices[i]]
            triangles += [Polygon(vertices: vexs)]
        }
        
        return triangles
    }
    
    func verticesConvex(vertices: [Vertex], normal: Vector) -> Bool {
        if vertices.count > 2 {
            var prevprevpos = vertices[vertices.count - 2].pos
            var prevpos = vertices[vertices.count - 1].pos
            
            for var i = 0; i < vertices.count; i++ {
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
    
    func isConvexPoint(prevpoint: Vector, point: Vector, nextpoint: Vector, normal: Vector) -> Bool {
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
                
                for var i = 0; triangles.count > i; i++ {
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
            
            for var i = 0; mesh.count > i; i++ {
				var bounds = mesh[i].boundingBox()
                
                minpoint = minpoint.min(bounds.min)
                maxpoint = maxpoint.max(bounds.max)
            }
            boxBound = (minpoint, maxpoint)
            return (minpoint, maxpoint)
        }
    }
    
    // returns true if there is a possibility that the two solids overlap
    // returns false if we can be sure that they do not overlap
    func mayOverlap(other: Mesh) -> Bool {
    
        if (mesh.count == 0) || (other.mesh.count == 0) {
            return false
        } else {
            var mybounds = getBounds()
            var otherbounds = other.getBounds()
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