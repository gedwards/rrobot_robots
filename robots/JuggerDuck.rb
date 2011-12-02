require 'robot'

class JuggerDuck
   include Robot
   
  def move_me
    # turn 2 if near_wall
    # accelerate 1
    # return 
    turn 1 if heading != 90
    if time % 200 > 100
      accelerate 1
      # accelerate 1 if speed.abs <= 2
    else
      accelerate -1
      # accelerate -1 if speed.abs <= 2
    end
    # say "#{speed} #{speed.abs}"
    # stop if (time - @last_enemy_seen) < 100

  end

  def turn_my_radar
    # turn_radar 1
    if (time - @last_enemy_seen) < 100
      say "WAITING"
    elsif enemy_seen
      say "bye bye!"
    else
      say "looking"
    end
  end

  def turn_my_gun
    turn_gun -2 unless (time - @last_enemy_seen) < 100
  end
  
  def shoot_something
    fire 0.2
    # unless events['robot_scanned'].empty? 
  end
  
  def enemy_was_seen
    @last_enemy_seen = time if enemy_seen
  end
  
#---------------------------------------------------
  def tick events
    set_me_up if time == 0
    
    # Let's MOVE!!!!
    move_me
    # turn 2
    
    turn_my_radar
    # Let's point the gun
    turn_my_gun
    # Let's shoot something!
    
    shoot_something
  end
#---------------------------------------------------
  def enemy_seen
    @last_enemy_seen = time if _enemy_seen
    _enemy_seen
  end
  
  def _enemy_seen
    !events['robot_scanned'].empty? 
  end
  
  def set_me_up
    @my_last_gun = -1
    @last_enemy_seen = 0
  end

  def near_wall
    stay_away = size * 6
    return true if x < stay_away
    return true if x > battlefield_width - stay_away
    return true if y < stay_away
    return true if y > battlefield_height - stay_away
  end

#---------------------------------------------------
  

end