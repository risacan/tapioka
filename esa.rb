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
      request_body =  request.body.read
      TapiokaEsa.new(request_body).update_post
    end
  end
end


class TapiokaEsa
  def initialize(request_body)
    @body = JSON.parse(request_body)
    @number = @body.fetch('post').fetch('number')
    @name =  @body.fetch('user').fetch('screen_name')
  end

  def update_post
    client.update_post(@number, category: "Users/#{@name}") unless has_category?
  end

  private

  def client
    @client ||= Esa::Client.new(access_token: ENV['ESA_API_TOKEN'], current_team: ENV['TEAM'])
  end

  def content
    response = client.post(@number)
    response.body
  end

  def has_category?
    category = content.fetch('category')
    return false if category.nil?

    true
  end
end

Tapioka::Web.run!
