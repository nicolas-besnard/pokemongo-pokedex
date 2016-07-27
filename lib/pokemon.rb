class Pokemon
  attr_accessor :id, :name, :pokedex_id, :raw_response, :cp

  def initialize(hash)
    hash.keys.each do |key|
      self.public_send("#{key}=", hash[key])
    end
  end

  # {:id=>17999104379928447960, :pokemon_id=>:ONIX, :cp=>95, :stamina=>0, :stamina_max=>23, :move_1=>:ROCK_THROW_FAST, :move_2=>:IRON_HEAD, :deployed_fort_id=>0, :owner_name=>"", :is_egg=>false, :egg_km_walked_target=>0, :egg_km_walked_start=>0, :origin=>0, :height_m=>6.761429786682129, :weight_kg=>94.65052032470703, :individual_attack=>1, :individual_defense=>10, :individual_stamina=>10, :cp_multiplier=>0, :pokeball=>1, :captured_cell_id=>9803818614664462336, :battles_attacked=>2, :battles_defended=>0, :egg_incubator_id=>0, :creation_time_ms=>1467842385935, :num_upgrades=>0, :additional_cp_multiplier=>0, :favorite=>0, :nickname=>"", :from_fort=>0}
  def self.from_api(response)
    return if response.nil? || response[:pokemon_id] == :MISSINGNO

    Pokemon.new(
      id: response[:id],
      name: response[:pokemon_id],
      cp: response[:cp],
      pokedex_id: RpcEnum::PokemonId.resolve(response[:pokemon_id].to_sym),
      raw_response: response
    )
  end

  def image_path
    "icons/#{self.pokedex_id}.png"
  end
end
