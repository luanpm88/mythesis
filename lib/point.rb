#
# Point class, for representing a coordinate in 2D space
#
 
class Point
  attr_accessor :x, :y
 
# Constructor that takes in an x,y coordinate
  def initialize(x,y)
    @x = x
    @y = y
  end
 
  # Calculates the distance to Point p
  def dist_to(p)
    xs = (@x - p.x)**2
    ys = (@y - p.y)**2
    return Math::sqrt(xs + ys)
  end
 
  # Return a String representation of the object
  def to_s
    return "(#{@x}, #{@y})"
  end
end

