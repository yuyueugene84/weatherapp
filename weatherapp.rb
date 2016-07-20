require 'net/http'
require 'json'
require 'ostruct'

module Subject
  def initialize
    @observers = []
  end

  def register_observer(observer)
    @observers << observer
  end

  def remove_observer(observer)
    @observers.delete observer
  end

  def notify_observers
    @observers.each do |observer|
      observer.update(self.temp, self.humidity, self.pressure)
    end
  end
end

module Observer
  def update(temp, humidity, pressure)
    raise NotImplementedError, 'Implement this method!'
  end
end

module DisplayElement
  def display
    raise NotImplementedError, 'Implement this method!'
  end
end

class WeatherData
  include Subject
  attr_accessor :temp, :humidity, :pressure

  def measurements_changed
    notify_observers
  end

  def set_measurements(temp, humidity, pressure)
    self.temp     = temp
    self.humidity = humidity
    self.pressure = pressure
    measurements_changed()
  end
end

class CurrentConditionsDisplay
  include Observer, DisplayElement
  attr_accessor :temp, :humidity, :pressure, :subject

  def initialize(weatherData)
    self.subject = weatherData
    self.subject.register_observer(self)
  end

  def update(temp, humidity, pressure)
    self.temp     = temp
    self.humidity = humidity
    self.pressure = pressure
    display
  end

  def display
    puts "目前情況 : 溫度 = #{temp}度C, 濕度 = #{humidity}%, 壓力 = #{pressure}"
  end
end

class WeatherStation
  def initialize
    puts 'WeatherStation Start'
    w = WeatherData.new
    c = CurrentConditionsDisplay.new(w)

    w.set_measurements 80, 65, 30.4
    w.set_measurements 82, 70, 29.2
    w.set_measurements 78, 90, 29.2
  end
end

w = WeatherStation.new