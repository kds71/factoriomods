for _, player in ipairs(game.players) do

    player.force.reset_recipes()
    player.force.reset_technologies()
    
    if player.force.technologies["automated-construction"].researched then
        player.force.recipes["upgrade-planner"].enabled = true
    end
	
end
