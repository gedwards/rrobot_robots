begin
  # In case you use Gosu via RubyGems.
  require 'rubygems'
rescue LoadError
  # In case you don't.
end
require 'gosu'
BIG_FONT = 'PortagoITC TT'
SMALL_FONT = 'Monaco'

GosuRobot = Struct.new(:body, :gun, :radar, :speech, :info, :status)

module ZOrder
  Background, Robot, Explosions, UI = *0..3
end

class LeaderBoard
  def initialize(window, battlefield, xres, yres, position = :right_top)
    @font_size = (xres / 45).to_i
    @position = position
    @battlefield = battlefield
    @font = Gosu::Font.new(window, BIG_FONT, @font_size)
    case position
    when :right_top
      @x_offset = xres-(@font_size * 9)
    when :left_top
      @x_offset = @font_size
    end
    @y_offset = @font_size * 2
  end

  def draw
    @battlefield.robots.sort_by{|a|-a.energy}.each_with_index do |r, i|
      y = @y_offset + (i * (@font_size * 1.5).to_i) - (@font_size * 1.5).to_i
      @font.draw("#{r.name}", @x_offset, y, 0xffffff00)
      @font.draw("#{r.energy.to_i}", @x_offset + (@font_size * 6), y, 0xffffff00)
    end
  end
end

class RRobotsGameWindow < Gosu::Window
  
  def usage
    puts "usage: rrobots.rb <FirstRobotClassName[.rb]> <SecondRobotClassName[.rb]> <...>"
    puts "\tthe names of the rb files have to match the class names of the robots"
    puts "\t(up to 8 robots)"
    puts "\te.g. 'ruby rrobots.rb SittingDuck NervousDuck'"
    exit
  end
  
  attr_reader :battlefield, :xres, :yres
  attr_accessor :on_game_over_handlers
  attr_accessor :boom, :robots, :bullets, :explosions
  
  def initialize(battlefield, xres, yres)
    super(xres,yres, true, 16)
    @leaderboard = LeaderBoard.new(self, battlefield, xres, yres)
    self.caption = 'RRobots - GOSU POWERED'
    @font = Gosu::Font.new(self, BIG_FONT, xres / 20)
    @small_font = Gosu::Font.new(self, SMALL_FONT, xres/100)
    @background_image = Gosu::Image.new(self, "images/space.png", true)
    @battlefield = battlefield
    @xres, @yres = xres, yres
    @on_game_over_handlers = []
    init_window
    init_simulation

    # for ultimate win
    @theme = Gosu::Song.new(self, 'music/song.mod')
    @theme.play
    @sound_boom = Gosu::Sample.new(self, 'sounds/sunexp.wav')
    @sound_gun = Gosu::Sample.new(self, 'sounds/shotborn.wav')
  end

  def draw
    @background_image.draw(0, 0, ZOrder::Background)
  end
  
  def on_game_over(&block)
    @on_game_over_handlers << block
  end
  
  def init_window
    @boom = (0..14).map do |i|
      Gosu::Image.new(self, "images/explosion#{i.to_s.rjust(2, '0')}.bmp")
    end
    @bullet_image = Gosu::Image.new(self, "images/bullet.png")
  end
  
  def init_simulation
    @robots, @bullets, @explosions = {}, {}, {}
  end


  def draw
    simulate
    draw_battlefield
    play_sounds
    @leaderboard.draw
    if button_down? Gosu::Button::KbEscape
      self.close
    end
  end
  
  def play_sounds
    @battlefield.robots.each do |ai|
      if !ai.robot.events['got_hit'].empty?
        @sound_boom.play(0.2)
      end

      if ai.actions[:fire] > 0 && ai.gun_heat <= 0
        @sound_gun.play([ai.actions[:fire], 1].min)
      end
    end
  end

  def draw_battlefield
    draw_robots
    draw_bullets
    draw_explosions
  end
  
  def simulate(ticks=1)
    @explosions.reject!{|e,tko| e.dead }
    @bullets.reject!{|b,tko| b.dead }
    @robots.reject! { |ai,tko| ai.dead}
    ticks.times do
      if @battlefield.game_over
        @on_game_over_handlers.each{|h| h.call(@battlefield) }
          winner = @robots.keys.first
          whohaswon = if winner.nil?
            "Draw!"
          elsif @battlefield.teams.all?{|k,t|t.size<2}
            "#{winner.name} won!"
          else
            "Team #{winner.team} won!"
          end
          text_color = winner ? winner.team : 7
          @font.draw_rel("#{whohaswon}", xres/2, yres/2, ZOrder::UI, 0.5, 0.5, 1, 1, 0xffffff00)
      end
      @battlefield.tick
    end
  end
  
  def draw_robots
    @battlefield.robots.each_with_index do |ai, i|
      next if ai.dead
      @robots[ai] ||= GosuRobot.new(
        Gosu::Image.new(self, 'images/red_body000.bmp'),
        Gosu::Image.new(self, 'images/red_turret000.bmp'),
        Gosu::Image.new(self, 'images/red_radar000.bmp'),
        @small_font,
        @small_font,
        @small_font
      )
      
      @robots[ai].body.draw_rot(ai.x / 2, ai.y / 2, ZOrder::Robot, (-(ai.heading-90)) % 360)
      @robots[ai].gun.draw_rot(ai.x / 2, ai.y / 2, ZOrder::Robot, (-(ai.gun_heading-90)) % 360)
      @robots[ai].radar.draw_rot(ai.x / 2, ai.y / 2, ZOrder::Robot, (-(ai.radar_heading-90)) % 360)
      if @talkative
        @robots[ai].info.draw("#{ai.name}\n#{'|' * (ai.energy / 5)}", 
                              ai.x / 2 - 50, ai.y / 2 + 30, ZOrder::UI, 1.0, 1.0, 0xffffff00)
        @robots[ai].status.draw("#{ai.name.ljust(20)} #{'%.1f' % ai.energy}", 
                                ai.x / 2 - 50, ai.y / 2 + 30, ZOrder::UI, 1.0, 1.0, 0xffffff00)
      else
        @robots[ai].speech.draw_rel(ai.speech.to_s, ai.x / 2, ai.y / 2 - 40, ZOrder::UI, 0.5, 0.5, 1, 1, 0xffffff00)
        @robots[ai].info.draw_rel("#{ai.name}", ai.x / 2, ai.y / 2 + 30, ZOrder::UI, 0.5, 0.5, 1, 1, 0xffffff00)
      end
    end
  end

  def draw_bullets
    @battlefield.bullets.each do |bullet|
      @bullets[bullet] ||= @bullet_image
      @bullets[bullet].draw(bullet.x / 2, bullet.y / 2, ZOrder::Explosions)
    end
  end

  def draw_explosions
    @battlefield.explosions.each do |explosion|
      @explosions[explosion] = boom[explosion.t % 14]
      @explosions[explosion].draw_rot(explosion.x / 2, explosion.y / 2, ZOrder::Explosions, 0)
    end
  end
end

