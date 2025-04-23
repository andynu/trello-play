#!/usr/bin/env ruby

require 'dotenv/load'
require 'httparty'
require 'json'
require 'yaml'
require 'fileutils'

class TrelloAPI
  BASE_URL = 'https://api.trello.com/1'
  CONFIG_FILE = File.expand_path('~/.trello_config.yml')
  
  def initialize
    @api_key = ENV['TRELLO_API_KEY']
    @secret = ENV['TRELLO_SECRET']
    
    if @api_key.nil? || @secret.nil?
      # Try to read directly from .env file
      if File.exist?('.env')
        File.readlines('.env').each do |line|
          if line.start_with?('TRELLO_API_KEY=')
            @api_key = line.strip.split('=')[1]
          elsif line.start_with?('TRELLO_SECRET=')
            @secret = line.strip.split('=')[1]
          end
        end
      end
    end
    
    raise "TRELLO_API_KEY not found in .env file or environment variables" unless @api_key
    raise "TRELLO_SECRET not found in .env file or environment variables" unless @secret
    
    load_or_create_config
  end

  def load_or_create_config
    if File.exist?(CONFIG_FILE)
      config = YAML.load_file(CONFIG_FILE)
      @token = config['token']
      @board_id = config['board_id']
      @board_name = config['board_name']
    else
      # Get token through authorization flow
      auth_url = "https://trello.com/1/authorize?expiration=never&scope=read,write&response_type=token&name=Server%20Token&key=#{@api_key}"
      puts "\nPlease visit this URL to authorize the application:"
      puts auth_url
      print "\nEnter the token you received: "
      @token = STDIN.gets.strip

      # Get boards and select one
      boards = get_boards
      print_boards(boards)
      print "\nSelect board number: "
      board_index = STDIN.gets.to_i - 1
      board = boards[board_index]
      @board_id = board['id']
      @board_name = board['name']

      # Save config
      save_config
    end
  end

  def save_config
    config = {
      'token' => @token,
      'board_id' => @board_id,
      'board_name' => @board_name
    }
    FileUtils.mkdir_p(File.dirname(CONFIG_FILE))
    File.write(CONFIG_FILE, config.to_yaml)
  end

  def get_boards
    response = HTTParty.get("#{BASE_URL}/members/me/boards", query: {
      key: @api_key,
      token: @token,
      fields: 'name,id'
    })
    JSON.parse(response.body)
  end

  def get_lists
    response = HTTParty.get("#{BASE_URL}/boards/#{@board_id}/lists", query: {
      key: @api_key,
      token: @token,
      fields: 'name,id'
    })
    JSON.parse(response.body)
  end

  def get_all_cards
    response = HTTParty.get("#{BASE_URL}/boards/#{@board_id}/cards", query: {
      key: @api_key,
      token: @token,
      fields: 'name,id,idList'
    })
    JSON.parse(response.body)
  end

  def move_card(card_id, list_id)
    response = HTTParty.put("#{BASE_URL}/cards/#{card_id}", query: {
      key: @api_key,
      token: @token,
      idList: list_id
    })
    JSON.parse(response.body)
  end

  def print_boards(boards)
    puts "\nAvailable boards:"
    boards.each_with_index do |board, index|
      puts "#{index + 1}. #{board['name']}"
    end
  end
end

def fuzzy_match(needle, haystack)
  needle = needle.downcase
  matches = haystack.select do |item|
    item['name'].downcase.include?(needle)
  end
  
  case matches.size
  when 0
    puts "\nNo matches found for '#{needle}'"
    puts "Available options:"
    haystack.each { |item| puts "- #{item['name']}" }
    exit 1
  when 1
    matches.first
  else
    puts "\nMultiple matches found for '#{needle}':"
    matches.each_with_index do |match, i|
      puts "#{i + 1}. #{match['name']}"
    end
    print "Select number: "
    index = STDIN.gets.to_i - 1
    matches[index]
  end
end

def main
  if ARGV.length != 2
    puts "Usage: #{$0} <card_name> <column>"
    puts "e.g. #{$0} fcas testing"
    exit 1
  end

  card_name = ARGV[0]
  target_column = ARGV[1]
  
  trello = TrelloAPI.new
  
  # Get all lists and cards
  lists = trello.get_lists
  cards = trello.get_all_cards
  
  # Find card first
  card = fuzzy_match(card_name, cards)
  
  # Find target list
  target_list = fuzzy_match(target_column, lists)
  
  # Move the card
  if card['idList'] == target_list['id']
    puts "\nCard '#{card['name']}' is already in list '#{target_list['name']}'"
  else
    current_list = lists.find { |l| l['id'] == card['idList'] }
    trello.move_card(card['id'], target_list['id'])
    puts "\nMoved card '#{card['name']}' from '#{current_list['name']}' to '#{target_list['name']}'"
  end
end

if __FILE__ == $0
  main
end