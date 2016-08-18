require 'util'
require 'src/gui'
require 'src/move'
require "test"
require "stdlib/log/logger"

LOG = Logger.new("MagneticFloor")

function print(stuff)
  game.players[1].print(stuff)
end

function printBool(stuff)
  game.players[1].print(tostring(stuff))
end

function setup()
  global.hoverboard = global.hoverboard or {}
end

function activateEquipment(index)
  global.hoverboard[index].inserted = true
  global.hoverboard[index].active = false
  UI.initialize(index)
end

function deactivateEquipment(index)
  if global.hoverboard[index].inserted == true then
    global.hoverboard[index].inserted = false
    UI.destroy(index)
  end
end

function createPlayerMag(i)
  local entity = {
    charge = 0,
    active = false,
    inserted = false,
  }
  global.hoverboard[i] = entity
end

script.on_init(setup)

function getArmor(index)
  local armor = game.players[index].get_inventory(defines.inventory.player_armor)[1]
  return armor
end

function armorCheck(index)
  local armor = getArmor(index)
  if armor.valid_for_read and armor.has_grid then
    return true
  end
  return false
end

script.on_event(defines.events.on_player_joined_game, function(event)
  createPlayerMag(event.player_index)
end)

script.on_event(defines.events.on_tick, function(event)
  local n = 0
  for k,v in pairs(game.players) do
    if global.hoverboard[k] == nil then
      createPlayerMag(v.index)
    end
    if global.hoverboard[k].inserted == true and global.hoverboard[k].active == true then
      locomotion(k)
      tileCheck(k)
      UI.updateStatus(k)
    end
  end

end)

script.on_event(defines.events.on_player_armor_inventory_changed, function(event)
  local index = event.player_index
  if armorCheck(index) then
    local armor = getArmor(index)
    local equipment = armor.grid.equipment
    for i, e in ipairs(equipment) do
      if e.name == "hoverboard" then
        activateEquipment(index)
      end
    end
  else
    deactivateEquipment(index)
  end
end)

script.on_event(defines.events.on_player_placed_equipment, function(event)
  local index = event.player_index
  if armorCheck(index) and event.equipment.name == "hoverboard" then
      activateEquipment(index)
  end
end)

script.on_event(defines.events.on_player_removed_equipment, function(event)
  local index = event.player_index
  if armorCheck(index) and event.equipment == "hoverboard" then
    deactivateEquipment(index)
  end
end)

script.on_event(defines.events.on_entity_died, function(event)
  if event.entity.name == "player" then
    global.dead = true
  end
end)

script.on_event(defines.events.on_gui_click,function(event)
  local index = event.player_index
  if event.element.name == "mode" then
    if global.hoverboard[index].active == false then
      global.hoverboard[index].active = true
    elseif global.hoverboard[index].active == true then
      global.hoverboard[index].active = false
    end
    UI.switchMode(global.hoverboard[index].active,index)
  end
end)

function entity_on_built_tile_action(event)
  for k,v in pairs(event.positions) do
    local tile = game.players[event.player_index].surface.get_tile(v.x,v.y)
    if tile.name == "accelerator" then
      local entity = game.players[event.player_index].surface.create_entity{
        name = "accelerator_charger",
        position = tile.position,
        force = game.players[event.player_index].force
      }
    else
      local entity = game.players[event.player_index].surface.find_entity("accelerator_charger",tile.position)
      if entity ~= nil then
        entity.destroy()
      end
    end
  end
end

function entity_on_removed_tile_action(event)
  for k,v in pairs(event.positions) do
    local tile = game.players[event.player_index].surface.get_tile(v.x,v.y)
    local entity = game.players[event.player_index].surface.find_entity("accelerator_charger", tile.position)
    if entity ~= nil then
      entity.destroy()
    end
  end
end

script.on_event(defines.events.on_player_built_tile,entity_on_built_tile_action)
script.on_event(defines.events.on_robot_built_tile,entity_on_built_tile_action)
script.on_event(defines.events.on_player_mined_tile, entity_on_removed_tile_action)
script.on_event(defines.events.on_robot_mined_tile, entity_on_removed_tile_action)

function charge_hoverboard(index,tile)
  local entity = game.players[index].surface.find_entity("accelerator_charger", tile.position)
  if entity ~= nil then
    local charge_needed = 5 - global.hoverboard[index].charge
    local energy_needed = (charge_needed) * "1000"
    if (entity.energy - energy_needed) > 0 then
      entity.energy = entity.energy - energy_needed
      global.hoverboard[index].charge = global.hoverboard[index].charge + charge_needed
    else
      print("Insufficient energy for charging.")
    end
  end
end

function locomotion(index)
  local orientation = game.players[index].walking_state.direction
  if global.hoverboard[index].charge > 0 then
    if game.tick % 60 == 0 then
      global.hoverboard[index].charge = global.hoverboard[index].charge - 1
    end
    game.players[index].walking_state = {walking = true, direction = orientation}
  end
end

function inboundTile(name)
  local tiles = {"copper-floor", "copper-floor2", "copper-floor3","accelerator","down","left","up","right"}
  for _, tile in ipairs(tiles) do
    if tile == name then
      return true
    end
  end
  return false
end
