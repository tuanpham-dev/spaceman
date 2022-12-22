local module = {}

module.ternary = function(condition, valueOnTrue, valueOnFalse)
  if condition then
    return valueOnTrue
  else
    return valueOnFalse
  end
end

module.findIndex = function(array, value)
  for i, v in ipairs(array) do
    if v == value then
      return i
    end
  end

  return nil
end

module.getNextIndex = function(index, size, direction)
  local nextIndex = index + module.ternary(direction ~= 'left', 1, -1)

  return (nextIndex - 1) % size + 1
end

module.hasValue = function(array, value)
  for _, val in ipairs(array) do
    if val == value then
      return true
    end
  end

  return false
end

module.loadSetting = function(object, key, defaultValue)
  local value = hs.settings.get(object.name .. '.' .. key)

  object[key] = module.ternary(value ~= nil, value, defaultValue)
end

module.saveSetting = function(object, key, value, callback)
  hs.settings.set(object.name .. '.' .. key, value)

  object[key] = value
end

return module