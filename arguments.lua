--[[
Copyright 2019 Novemberisms

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local Arguments = {}

-- maps a name to a lua value
local values = {}
-- holds all the created flag handles so far
local flagHandles = {}

local arg = arg

setmetatable(Arguments, {
  __index = function(t, k)
    return t:get(k)
  end;
})

-- check to see if the name for the parameter hasn't already been taken
local function checkNameCollision(word)
  if values[word] ~= nil then
    error("There is already a parameter with the same name as '" .. word .. "'", 3)
  end
end

local flagHandleMt = {}
flagHandleMt.__index = flagHandleMt

local function createFlagHandle(default_value)
  local handle = setmetatable({
    __flagHandle = true,
    value = default_value,
  }, flagHandleMt)
  return handle
end

local function convert(input)
  if input == "true" then return true end
  if input == "false" then return false end
  if input == "nil" then return nil end
  if tonumber(input) then return tonumber(input) end
  return input
end

local function parseAssignment(input)
  local symbol, set_value = input, true
  if input:find("=") then
    symbol, set_value = input:match("^(.+)=(.+)$")
    set_value = convert(set_value)
  end
  return symbol, set_value
end

function Arguments:flag(name, symbol, default_value)
  -- validation
  checkNameCollision(name)
  if not symbol:find("^%-") then error("Flag symbols must begin with a dash (-)", 2) end

  -- create and process the flag handle
  local handle = createFlagHandle(default_value or false)
  values[name] = handle
  table.insert(flagHandles, handle)
  flagHandles[symbol] = true

  -- check arg to see if the flag is met
  for _, v in ipairs(arg) do
    local arg_symbol, set_value = parseAssignment(v)
    -- everything we just did above is useless if it's not actually the symbol we're looking for
    if arg_symbol == symbol then
      handle.value = set_value
    end
  end
end

function Arguments:pattern(pattern)
  local position = 1
  local required_mode = true
  for param in pattern:gmatch("[%[%w_=]+") do

    local should_assign = true
    local default_value = nil

    if param:find("^%[") then
      required_mode = false
      -- get rid of the leading and trailing square brackets
      param = param:sub(2, -1)
      if param:find("=") then
        param, default_value = param:match("^(.+)=(.+)$")
      end
    else
      if not required_mode then
        error("Required parameters are not allowed to appear after optional ones", 2)
      end
    end

    checkNameCollision(param)

    if required_mode then
      if param:find("=") then
        error("Required parameters are not allowed to have default values", 2)
      end
      if arg[position] == nil then
        error("Missing parameter '" .. param .. "'")
      end
      if arg[position]:find("^%-") then
        error("Required arguments cannot start with -")
      end
    else -- we are in optional mode
      if arg[position] and arg[position]:find("^%-") then
        -- this is a flag, so ignore it and give the optional its default value
        should_assign = false
        values[param] = default_value
      end  
      if arg[position] == nil then
        -- the optional param was not given, so give it its default value
        should_assign = false
        values[param] = default_value
      end
    end

    if should_assign then
      values[param] = arg[position]
    end

    position = position + 1
  end
end

function Arguments:get(name)
  local result = values[name]
  -- if it's a flag handle special value, then return whatever the value inside it is
  if type(result) == "table" and result.__flagHandle then
    return result.value 
  end
  -- otherwise just return the raw value
  return result
end

function Arguments:allFlags()
  local result = {}
  for _, v in ipairs(arg) do
    if v:find("^%-") then
      local symbol, value = parseAssignment(v)
      result[symbol] = value
    end
  end
  return result
end

function Arguments:iterFlags()
  return pairs(self:allFlags())
end

function Arguments:reset()
  values = {}
  flagHandles = {}
end

function Arguments:setArgTable(t)
  arg = t
end

return Arguments