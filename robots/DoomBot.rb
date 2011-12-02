require 'robot'

class DoomBot
   include Robot

  def tick events
    # turn_radar 1 if time == 0
    # turn_radar 1
    @radar_direction ||=5
    turn_radar @radar_direction
    @radar_direction *= -1
    # say "#{events.inspect}" if see_target

    #turn_gun 30 if time < 3
    accelerate 1
    turn 2 if near_wall
    # (stop; turn 0) if enemy_seen_recently(50)
    
    # puts "#{events['robot_scanned'][0].inspect} #{radar_heading.inspect}" unless events['robot_scanned'].empty?
    if enemy_seen_recently(50)
      if gun_heat == 0
        # puts "-----------------BANG!" 
        case @last_enemy_dist
        when 0...100
          fire 3; #puts "2: #{gun_heat}"
        when 100...500
          fire 2; #puts "3: #{gun_heat}"
        when 500...1000
          fire 0.5; #puts "4: #{gun_heat}"
        else fire 0.2; #puts "5: #{gun_heat}"
        end
      end
    else
      turn_gun 10
      fire 0.1
    end
    # if events['robot_scanned'][0].nil? || events['robot_scanned'][0].empty?
    #   fire 0.1
    # else
    #   puts "thing: #{events['robot_scanned'][0][0].to_i} #{events['robot_scanned'][0][0].to_i.class}"
    #   dist = events['robot_scanned'][0][0].to_i
    #   case dist
    #   when 0...100: fire 3; puts "2: #{gun_heat}"
    #   when 100...500: fire 2; puts "3: #{gun_heat}"
    #   when 500...1000: fire 2; puts "4: #{gun_heat}"
    #   else fire 0.2; puts "5: #{gun_heat}"
    #   end
    # end
    # fire 3 unless events['robot_scanned'].empty? 
  end
#------------------------------------------------
  def enemy_seen_recently(since = 100)
    enemy_seen
    @last_enemy_seen ||= 0
    (time - @last_enemy_seen) < since
  end
  
  def enemy_seen
    was_seen = _enemy_seen
    @last_enemy_dist ||= 0
    if was_seen
      @last_enemy_seen = time 
      @last_enemy_dist = events['robot_scanned'][0][0].to_i
    end
    was_seen
  end
  
  def _enemy_seen
    !events['robot_scanned'].empty? 
  end
  
  def distance(point)  
    Math.hypot(point.x - x, point.y - y)  
  end  

  def near_wall
    stay_away = size * 6
    return true if x < stay_away
    return true if x > battlefield_width - stay_away
    return true if y < stay_away
    return true if y > battlefield_height - stay_away
  end
  def see_target
    !events['robot_scanned'].empty?     
  end
end
