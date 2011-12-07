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
      @last_saw_target = 0
      @accel = 1
    end

    #--- look ---------
    distance = events['robot_scanned'][0][0].to_i rescue 100

    @radar_sweep = [@radar_sweep[1],radar_heading]
    avg_radar = avg_angle(*@radar_sweep)
    # err = angle_diff(*@radar_sweep) / 2
    err = 3
    avg_radar_box = compute_radar_box(x,y,distance,[avg_radar - err, avg_radar + err])
    avg_radar_box[:color] = 0xFF00ff00
    avg_radar_box[:z] = 200
    avg_radar_box[:rect] = scale(avg_radar_box[:rect])

    radar_box = compute_radar_box(x,y,distance,@radar_sweep)
    radar_box[:color] = see_target? ? 0xFFff0000 : 0xFF00ff00
    radar_box[:rect] = scale(radar_box[:rect])
    radar_box[:z] = 0

    if speed.abs == 8
      @accel *= -1
    end
    accelerate(@accel)

    #--- think --------
    @map.each{|r| r[:rect] = grow(scale_x(8), scale_y(8), *r[:rect])}

    if see_target?
      @last_saw_target = time
      @r_step = ((@r_step.to_f / 2).ceil).to_i
      if @r_step <= 2
        # tag location
        @map.shift if @map.size > 0

        t = radar_box.dup
        t[:color] = 0xFF0000ff
        t[:z] = 0
        @map << t

        # speed up again
        @r_step = 30
      else
        # @r_direction *= -1
      end
    else
      delta = time - @last_saw_target
      if delta == 1
        @r_direction *= -1
      elsif delta >= 5
        @r_step = 30
      end
    end

    #--- react --------
    turn_radar(@r_step * @r_direction)

    $bbox = [ radar_box ].concat(@map) << avg_radar_box
    # $bbox = [ ].concat(@map) << avg_radar_box
  end
#------------------------------------------------
end

