require 'robot'
# require 'gosu'
require 'functions'

class DadDuck
   include Robot
   
  # def move_me
  #   turn 1 if heading != 90
  #   if time % 200 > 100
  #     accelerate 1
  #     # accelerate 1 if speed.abs <= 2
  #   else
  #     accelerate -1
  #     # accelerate -1 if speed.abs <= 2
  #   end
  #   # say "#{speed} #{speed.abs}"
  # end

  def turn_my_radar
    # turn_radar 1
    if enemy_seen_recently(100)
      say "WAITING"
    elsif enemy_seen
      say "bye bye!"
    else say "looking"
    end
  end

  def turn_my_gun
    turn_gun -2 unless enemy_seen_recently(100)
  end
  
  def shoot_something
    fire 0.1
    # unless events['robot_scanned'].empty? 
  end
  
  def move_to_goal
    (stop; return if @goal[:position].empty?)
    goal = @goal[:position][0]
    turn_angle = 0

    if goal[:action]== :go
      gosu_distance_to_goal = Gosu::distance(@x,@y,goal[:x],goal[:y])
      gosu_angle_to_goal = Gosu::angle(@x,@y,goal[:x],goal[:y])
      if gosu_angle_to_goal.round > 180
        gosu_angle_to_goal = (360-gosu_angle_to_goal)*-1
      elsif gosu_angle_to_goal.round <= -180
        gosu_angle_to_goal = (360+gosu_angle_to_goal)
      # else
      #   gosu_angle_to_goal = gosu_angle_to_goal
      end

      gosu_heading = (180-heading-90)
      if gosu_heading > 180
        gosu_heading = (360-gosu_heading)*-1
      elsif gosu_heading <= -180
        gosu_heading = (360+gosu_heading)
      # else
      #   gosu_heading = gosu_heading
      end
      # gosu_heading = ((gosu_heading = (180-heading-90)) > 180 ? (360-gosu_heading)*-1 : gosu_heading) # reverse the direction of rotation, rotate it 90 degrees, and anything counterclockwise to 0 should be a negative number
      # heading = 91; ((gosu_heading = (180-heading-90) % 360) > 180 ? (360-gosu_heading)*-1 : gosu_heading)
      # heading = 269; ((gosu_heading = (180-heading-90) % 360) > 180 ? (360-gosu_heading)*-1 : gosu_heading)
      # heading = 0; ((gosu_heading = (180-heading-90) % 360) > 180 ? (360-gosu_heading)*-1 : gosu_heading)
      # heading = 1; ((gosu_heading = (180-heading-90) % 360) > 180 ? (360-gosu_heading)*-1 : gosu_heading)
      # heading = 360; ((gosu_heading = (180-heading-90) % 360) > 180 ? (360-gosu_heading)*-1 : gosu_heading)
      # heading = 359; ((gosu_heading = (180-heading-90) % 360) > 180 ? (360-gosu_heading)*-1 : gosu_heading)
      # heading = 90; ((gosu_heading = (180-heading-90) % 360) > 180 ? (360-gosu_heading)*-1 : gosu_heading)
      # heading = 270; ((gosu_heading = (180-heading-90) % 360) > 180 ? (360-gosu_heading)*-1 : gosu_heading)
      # heading = 271; ((gosu_heading = (180-heading-90) % 360) > 180 ? (360-gosu_heading)*-1 : gosu_heading)
      # heading = 180; ((gosu_heading = (180-heading-90) % 360) > 180 ? (360-gosu_heading)*-1 : gosu_heading)
      # heading = 181; ((gosu_heading = (180-heading-90) % 360) > 180 ? (360-gosu_heading)*-1 : gosu_heading)
      # heading = 179; ((gosu_heading = (180-heading-90) % 360) > 180 ? (360-gosu_heading)*-1 : gosu_heading)

      # angle_to_goal = (gosu_angle_to_goal * -1) + 90 # gosu treats up as 0, and increases clockwise, whereas rrobot uses regular cartesian and increases counter-clockwise
      gosu_angle_delta = gosu_heading-gosu_angle_to_goal
      # angle_delta = (gosu_angle_delta > 180 ? (360-gosu_angle_delta) : gosu_angle_delta)
      if gosu_angle_delta > 180
        angle_delta = (360-gosu_angle_delta)
      elsif gosu_angle_delta < -180
        angle_delta = (360+gosu_angle_delta)*-1
      else
        angle_delta = gosu_angle_delta
      end
      # angle_delta = angle_delta % 360
    
      # print "#{gosu_distance_to_goal}: #{goal.inspect} <-- (#{x.round},#{y.round}, #{heading.round.inspect})"
      # print " #{gosu_heading.round.inspect}/#{gosu_angle_to_goal.round.inspect}::#{gosu_angle_delta.round.inspect}"
      # puts " == #{angle_delta.round.inspect}"
    
      if angle_delta > 170
        @goal[:position].unshift({:action=>:turn, :direction=>10, :count=>9})
        angle_delta = 10
      elsif angle_delta < -170
        @goal[:position].unshift({:action=>:turn, :direction=>-10, :count=>9})
        angle_delta = -10
      end

      # if gosu_angle_delta.abs > 160
      #   
      #   gosu_angle_delta = Gosu::angle_diff(gosu_heading,gosu_angle_to_goal)
      #   if gosu_angle_delta > 180
      #     gosu_angle_delta = (360-gosu_angle_delta)*-1
      #   elsif gosu_angle_delta <= -180
      #     gosu_angle_delta = (360+gosu_angle_delta)
      #   # else
      #   #   gosu_heading = gosu_heading
      #   end
      # 
      # 
      #   puts "Alternate: old #{angle_delta}, new #{gosu_angle_delta}"
      #   angle_delta = gosu_angle_delta
      # end
    
      if gosu_distance_to_goal < 50
        # puts "nearing goal!! #{gosu_distance_to_goal}. Shifting to next goal"
        @slow = time
        @goal[:position].shift
      end
      sleep 1 if time - @slow < 20 && goal[2] && goal[2]==:slow


      turn_angle = angle_delta
    elsif goal[:action]==:turn
      if goal[:count] && goal[:count] > 0
        turn_angle = goal[:direction]
        goal[:count] -= 1
      end
      if goal[:count] && goal[:count] <= 0 
        @goal[:position].shift
      end
      # puts "turning #{goal[:direction]}, coount = #{goal[:count]} (heading= #{heading})"
    # elsif goal[:action]==:turn_to_heading
    #   turn_angle = goal[:direction]
    #   if ((heading >= goal[:heading] - goal[:fudge] && heading <= goal[:heading] + goal[:fudge]) ||
    #     (heading >= goal[:heading] + goal[:fudge] && heading <= goal[:heading] - goal[:fudge])
    #     )
    #     @goal[:position].shift
    #   else
    #     turn_angle = @goal[:direction]
    #   end
    #   puts "turning #{goal[:direction]} (heading= #{heading})"
    end
    # turn_angle = angle_delta > 10 ? 10 : angle_delta
    # turn_angle = turn_angle < -10 ? -10 : turn_angle
     
    turn(turn_angle) # reduce the delta, so turn into it
    accelerate 1
    # handle if we've reached the goal
  end
