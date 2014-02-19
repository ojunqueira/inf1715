require "lib/class_interface"

local s_get_constructors
s_get_constructors = function(class)
  local constructors = {}
  if rawget(class,"_base") then -- single inheritance
    local ctors = s_get_constructors(rawget(class,"_base"))
    for i,ctor in ipairs(ctors) do
      table.insert(constructors,ctor)
    end
  elseif rawget(class,"_bases") then -- multiple inheritance
    for i,base in ipairs(rawget(class,"_bases")) do
      local ctors = s_get_constructors(base)
      for j,ctor in ipairs(ctors) do
        table.insert(constructors,ctor)
      end
    end
  end
  -- add the constructor of 'class', if existing
  local thisctor = rawget(class,"Constructor")
  if thisctor then
    table.insert(constructors,thisctor)
  end
  return constructors
end

local s_get_abstract_methods
s_get_abstract_methods = function(class,abstract_methods)
  if class._abstract then
    -- add the abstract methods of 'class'
    for m in pairs(class._abstract) do
      abstract_methods[m] = true
    end
  end
  if rawget(class,"_base") then      -- add the abstract methods of single parent class
    s_get_abstract_methods(rawget(class,"_base"),abstract_methods)
  elseif rawget(class,"_bases") then -- add the abstract methods of multiple parent classes
    for _,base in ipairs(rawget(class,"_bases")) do
      s_get_abstract_methods(base,abstract_methods)
    end
  end
end

-- check if object is complete (no abstract methods missing)
local function s_check_abstract_methods(class,instance)
  local abstract_methods = {}
  s_get_abstract_methods(class,abstract_methods)
  for m in pairs(abstract_methods) do
    if type(class[m]) ~= "function" then
      error("Class does not define the method "..m.." which was declared abstract: unable to instantiate object.",3)
    end
  end
end

-- check if object implements all interfaces correctly
local function s_check_implemented_interfaces(class,instance)
 if class._implements then
   for i,interface in ipairs(class._implements) do
     if not interface.TestObject then
       error("Class _implements field, index "..i.." is not an interface: unable to instantiate object.",3)
     end
     local ok, method = interface:TestObject(instance)
     if not ok then
       error("Class does not define the method "..method.." which was declared in one of its interfaces ("..interface:GetName().."): unable to instantiate object.",3)
     end
   end
 end
end

local function s_call_cascading_constructors(class,instance,callerLevel)
  local constructors = s_get_constructors(class)
  for _,constructor in ipairs(constructors) do
    local errwithtraceback
    local ok, err =
      xpcall(function ()
               constructor(instance)
             end,
             function (err)
               -- obtain traceback in case of errors, or else part
               -- of error stack will be missed
               errwithtraceback = debug.traceback(nil,2)
               return err
             end)
    if not ok then
      error((err or "").."\n"..(errwithtraceback or ""),callerLevel+1)
    end
  end
  return instance
end

local function s_call_single_constructor(class,instance,callerLevel)
  if class.Constructor then
    local errwithtraceback
    local ok, err, ret =
      xpcall(function ()
               return instance.Constructor(instance)
             end,
             function (err)
               -- obtain traceback in case of errors, or else part
               -- of error stack will be missed
               errwithtraceback = debug.traceback(nil,2)
               return err
             end)
    if not ok then
      error((err or "").."\n"..(errwithtraceback or ""),callerLevel+1)
    end
    return ret or instance
  else
    return instance 
  end
end

local function s_build_metatable_index(self)
  if self._bases then
    if #self._bases == 1 then
      self._base = self._bases[1]
      self._bases = nil
      return self._base
    else
      self._base = nil
      return function(instance,key)
        for _,base in ipairs(self._bases) do
          if base[key] then
            instance[key] = base[key]
            return base[key]
          end
        end
      end
    end
  elseif self._base then
    return self._base
  end
end

function Class (self)
  local index_mt = s_build_metatable_index(self)
  setmetatable(self,{
    __index = index_mt,
    __call = function(class,instance) 
      setmetatable(instance,class) 
      s_check_abstract_methods(class,instance)
      s_check_implemented_interfaces(class,instance)
      if class._cascade_constructors then
        return s_call_cascading_constructors(class,instance,2)
      else
        return s_call_single_constructor(class,instance,2)
      end
    end
  })
  self.__index = self
  return self
end

return Class
