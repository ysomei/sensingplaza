# -*- coding: utf-8 -*-

module Sensingplaza

  SENSINGPLAZA_URL = "https://iot.blueomega.jp/sensingplaza2"
  
  class Client
    attr_accessor :mailaddress

    # mailaddress - String  ex) hoge@mail.com
    # logger - Logger
    def initialize(mailaddress = nil, logger = nil)
      @sensingplaza_url = SENSINGPLAZA_URL
      @mailaddress = mailaddress
      @logger = logger

      @webreq = WebRequest.new(@sensingplaza_url, @logger)
    end

    def sensingplaza_url=(val)
      @sensingplaza_url = val
      @webreq.url = val
    end
    def logger=(val)
      @logger = val
      @webreq.logger = val
    end

    # +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
    # -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    # private methods
    private

    def datetime_format?(datetime)
      return datetime.match(/^\d{4}\-\d{2}\-\d{2} \d{2}\:\d{2}:\d{2}$/)
    end
    def skey_forming(sensorkey)
      skeys = Array.new
      skeys.push(sensorkey) if sensorkey.instance_of?(String)
      if sensorkey.instance_of?(Array)
        if (sensorkey.collect{|c| c.instance_of?(String)} - [true]).empty?
          skeys = sensorkey
        end
      end
      return skeys
    end
    def data_forming(data)
      datas = Array.new
      if data.instance_of?(Array)
        datas = data
      else
        datas.push(data)
      end
      return datas
    end
    
    def download(skeys, datetime)
      endpoint = "/api/download"
      req = { "mailaddress" => @mailaddress,
              "datetime" => datetime,
              "data" => skeys
            }
      jsonstr = @webreq.post(req, endpoint)
      response = JSON.parse(jsonstr)
      return response["data"]
    end
    def upload(skeys, datetime, datas)
      sensvals = Hash.new
      skeys.each_with_index do |skey, i|
        sensvals[skey] = datas[i]
      end

      endpoint = "/api/upload"
      req = { "mailaddress" => @mailaddress,
              "datetime" => datetime,
              "data" => sensvals
            }
      jsonstr = @webreq.post(req, endpoint)
      response = JSON.parse(jsonstr)
      return response["data"]
    end

    def bulkdown(skeys, sdatetime, edatetime)
      result = Hash.new
      endpoint = "/api/bulkdown"
      req = { "mailaddress" => @mailaddress,
              "start_datetime" => sdatetime,
              "end_datetime" => edatetime,
              "data" => skeys
            }
      jsonstr = @webreq.post(req, endpoint)
      response = JSON.parse(jsonstr)
      return response["sheaf"]
    end

    # img_header -> first 4bytes of data :p 
    def check_image_format(img_header)
      hstr = img_header.unpack("H*").first
      mime = { "unk" => "application/octet-stream",
               "jpg" => "image/jpeg",
               "png" => "image/png",
               "gif" => "image/gif",
               "bmp" => "image/x-bmp",
               "pic" => "image/pict",
               "tif" => "image/tiff"               
             }
      
      result = "unk"
      result = "jpg" if hstr[0, 4] == "ffd8"
      result = "png" if hstr == "89504e47"
      result = "gif" if hstr == "47494638"
      resutl = "bmp" if hstr[0, 4] == "424d"
      result = "pic" if hstr[0, 6] == "504943"
      result = "tif" if hstr[0, 4] == "4949" || hstr[0, 4] == "4d4d"
      return result, mime[result]
    end
    
    public
    # -+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    # +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
    
    # ------------------------------------------------------------------------
    # sensorkey - String(s)  ex) "12abe9de" or ["12abe9de", "433bedd2", ...]
    # datetime - String  ex) "2018-07-04 12:00:00"
    def get_data(sensorkey, datetime)
      return nil if @mailaddress.nil?
      datetime = Time.now.to_s[0, 19] if datetime.nil?
      return nil unless datetime_format?(datetime)

      skeys = skey_forming(sensorkey)
      return nil if skeys.empty?
            
      result = download(skeys, datetime)
      return result
    end

    # ------------------------------------------------------------------------
    # sensorkey - String(s)
    # sdatetme, edatetime - String  ex) "2018-07-04 12:12:00"
    #    getting data from sdatetime to edatetime
    def get_data_period(sensorkey, sdatetime, edatetime)
      return nil if @mailaddress.nil?
      return nil unless datetime_format?(sdatetime)
      return nil unless datetime_format?(edatetime)

      skeys = skey_forming(sensorkey)
      return nil if skeys.empty?

      result = bulkdown(skeys, sdatetime, edatetime)
      return result      
    end

    # ------------------------------------------------------------------------
    # sensorkey - String(s)  ex) "" or ["", "", ...]
    # data - value(s)  ex) 12.45 or [12.45, "on", ...]
    # datetime - String or Nil  ex) "2018-07-04 12:34:00", nil -> now time    
    def push_data(sensorkey, data, datetime = nil)
      return nil if @mailaddress.nil?
      datetime = Time.now.to_s[0, 19] if datetime.nil?
      return nil unless datetime_format?(datetime)

      skeys = skey_forming(sensorkey)
      return nil if skeys.empty?
      datas = data_forming(data)
      return nil if datas.empty?
      
      result = upload(skeys, datetime, datas)
      return result
    end

    # ------------------------------------------------------------------------
    # sensorkey - String(s)  ex) "12abe9de" or ["12abe9de", "433bedd2", ...]
    # datetime - String  ex) "2018-05-22 12:34:00"
    def get_image(sensorkey, datetime)
      return nil if @mailaddress.nil?
      return nil unless datetime_format?(datetime)
      skeys = skey_forming(sensorkey)
      return nil if skeys.empty?

      result = Hash.new
      datas = download(skeys, datetime)
      datas.each do |k, v|
        unless v.nil?
          imgdat = Base64.strict_decode64(v)
          imgtype, mimetype = check_image_format(imgdat[0, 4]) # first 4bytes
          fname = "#{datetime.gsub(/[\-\s\:]/, "")}.#{imgtype}"
          result[k] = { "blob" => imgdat,
                        "filename" => fname, "content-type" => mimetype }
        else
          result[k] = nil
        end
      end
      return result      
    end

    
  end
end
