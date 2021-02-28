class V1Controller < ApplicationController
  def health
    #get values using SQL
    sql = "SELECT date_trunc('second', current_timestamp - pg_postmaster_start_time()) as uptime;"
    uptime = ActiveRecord::Base.connection.execute(sql).getvalue(0, 0)

    #prepare uptime for parsing
    value = uptime.split("P", 2)[1].split("T", 2).join
    value_arr = value.split(/(?<=[\D])/)

    days = hours = minutes = seconds = "0"

    value_arr.each { |x|
      case x[-1]
      when "D"
        days = x[0..-2]
      when "H"
        hours = x[0..-2]
      when "M"
        minutes = x[0..-2]
      when "S"
        seconds = x[0..-2]
      end
    }
    time = days + " days " + hours + ":" + minutes + ":" + seconds

    #parse into JSON
    require "json"
    json_format = { :pgsql => { :uptime => time } }.to_json

    #return
    @health_info = json_format
    render json: @health_info
  end
end
