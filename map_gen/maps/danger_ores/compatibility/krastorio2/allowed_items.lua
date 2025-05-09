local items = {
  -- raws
  'coal',
  'compact-raw-rare-metals',
  'copper-ore',
  'iron-ore',
  'kr-imersite',
  'kr-rare-metal-ore',
  'stone',
  'uranium-ore',
  'wood',
  -- processed
  'kr-coke',
  'kr-enriched-copper',
  'kr-enriched-iron',
  'kr-enriched-rare-metals',
  'fluoride',
  'kr-imersite-crystal',
  'kr-imersite-powder',
  'kr-lithium-chloride',
  'kr-lithium',
  'kr-quartz',
  'kr-sand',
  'kr-silicon',
  'solid-fuel',
  'sulfur',
  'yellowcake',
  -- plates
  'copper-plate',
  'kr-glass',
  'kr-imersium-plate',
  'iron-plate',
  'plastic-bar',
  'kr-rare-metals',
  'steel-plate',
  'stone-brick',
  -- intermediates
  'kr-electronic-components',
  'electronic-circuit',
  'advanced-circuit',
  'processing-unit',
}

local allowed_recipes = {}

for _, k in pairs(items) do
  allowed_recipes[k] = true
end

return allowed_recipes