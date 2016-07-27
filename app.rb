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

def get_pokemons(client, sort: :id)
  client.get_inventory

  response = client.call.response

  pp response

  inventory = response[:GET_INVENTORY][:inventory_delta][:inventory_items]
    .map { |item| Pokemon.from_api(item[:inventory_item_data][:pokemon]) }
    .compact

  case sort
  when :id
    inventory.sort_by! { |item| item.pokedex_id }
  else
    nil
  end

  inventory
end

get '/' do
  erb :index, locals: { pokemons: get_pokemons(client) }
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

  t.to_json
end

get '/pokemons/:pokemon_id/evolve' do
  client.evolve_pokemon(pokemon_id: params[:pokemon_id].to_i)

  t = client.call.response[:EVOLVE_POKEMON]

  failure = t[:result] == :FAILED

  pp t

  if failure
    status 400
  end

  t.to_json
end
