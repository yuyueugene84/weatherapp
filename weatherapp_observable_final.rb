require 'observer'
require 'net/http'
require 'json'
require 'ostruct'
require 'date'
require 'pry'

module Observer

  def update(obj)
    raise NotImplementedError, 'Implement this method!'
  end
end

module DisplayElement
  def display
    raise NotImplementedError, 'Implement this method!'
  end
end

class WeatherData
  include Observable
  attr_accessor :temp, :humidity, :pressure, :high_temp, :low_temp, :forecast

  def set_measurements(temp=nil, humidity=nil, pressure=nil, high_temp=nil, low_temp=nil, forecast=nil)
    obj = get_yahoo_data # 去 yahoo API 取得資料，存入 obj 變數中

    changed # 如果這個物件的狀態跟上次呼叫 notify_observers 時有差別，就會迴傳 true

    self.temp     = ( temp != nil ) ? temp : obj.query.results.channel.item.condition.temp
    self.humidity = ( humidity != nil ) ? humidity  : obj.query.results.channel.atmosphere.humidity
    self.pressure = ( pressure != nil ) ? pressure  : obj.query.results.channel.atmosphere.pressure
    self.high_temp = (high_temp != nil) ? high_temp : obj.query.results.channel.item.forecast.high
    self.low_temp = (low_temp != nil) ?   low_temp  : obj.query.results.channel.item.forecast.low
    self.forecast = ( forecast != nil ) ? forecast  : obj.query.results.channel.item.forecast.text
    # 更新所有的狀態

    notify_observers(self)
    # measurements_changed()
  end

  def get_yahoo_data
    url = 'https://query.yahooapis.com/v1/public/yql?q=select%20item.forecast%2C%20item.condition%2C%20atmosphere%20%20%20from%20weather.forecast%20where%20woeid%20%3D%202306179%20and%20u%3D%22c%22%20limit%201&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys'
    uri = URI(url)
    response = Net::HTTP.get(uri)
    obj = JSON.parse(response, object_class: OpenStruct)
  end

end

class CurrentConditionsDisplay
  include Observer, DisplayElement
  attr_accessor :temp, :humidity, :pressure, :subject

  def initialize(weatherData)
    self.subject = weatherData
    self.subject.add_observer(self)
  end

  def update(obj)
    self.temp     = obj.temp
    self.humidity = obj.humidity
    self.pressure = obj.pressure

    display
  end

  def display
    puts "目前情況 : 溫度 = #{temp}度C, 濕度 = #{humidity}%, 壓力 = #{pressure}kPa"
  end
end

class StatisticsDisplay
  include Observer, DisplayElement
  attr_accessor :high_temp, :low_temp, :subject

  def initialize(weatherData)
    self.subject = weatherData
    self.subject.add_observer(self)
  end

  def update(obj)
    self.high_temp = obj.high_temp
    self.low_temp = obj.low_temp

    display
  end

  def display
    puts "天氣統計 : 最高溫度 = #{high_temp}度C, 最低溫度 = #{low_temp}%"
  end
end

class ForecastDisplay
  include Observer, DisplayElement
  attr_accessor :forecast, :subject

  def initialize(weatherData)
    self.subject = weatherData
    self.subject.add_observer(self)
  end

  def update(obj)
    self.forecast = obj.forecast

    display
  end

  def display
    puts "天氣預報 : #{forecast}"
  end
end

class WeatherStation
  def initialize
    puts 'WeatherStation Start'
    w = WeatherData.new
    CurrentConditionsDisplay.new(w)
    StatisticsDisplay.new(w)
    ForecastDisplay.new(w)

    w.set_measurements

    # now = Time.now
    # end_time = now + 30

    # begin 
    #   w.set_measurements rand(1..40), rand(1..100), rand(10000..20000), rand(20..40), rand(1..20), ['sunny', 'rain'].sample
    #   now += 1
    # end while now < end_time

    puts 'WeatherStation Ends'
  end

end

w = WeatherStation.new