require 'robot'
require_relative '../functions'

class Sail
  include Robot
  include RobotFunctions

  def tick events
    if time == 0
      $bbox = []
      @radar_sweep=[radar_heading,radar_heading] 
      @map = []
      @r_direction = 1
      @r_step = 30
      @r_cnt = 100
    end

    #--- look ---------

    @radar_sweep = [@radar_sweep[1],radar_heading]

    distance = events['robot_scanned'][0][0].to_i rescue 100
    radar_box = compute_radar_box(x,y,distance,@radar_sweep)
    radar_box[:color] = see_target? ? 0xFFff0000 : 0xFF00ff00
    radar_box[:rect] = scale(radar_box[:rect])
    radar_box[:z] = 0

    #--- think --------
    if see_target?
      @r_step = ((@r_step.to_f / 2).ceil).to_i
      if @r_step <= 4
        @r_step = 4
        @map.shift if @map.size > 6

        t = radar_box.dup
        t[:color] = 0xFF0000ff
        t[:z] = 10
        @map << t
        @r_step = 60
      else
        @r_direction *= -1
      end
    else
      @r_step = 30
    end

    #--- react --------
    turn_radar(@r_step * @r_direction)

    $bbox = [ radar_box ].concat(@map)
  end
#------------------------------------------------
end

