# -*- coding: utf-8 -*-

module Sensingplaza

  SENSINGPLAZA_URL = "https://iot.blueomega.jp/sensingplaza2"
  
  class Client
    attr_accessor :mailaddress

    # mailaddress - String  ex) hoge@mail.com
    # logger - Logger
    def initialize(mailaddress, logger = nil)
      @sensingplaza_url = SENSINGPLAZA_URL
      @mailaddress = mailaddress
      @logger = logger

      @webreq = WebRequest.new(@sensingplaza_url, @logger)
    end

    def sensingplaza_url=(val)
      @sensingplaza_url = val
      @webreq.url = val
    end
    
    # sensorkey - String(s)  ex) "12abe9de" or ["12abe9de", "433bedd2", ...]
    # datetime - String  ex) "2018-07-04 12:00:00"
    def get_data(sensorkey, datetime)
      return nil if @mailaddress.nil?
      unless datetime.match(/^\d{4}\-\d{2}\-\d{2} \d{2}\:\d{2}:\d{2}$/)
        return nil
      end

      skeys = Array.new
      skeys.push(sensorkey) if sensorkey.instance_of?(String)
      if sensorkey.instance_of?(Array)
        if (sensorkey.collect{|c| c.instance_of?(String)} - [true]).empty?
          skeys = sensorkey
        end
      end
      return nil if skeys.empty?
      
      result = Hash.new
      endpoint = "/api/download"
      req = { "mailaddress" => @mailaddress,
              "datetime" => datetime,
              "data" => skeys
            }
      jsonstr = @webreq.post(req, endpoint)
      response = JSON.parse(jsonstr)
      response["data"].each do |skey, val|
        result[skey] = val
      end
      return result
    end

    # sensorkey - String(s)  ex) "" or ["", "", ...]
    # datetime - String  ex) "2018-07-04 12:34:00"
    # data - value(s)  ex) 12.45 or [12.45, "on", ...] 
    def push_data(sensorkey, datetime, data)
      return nil if @mailaddress.nil?
      unless datetime.match(/^\d{4}\-\d{2}\-\d{2} \d{2}\:\d{2}:\d{2}$/)
        return nil
      end

      skeys = Array.new
      skeys.push(sensorkey) if sensorkey.instance_of?(String)
      if sensorkey.instance_of?(Array)
        if (sensorkey.collect{|c| c.instance_of?(String)} - [true]).empty?
          skeys = sensorkey
        end
      end
      return nil if skeys.empty?

      vals = Array.new
      if data.instance_of?(Array)
        vals = data
      else
        vals.push(data)
      end
      return nil if vals.empty?

      sensvals = Hash.new
      skeys.each_with_index do |skey, i|
        sensvals[skey] = vals[i]
      end

      result = Hash.new
      endpoint = "/api/upload"
      req = { "mailaddress" => @mailaddress,
              "datetime" => datetime,
              "data" => sensvals
            }
      jsonstr = @webreq.post(req, endpoint)
      response = JSON.parse(jsonstr)
      response["data"].each do |skey, val|
        result[skey] = val
      end
      return result
    end
    
  end


end
