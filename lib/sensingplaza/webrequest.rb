# -*- coding: utf-8 -*-
require "net/http"
require "openssl"
require "uri"
require "cgi"

module Sensingplaza
  class WebRequest
    attr_accessor :user_id, :user_password, :url, :logger

    # requesthost - String  ex) "http://hoge.com"
    # logger - Logger
    def initialize(requesthost, logger = nil)
      @url = requesthost
      @url = requesthost[0, requesthost.length - 1] if requesthost[-1] == "/"
      @logger = logger

      @user_id = nil
      @user_password = nil
    end
  
    # --------------------------------------------------------------------------
    
    # postdata - Hash  ex) { 1 => 10.2, 2 => 12, 3 => "hoge" ... }
    # endpoint - String  ex) "/setvalues"
    # htmlret - Boolean -> false: return json string, true: html response
    def post(postdata, endpoint, htmlret = false)
      endpoint = "/ " + endpoint if endpoint[0] != "/"
      reqaddr = @url + endpoint
      uri = URI.parse(reqaddr)
      response = nil
      begin
        if reqaddr =~ /^https/
          https = Net::HTTP.new(uri.host, 443)
          https.use_ssl = true
          https.verify_mode = OpenSSL::SSL::VERIFY_NONE
          https.start{|h|
            request = Net::HTTP::Post.new(uri.path)
            request.basic_auth(@user_id, @user_password) unless @user_id.nil?
            request.body = postdata.to_json
            response = h.request(request)
          }
        else
          Net::HTTP.start(uri.host, uri.port){|http|
            request = Net::HTTP::Post.new(uri.path)
            request.basic_auth(@user_id, @user_password) unless @user_id.nil?
            request.body = postdata.to_json
            response = http.request(request)
          }
        end
        jsondata = response.body.strip
        errflg = false
        errflg = true if htmlret == false && jsondata =~ /^<html>/
        if errflg
          raise WebRequestError.new(jsondata.force_encoding("utf-8"))
        end      
      rescue
        unless @logger.nil?
          @logger.error("WebRequestError: can not send data.")
          @logger.error("#{$!}")
        else
          puts "WebRequestError: can not send data."
          puts "#{$!}"
        end
        jsondata = nil
      end
      return jsondata, response.code.to_i if htmlret
      return jsondata
    end
    
    # getdata - Hash  ex) { 1 => 10.2, 2 => 12, 3 => "hoge" ... }
    # endpoint - String  ex) "/setvalues"
    # htmlret - Boolean -> false: return json string, true: html response
    # headers - Hash -> header values
    def get(getdata, endpoint, htmlret = false, headers = {})
      endpoint = "/" + endpoint if endpoint[0] != "/"
      reqaddr = @url + endpoint
      dparams = URI.encode_www_form(getdata)
      uri = URI.parse(reqaddr + "?" + dparams)
      response = nil
      begin
        if reqaddr =~ /^https/
          https = Net::HTTP.new(uri.host, 443)
          https.use_ssl = true
          https.verify_mode = OpenSSL::SSL::VERIFY_NONE
          https.start{|h|
            request = Net::HTTP::Get.new(uri.request_uri)
            request.basic_auth(@user_id, @user_password) unless @user_id.nil?
            headers.each do |k, v|
              request[k] = v
            end
            response = h.request(request)
          }
        else
          Net::HTTP.start(uri.host, uri.port){|http|
            request = Net::HTTP::Get.new(uri.request_uri)
            request.basic_auth(@user_id, @user_password) unless @user_id.nil?
            headers.each do |k, v|
              request[k] = v
            end
            response = http.request(request)
          }
        end
        jsondata = response.body.strip
        errflg = false
        errflg = true if htmlret == false && jsondata =~ /^<html>/
        if errflg
          raise WebRequestError.new(jsondata.force_encoding("utf-8"))
        end        
      rescue
        unless @logger.nil?
          @logger.error("WebRequestError: can not send data.")
          @logger.error("#{$!}")
        else
          puts "WebRequestError: can not send data."
          puts "#{$!}"
        end
        jsondata = nil      
      end
      return jsondata, response.code.to_i, response if htmlret
      return jsondata    
    end    
  end
  
  # --------------------------------------------------------------------------
  class WebRequestError < StandardError
  end

end
