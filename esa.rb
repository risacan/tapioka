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
    @screen_name =  @body.fetch('user').fetch('screen_name')
  end

  attr_reader :body, :number, :screen_name

  def update_post
    return unless content.fetch("name").match(/readme/i).nil?
    return if has_category?

    client.update_post(number, category: "Users/#{screen_name}")
    notify_via_comment
  end

  private

  def client
    @client ||= Esa::Client.new(access_token: ENV['ESA_API_TOKEN'], current_team: ENV['TEAM'])
  end

  def content
    @content ||= client.post(number).body
  end

  def has_category?
    category = content.fetch('category')
    return false if category.nil?

    true
  end

  def notify_via_comment
    client.create_comment(number, body_md: body_md)
  end

  def body_md
    "@#{screen_name} カテゴリを移動してね!"
  end
end

Tapioka::Web.run!
