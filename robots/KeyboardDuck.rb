require 'robot'
require 'rubygems'
require 'gosu'

class KeyboardDuck
  include Robot

  def tick(events)
    unless (dist = events['robot_scanned']).empty?
      say 'ENEMY SPOTTED ' + (dist.first.first / 2).to_i.to_s + ' PIXELS AWAY!'
    end
    
    unless events['got_hit'].empty?
      say 'OUCH!'
    end

    if events['button_pressed'].include?(Gosu::Button::KbNumpad1)
        turn_radar 4
    end
    if events['button_pressed'].include?(Gosu::Button::KbNumpad3)
        turn_radar -4
    end
    if events['button_pressed'].include?(Gosu::Button::KbNumpad0)
        fire 3
    end
    if events['button_pressed'].include?(Gosu::Button::KbNumpad8)
        accelerate 3
    end
    if events['button_pressed'].include?(Gosu::Button::KbNumpad5)
        accelerate -3
    end
    if events['button_pressed'].include?(Gosu::Button::KbNumpad4)
        turn 4
    end
    if events['button_pressed'].include?(Gosu::Button::KbNumpad6)
        turn -4
    end
    if events['button_pressed'].include?(Gosu::Button::KbNumpad7)
        turn_gun 4
    end
    if events['button_pressed'].include?(Gosu::Button::KbNumpad9)
        turn_gun -4
    end
  end
end