#---------------------------------------------------
  def tick events
    set_me_up if time == 0
    
    # Let's MOVE!!!!
    move_to_goal
    # turn 2
    
    turn_my_radar
    # Let's point the gun
    turn_my_gun
    # Let's shoot something!
    
    shoot_something
  end
#---------------------------------------------------
  def near_wall
    stay_away = size * 6
    return true if x < stay_away
    return true if x > battlefield_width - stay_away
    return true if y < stay_away
    return true if y > battlefield_height - stay_away
  end

  def enemy_seen_recently(since = 100)
    @last_enemy_seen ||= 0
    (time - @last_enemy_seen) < since
  end
  
  def enemy_seen
    was_seen = _enemy_seen
    @last_enemy_seen = time if was_seen
    was_seen
  end
  
  def _enemy_seen
    !events['robot_scanned'].empty? 
  end
  
  def set_me_up
    @my_last_gun = -1
    # @last_enemy_seen = 0
    @goal={}
    @goal[:position] = [
        # {:action=>:turn_to_heading, :direction=>10, :heading=>90, :fudge=>20},
        {:action=>:turn, :direction=>10, :count=>90},
        {:action=>:go,:x=>200,:y=>1000,:debug=>:fast},{:action=>:go,:x=>200,:y=>500,:debug=>:fast},
        {:action=>:go,:x=>1000,:y=>500,:debug=>:fast},{:action=>:go,:x=>1000,:y=>200,:debug=>:fast},{:action=>:go,:x=>1000,:y=>1000,:debug=>:fast}, 
        {:action=>:go,:x=>50,:y=>50,:debug=>:fast},{:action=>:go,:x=>1000,:y=>50,:debug=>:fast},{:action=>:go,:x=>50,:y=>1000,:debug=>:fast},{:action=>:go,:x=>1000,:y=>1000,:debug=>:fast}
        ]
    # @goal[:position] = [[200,200],[500,200],[200,600],[1000,600],[1000,1000]]
    @goal[:gun] = [[0,0], [500,500]]
    @goal[:radar] = []
    @slow = 0
  end
#---------------------------------------------------
end
