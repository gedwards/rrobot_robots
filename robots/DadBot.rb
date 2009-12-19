require 'robot'
# require 'gosu'
require 'functions'

class DadBot
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
    if enemy_seen_recently(100): say "WAITING"
    elsif enemy_seen: say "bye bye!"
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
      turn_angle, goal_distance = RobotFunctions::plot_course(heading, x,y,goal[:x],goal[:y])
      if goal_distance < 50
        @slow = time
        completed = @goal[:position].shift
        @goal[:position] << completed if completed[:recyle]
      end
      sleep 1 if time - @slow < 20 && goal[2] && goal[2]==:slow
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
        {:action=>:go, :recyle=>true,:x=>200,:y=>1000,:debug=>:fast},{:action=>:go, :recyle=>true,:x=>200,:y=>500,:debug=>:fast},
        {:action=>:go, :recyle=>true,:x=>1000,:y=>500,:debug=>:fast},{:action=>:go, :recyle=>true,:x=>1000,:y=>200,:debug=>:fast},{:action=>:go, :recyle=>true,:x=>1000,:y=>1000,:debug=>:fast}, 
        {:action=>:go, :recyle=>true,:x=>50,:y=>50,:debug=>:fast},{:action=>:go, :recyle=>true,:x=>1000,:y=>50,:debug=>:fast},{:action=>:go, :recyle=>true,:x=>50,:y=>1000,:debug=>:fast},{:action=>:go, :recyle=>true,:x=>1000,:y=>1000,:debug=>:fast}
        ]
    # @goal[:position] = [[200,200],[500,200],[200,600],[1000,600],[1000,1000]]
    @goal[:gun] = [[0,0], [500,500]]
    @goal[:radar] = []
    @slow = 0
  end
#---------------------------------------------------
end