--==============================================================================
-- Dependency
--==============================================================================

--==============================================================================
-- Data Structure
--==============================================================================

local Lulex = {}

local rex_ok, rex

for _, flavor in ipairs{"gnu", "pcre", "tre", "posix", "oniguruma"} do
   rex_ok, rex = pcall(require, "rex_"..flavor)
   if rex_ok then
      break
   end
end

--==============================================================================
-- Private Methods
--==============================================================================

local function Lua_match(rule, input, at)
   --if (_DEBUG) then print("Lul :: Lua_match") end
   local match = string.match(input, "^"..rule[1], at)
   if match then
      return at + #match
   end
end

local function Re_match(rule, input, at)
   --if (_DEBUG) then print("Lul :: Re_match") end
   if not rule.pat then
      rule.pat = rex.new("^"..rule[1])
   end
   local start, finish = rule.pat:find(input:sub(at))
   if start then
      return at+(finish-start)+1
   end
end

local function Run(self, input)
   --if (_DEBUG) then print("Lul :: Run") end
   local at = 1
   while at <= #input do
      local lrule = nil
      local llen = 0
      for _, rule in ipairs(self.rules) do
         local found = self.match(rule, input, at)
         if found then
            local len = found - at
            if len > llen then
               llen = len
               lrule = rule
            end
         end
      end
      if lrule then
         lrule[2](input:sub(at, at+llen-1))
         at = at + llen
      else
         io.write(input:sub(at, at))
         at = at + 1
      end
   end
end


--==============================================================================
-- Public Methods
--==============================================================================

function Lulex.New(rules, use_lua)
   --if (_DEBUG) then print("Lul :: New") end
   return {
      match = (use_lua or not rex_ok) and Lua_match or Re_match,
      rules = rules,
      run = Run,
   }
end


--==============================================================================
-- Return
--==============================================================================

return Lulex