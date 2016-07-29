###
# ENV
###
require 'dotenv'
Dotenv.load

###
# SINATRA
###
require 'sinatra'
require 'json'

set :bind, '0.0.0.0'
set :port, 3002
set :public_folder, Proc.new { File.join(root, "public") }

require 'pp'

###
# PGO API
###

require 'poke-api'

client = Poke::API::Client.new

email = ENV['EMAIL'].dup
password = ENV['PASSWORD'].dup
type = ENV['TYPE'].dup

client.login(email, password, type)

###
# STUFF
##
require_relative 'lib/pokemon'

@candies = {}
@items = {}

def get_pokemons(client, sort: :id)
  client.get_inventory

  response = client.call.response

  inventory = response[:GET_INVENTORY][:inventory_delta][:inventory_items]

  pokemons = []
  @candies = {}
  @items = {}
  @pokedex = {}

  inventory.each do |item|
    if !item[:inventory_item_data][:pokemon_data].nil?
      pokemons << Pokemon.from_api(item[:inventory_item_data][:pokemon_data])
    elsif !item[:inventory_item_data][:pokemon_family].nil?
      family = item[:inventory_item_data][:pokemon_family][:family_id]
      family = family.to_s.split('FAMILY_').last
      @candies[family.to_sym] = item[:inventory_item_data][:pokemon_family][:candy]
    elsif !item[:inventory_item_data][:item].nil?
      item_id = item[:inventory_item_data][:item][:item_id]
      item_quantity = item[:inventory_item_data][:item][:count]
      @items[item_id] = item_quantity
    elsif !item[:inventory_item_data][:pokedex_entry].nil?
      entry = item[:inventory_item_data][:pokedex_entry]

      pokemon_name = entry.delete(:pokemon_id)
      entry.delete(:evolution_stone_pieces)
      entry.delete(:evolution_stones)

      @pokedex[pokemon_name] = entry
    else
      pp item
    end
  end

  pokemons.compact!

  case sort
  when :id
    pokemons.sort_by! { |item| item.pokedex_id }
  else
    nil
  end

  pp @items

  pokemons
end

get '/' do
  pokemons = get_pokemons(client)
  erb :index, locals: { pokemons: pokemons, candies: @candies, pokedex: @pokedex }
end

get '/pokemons' do
  content_type :json

  get_pokemons(client).to_json
end

get '/pokemons/:pokemon_id/release' do
  client.release_pokemon(pokemon_id: params[:pokemon_id].to_i)

  t = client.call.response[:RELEASE_POKEMON]

  failure = t[:result] == :FAILED

  if failure
    status 400
  end

  content_type :json
  t.to_json
end

get '/pokemons/:pokemon_id/evolve' do
  client.evolve_pokemon(pokemon_id: params[:pokemon_id].to_i)

  t = client.call.response[:EVOLVE_POKEMON]

  failure = (t[:result] != :SUCCESS)

  if failure
    status 400
  end

  content_type :json
  t.to_json
end
