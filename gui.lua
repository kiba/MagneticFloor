UI = {}


function UI.initialize()
  for _, player in pairs(game.players) do
    local gui = player.gui
    if gui.top.hoverboard ~= nil then
      gui.top.hoverboard.destroy()
    end
    gui.top.add{type="frame", name="hoverboard"}
    gui.top.hoverboard.add{type="button",name="mode", caption = "Hoverboard Status: Inactive"}
    gui.top.hoverboard.add{type="label",name="charge"}
    global.hoverboard.status = false
  end
end

function UI.updateStatus()
  game.player.gui.top.hoverboard.charge.caption = "Charge: "..global.charge
end

function UI.switchMode()
  if global.hoverboard.status == true then
    game.player.gui.top.hoverboard.mode.caption = "Hoverboard Status: Active"
  elseif global.hoverboard.status == false then
    game.player.gui.top.hoverboard.mode.caption = "Hoverboard Status: Inactive"
  end
end