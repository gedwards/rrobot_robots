require_relative '../robot'
# require 'gosu'
require_relative '../functions'

class DadBot
   include Robot
   
  def tick events
    if time == 0
      $bbox = []
      @radar_sweep=[radar_heading,radar_heading] 
      @scan_everything = true
      @slices_per_circle = 6
      @contacts = []
      
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
    end

    @radar_sweep = [@radar_sweep[1],radar_heading]

    check_for_enemy_seen
    
    radar_fast_sweep if @scan_everything
    
    # Let's MOVE!!!!
    move_to_goal
    # turn 2
    
    # turn_my_radar
    # Let's point the gun
    turn_my_gun
    # Let's shoot something!
    
    shoot_something
    # puts "heat!: #{gun_heat} radar#{@radar_sweep.inspect}"
  end
#---------------------------------------------------

  def turn_my_radar
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
      turn_angle, goal_distance = RobotFunctions::plot_course(heading, x,y,goal[:x],goal[:y])
      if goal_distance < 50
        completed = @goal[:position].shift
        @goal[:position] << completed if completed[:recyle]
      end
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
  
  def scale_x(val); (((val*1.0)/battlefield_width) * 800).to_i end
  def scale_y(val); (((val*1.0)/battlefield_height) * 800).to_i end

	# Gets the location of an object given the heading and distance
	def location(x, y, theta, distance)
	  [x + distance * Math.cos(theta), y - distance * Math.sin(theta)]
	end

  def compute_radar_box(x,y,distance,sweep)
    p1 = location(x,y,sweep[0].to_rad,distance)
    p2 = location(x,y,sweep[1].to_rad,distance)
    xx = [p1[0],p2[0]] # group the x's together so that we can do min/max on the array
    yy = [p1[1],p2[1]] # group the y's together so that we can do min/max on the array
    {
      :rect=>[xx.min.to_i,yy.min.to_i,xx.max.to_i,yy.max.to_i],# the enclosing rectangle
      :color =>0xFFFFffff, # color
      :age => 1, # age = 1
      :distance => distance
    }
  end
  def enemy_list_account_for_movement(list)
    return nil if list.nil?
    list.map{|elem| e = elem[:rect]; elem[:rect]=[e[0]-8,e[1]-8,e[2]+8,e[3]+8]; elem[:age]=elem[:age]+1; elem[:color]=0xFFFFffff; elem} # increment each entries age
  end
  def overlap(a,b)
    c = [ [a[0],b[0]].max, [a[1],b[1]].max, [a[2],b[2]].min, [a[3],b[3]].min] 
    return nil if c[0]>c[2] || c[1]>c[3]
    c
  end
  def check_for_enemy_seen
    @contacts = enemy_list_account_for_movement(@contacts)
    @contacts.delete_if{|e| e[:age] > @slices_per_circle}
    # $bbox = @contacts.compact.map{|elem| e=elem[:rect]; {:rect=>[scale_x(e[0]),scale_y(e[1]),scale_x(e[2]),scale_y(e[3])], :color=>elem[:color]} }
    return if events['robot_scanned'].empty? 
    # --- enemy seen
    distance = events['robot_scanned'][0][0].to_i
    radar_box = compute_radar_box(x,y,distance,@radar_sweep)
    overlap_exists = false
    @contacts.map!{|elem| 
      new_rect = overlap(elem[:rect],radar_box[:rect])
      unless new_rect.nil?
        overlap_exists = true
        # puts "overlap: #{elem.inspect} #{radar_box.inspect} = #{new_rect.inspect}"
        elem[:rect] = new_rect
        elem[:color] = 0xFFFF0000
        elem[:age] = 1 # age: this is the first modification
      end
      elem
    } 
    @contacts << radar_box unless overlap_exists
    # $bbox = @contacts.compact.map{|elem| e=elem[:rect]; {:rect=>[scale_x(e[0]),scale_y(e[1]),scale_x(e[2]),scale_y(e[3])], :color=>elem[:color]} }
    
    # puts "self [#{x.round},#{y.round}] --> #{distance.round} #{radar_box.inspect}"
  end
  
  def radar_fast_sweep
    turn_radar_by = 27
    @slices_per_circle = (360.0/turn_radar_by + 0.5).round + 2
    turn_radar turn_radar_by
    return
    @radar_turns_remaining ||=7 # need to do 6 * 60 to get around, plus 1 extra to handle possible tank rotations
    (turn_radar 60; @radar_turns_remaining -= 1) if @radar_turns_remaining > 0
    
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
  
#---------------------------------------------------
end
