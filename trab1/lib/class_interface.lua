Interface = function(self)
  if type(self._name) ~= "string" then
    error("Interface defined without a '_name' field.",2) 
  end
  setmetatable(self,{
    __index={
      TestObject = function(interface,objectclass)
        for method in pairs(interface) do
          if method ~= "_name" and type(objectclass[method]) ~= 'function' then
            return false,method
          end
        end
        return true
      end,
      GetName = function(interface)
        return interface._name
      end,
    }
  })
  return self
end

