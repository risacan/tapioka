require "sinatra/base"
require "json"
require 'rack/esa_webhooks'
require "dotenv"
require "esa"

Dotenv.load

module Tapioka
  class Web < Sinatra::Base
    use Rack::EsaWebhooks, secret: ENV["ESA_SECRET"]

    get "/" do
      "🥤"
    end

    post "/esa-webhook" do
      request_body = JSON.parse(request.body.read)
      Tapioka::Esa.new(request_body).update_post
    end
  end

  class Esa
    def initialize(request_body)
      @body = request_body
    end

    def update_post
      client.update_post(number, category: "Users/#{name}")
    end

    private

    def client
      @client ||=  Esa::Client.new(access_token: ENV['ESA_API_TOKEN'], current_team: ENV['TEAM'])
    end

    def number
      @body["post"]["number"]
    end

    def name
      @body["user"]["screen_name"]
    end
  end
end

Tapioka::Web.run!
