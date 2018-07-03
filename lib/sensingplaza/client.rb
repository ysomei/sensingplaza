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
    
    # sensorkey - String  ex) "12abe9de" or ["12abe9de", "433bedd2", ...]
    # datetime - String  ex) "2018-07-04 12:00:00"
    def get_data(sensorkey, datetime)
      return nil if @mailaddress.nil?
      unless datetime.match(/^\d{4}\-\d{2}\-\d{2} \d{2}\:\d{2}:\d{2}$/)
        return nil
      end

      skeys = Array.new
      skeys.push(sensorkey) if sensorkey.instance_of?(String)
      skeys = sensorkey if sensorkey.instance_of?(Array)
      return nil if skeys.empty?
      
      values = Hash.new
      endpoint = "/api/download"
      req = { "mailaddress" => @mailaddress,
              "datetime" => datetime,
              "data" => skeys
            }
      jsonstr = @webreq.post(req, endpoint)
      response = JSON.parse(jsonstr)
      response["data"].each do |skey, val|
        values[skey] = val
      end
      return values
    end
        
  end


end
