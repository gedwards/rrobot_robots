begin
  # In case you use Gosu via RubyGems.
  require 'rubygems'
rescue LoadError
  # In case you don't.
end
require 'gosu'

GosuRobot = Struct.new(:body, :gun, :radar, :speech, :info, :status)

module ZOrder
  Background, Robot, Explosions, UI = *0..3
end

class GosuRobot
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
  attr_accessor :speed_multiplier, :on_game_over_handlers
  attr_accessor :boom, :robots, :bullets, :explosions, :colors
  attr_accessor :default_skin_prefix
  
  def initialize(battlefield, xres, yres)
    super(xres,yres, true, 16)
    self.caption = 'RRobots - GOSU POWERED'
    @font = Gosu::Font.new(self, Gosu::default_font_name, 50)
    @background_image = Gosu::Image.new(self, "images/space.png", true)
    @battlefield = battlefield
    @xres, @yres = xres, yres
    @on_game_over_handlers = []
    init_window
    init_simulation
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
    if button_down? Gosu::Button::KbEscape
      self.close
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
          @font.draw("GAME OVER #{whohaswon}", xres/2-50, yres/2-10, ZOrder::UI, 1.0, 1.0, 0xffffff00)
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
        Gosu::Font.new(self, Gosu::default_font_name, 12),
        Gosu::Font.new(self, Gosu::default_font_name, 12),
        Gosu::Font.new(self, Gosu::default_font_name, 12)
      )
      
      @robots[ai].body.draw_rot(ai.x / 2, ai.y / 2, ZOrder::Robot, (-(ai.heading-90)) % 360)
      @robots[ai].gun.draw_rot(ai.x / 2, ai.y / 2, ZOrder::Robot, (-(ai.gun_heading-90)) % 360)
      @robots[ai].radar.draw_rot(ai.x / 2, ai.y / 2, ZOrder::Robot, (-(ai.radar_heading-90)) % 360)
      @robots[ai].speech.draw(ai.speech.to_s, ai.x / 2 - 40 , ai.y / 2 - 40, ZOrder::UI, 1.0, 1.0, 0xffffff00)
      @robots[ai].info.draw("#{ai.name}\n#{'|' * (ai.energy / 5)}", 
                            ai.x / 2 - 50, ai.y / 2 + 30, ZOrder::UI, 1.0, 1.0, 0xffffff00)
      @robots[ai].status.draw("#{ai.name.ljust(20)} #{'%.1f' % ai.energy}", 
                              ai.x / 2 - 50, ai.y / 2 + 30, ZOrder::UI, 1.0, 1.0, 0xffffff00)
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

