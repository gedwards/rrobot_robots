module RobotFunctions

  class Box
    attr_accessor :a, :b, :x, :y

    def initialize(a,b,x,y)
      @a, @b, @x, @y = a,b,x,y
    end

    def [](index)
      rect[index]
    end

    def rect
      [@a,@b,@x,@y]
    end

  end

  #----------------------------------------------------

  def grow(by_x, by_y, a,b,x,y)
    [a - by_x, b - by_y, x + by_x, y + by_y]
  end

  def scale(box)
    [scale_x(box.a), scale_y(box.b), scale_x(box.x), scale_y(box.y)]
  end

  def scale_x(val); (((val*1.0)/battlefield_width) * 800).to_i end
  def scale_y(val); (((val*1.0)/battlefield_height) * 800).to_i end

	# Gets the location of an object given the heading and distance
	def location(x, y, theta, distance)
	  [x + distance * Math.cos(theta), y - distance * Math.sin(theta)]
	end

  def distance_to(point)
    Math.hypot(point.x - x, point.y - y)
  end

  def near_wall
    stay_away = size * 6
    return true if x < stay_away
    return true if x > battlefield_width - stay_away
    return true if y < stay_away
    return true if y > battlefield_height - stay_away
  end

  def compute_radar_box(x,y,distance,sweep)
    p1 = location(x,y,sweep[0].to_rad,distance)
    p2 = location(x,y,sweep[1].to_rad,distance)
    xx = [p1[0],p2[0]] # group the x's together so that we can do min/max on the array
    yy = [p1[1],p2[1]] # group the y's together so that we can do min/max on the array
    box = Box.new(xx.min.to_i,yy.min.to_i,xx.max.to_i,yy.max.to_i) # the enclosing rectangle
    {
      :rect=> box,
      :color =>0xFFFFffff, # color
      :age => 1, # age = 1
      :distance => distance
    }
  end

  def see_target?
    !events['robot_scanned'].empty?
  end
  #----------------------------------------------------
  DEG = Math:: PI / 180.0 
  def self.angle_between(a,b,x,y)
    heading = Math::atan2(b-y,x-a) / DEG % 360 # NOTE: using b-y instead of y-b because y increases DOWNWARD
  end         

  def avg_angle(a,b)
    diff = ( ( a - b + 180 + 360 ) % 360 ) - 180
    angle = (360 + b + ( diff / 2 ) ) % 360
  end

  def angle_diff(a,b)
    diff = ( ( a - b + 180 + 360 ) % 360 ) - 180
  end

  class EmptyImageStub
    def initialize(w,h)
      @w, @h = w, h;
    end

    def to_blob
      "\0" * @w * @h * 4
    end

    def rows
      @h
    end

    def columns
      @w
    end
  end

  def empty(w,h)
    stub = EmptyImageStub.new(w,h)
    return Gosu::Image.new($p,stub,true)
    # return Gosu::Image.new(MainWindow.instance,stub,true)
  end


  def self.distance_between(a,b,x,y)
    dx, dy = x-a, y-b
    Math::sqrt(dx*dx + dy*dy)    
  end
  
  def self.toBAMS(x); (((x)/360.0) * 256) end
  def self.toDEGS(b); (((b)/256.0) * 360) end


  def self.modNearestInt(a,b) a-b*(a.to_f/b).round end


  #double a1, a2     # "real" angles
  #int b1, b2, b3    # BAMS angles
  def self.smallest_angle_between(a1=0,a2=90)
    # puts "Angle (#{a1})(#{a2})=#{modNearestInt(a2-a1,360.0)}"
    return modNearestInt(a2-a1,360.0)
    
    b1 = toBAMS(a1)
    b2 = toBAMS(a2)

    # difference increases with increasing goal angle
    # difference decreases with increasing start angle
    b3 = b2 - b1
    # b3 &= 0xff
    b3 = b3.round & 0xff

    # puts "Start at #{a1} deg and go to #{a2} deg"
    # puts "BAMS are #{b1} and #{b2}"
    # puts "BAMS diff is #{b3}"
    # puts "--------BAMS line is #{b3 & 0x80}"

    turn = 0
    # check what would be the 'sign bit' of the difference
    # negative (msb set) means turn one way, positive the other
    if (b3 & 0x80) != 0
      # difference is negative; negate to recover the
      # DISTANCE to move, since the negative-ness just
      # indicates direction.

      # cheap 2's complement on an N-bit value:
      # invert, increment, trim
      b3 ^= -1       # XOR -1 inverts all the bits
      b3 += 1        # "add 1 to x" :P
      b3 &= 0xFF     # retain only N bits

      # difference is already positive, can just use it
      # puts "Turn right #{toDEGS(b3)} degrees"
      # puts "Turn right #{b3} counts"
      turn = -toDEGS(b3)
    else
      # puts "Turn left #{toDEGS(b3)} degrees"
      # puts "Turn left #{b3} counts"
      turn = toDEGS(b3)
    end
    # puts
    return turn
  end
  
  # [a,b] is current position, [x,y] is goal position
  def self.plot_course(heading,a,b,x,y)
      goal_heading = RobotFunctions::angle_between(a,b,x,y)
      goal_distance = RobotFunctions::distance_between(a,b,x,y)
      angle_delta = RobotFunctions::smallest_angle_between(heading,goal_heading)
      # puts "At [#{a},#{b}] going to [#{x},#{y}] Heading(#{goal_heading}),Dist(#{goal_distance}) = #{angle_delta} Turn"
      [angle_delta,goal_distance]
  end
  
  #------------------
  def near_wall(x,y,buffer)
    # buffer = size * 6
    return true if x < buffer
    return true if x > battlefield_width - buffer
    return true if y < buffer
    return true if y > battlefield_height - buffer
  end
  #------------------
end
# RobotFunctions::smallest_angle_between(0,1)
# RobotFunctions::smallest_angle_between(0,-1)
# RobotFunctions::smallest_angle_between(0,359)
# RobotFunctions::smallest_angle_between(0,179)
# RobotFunctions::smallest_angle_between(0,180)
# RobotFunctions::smallest_angle_between(0,181)
# RobotFunctions::smallest_angle_between(90,270)
# RobotFunctions::smallest_angle_between(89,270)
# RobotFunctions::smallest_angle_between(90,360)
# RobotFunctions::smallest_angle_between(90,380)

# a = [0,0]; b= [10,10]; puts "#{a.inspect} to #{b.inspect} = #{RobotFunctions::angle_between(a[0],a[1],b[0],b[1])}"
# a = [0,0]; b= [0,10]; puts "#{a.inspect} to #{b.inspect} = distance #{RobotFunctions::distance_between(a[0],a[1],b[0],b[1])}"
# a = [0,0]; b= [0,10]; puts "#{a.inspect} to #{b.inspect} = #{RobotFunctions::angle_between(a[0],a[1],b[0],b[1])}"
# a = [0,0]; b= [10,0]; puts "#{a.inspect} to #{b.inspect} = #{RobotFunctions::angle_between(a[0],a[1],b[0],b[1])}"
# a = [0,0]; b= [-10,0]; puts "#{a.inspect} to #{b.inspect} = #{RobotFunctions::angle_between(a[0],a[1],b[0],b[1])}"
# a = [0,0]; b= [0,-10]; puts "#{a.inspect} to #{b.inspect} = #{RobotFunctions::angle_between(a[0],a[1],b[0],b[1])}"
# a = [0,0]; b= [-4,-1]; puts "#{a.inspect} to #{b.inspect} = #{RobotFunctions::angle_between(a[0],a[1],b[0],b[1])}"
