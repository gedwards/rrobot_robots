module RobotFunctions
  DEG = Math:: PI / 180.0 
  def self.angle_between(a,b,x,y)
    heading = Math::atan2(b-y,x-a) / DEG % 360 # NOTE: using b-y instead of y-b because y increases DOWNWARD
  end         

  def self.distance_between(a,b,x,y)
    dx, dy = x-a, y-b
    Math::sqrt(dx*dx + dy*dy)    
  end
  
  def self.toBAMS(x); (((x)/360.0) * 256) end
  def self.toDEGS(b); (((b)/256.0) * 360) end

  #double a1, a2     # "real" angles
  #int b1, b2, b3    # BAMS angles
  def self.smallest_angle_between(a1=0,a2=90)
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
