--==============================================================================
-- Class Dependency
--==============================================================================



--==============================================================================
-- Class Implementation
--==============================================================================

util = {}


--==============================================================================
-- Public Methods
--==============================================================================

--FileExists()
--  parameters:
--    [1] $string  [file path and name including extension to be evaluated]
--  return:
--    [1] $boolean [true if file exists, false otherwise]
function util.FileExists(file)
  if (file == nil or type(file) ~= "string" or file == "") then
    return false
  end
  local f, msg = io.open(file, "r")
  if (f == nil) then
    return false
  end
  f:close()
  return true
end

--FileToTable()
--  parameters:
--    [1] 
--  return:
--    [1] 
function util.FileToTable(file)
  if (file == nil or type(file) ~= "string" or file == "") then
    return false, "Parameter 'file' is invalid"
  end
  local f = io.open(file, "r")
  if (f == nil) then
    return false, "Could not open desired file"
  end
  local t = FileToTableAux(f, {})
  f:close()
  if (t and type(t) == "table") then
    return true, t
  end
  return false, {}
end

--StringIsNull()
--  parameters:
--    [1] $string  [string that is going to be evaluated]
--  return:
--    [1] $boolean [true if string is null]
function util.StringIsNull(str)
  return (str == nil or str == "")
end

--TableCopy()
--  parameters:
--    [1] $table [table that is going to be duplicated]
--  return:
--    [1] $table [copy of incoming table]
function util.TableCopy(t)
  if (not t or type(t) ~= "table") then
    return
  end
  local ret = {}
  local mt = getmetatable(t)
  if mt then
    setmetatable(ret, mt)
  end
  for k,v in pairs(t) do
    v = rawget(t, k)
    if type(v)== "table" then
      rawset(ret, k, util.TableCopy(v))
    else
      rawset(ret, k, v)
    end
  end
  return ret
end

--TableGetChanges()
--  required:
--    [1] $table [old table]
--    [2] $table [new table]
--  return:
--    [1] $table [fields that have been modified from old_table to new_table]
function util.TableGetChanges(old_table, new_table)
  if not old_table or not new_table then 
    return 
  end
  local changes = {}
  for k, v in pairs(old_table) do
    if type(v) == "table" then
      changes[k] = utils.GetTableChanges(v, new_table[k])
    else
      if new_table[k] ~= nil and new_table[k] ~= v then
        changes[k] = new_table[k]
      end
    end
  end
  if next(changes) then
    return changes
  end
end

--TableIsEmpty()
--  parameters:
--    [1] $table   [table that is going to be valuated]
--  return:
--    [1] $boolean [true if table is empty, false otherwise]
function util.TableIsEmpty (t)
  assert(type(t) == "table")
  for _, _ in pairs(t) do
    return false
  end
  return true
end

--TablePrint()
--  parameters:
--    [1] $table [table that is going to be printed]
function util.TablePrint (t)
  if (not t) then
    return
  end
  print(TablePrintAux("", t, ""))
end

--TableToFile()
--  parameters:
--    [1] $table  [table that is going to be printed]
--  return:
--    [1] $string [string of copied table]
function util.TableToFile (file, t)
  if (file == nil or type(file) ~= "string" or file == "") then
    return false, "Parameter 'file' is invalid"
  end
  local f = io.open(file, "w")
  if (f == nil) then
    return false, "Could not open desired file"
  end
  if (not t) then
    return
  end
  TableToFileAux(f, "", t, "")
  f:close()
  return true
end

--TableToString()
--  parameters:
--    [1] $table  [table that is going to be printed]
--  return:
--    [1] $string [string of copied table]
function util.TableToString (t)
  if (not t) then
    return
  end
  return TablePrintAux("", t, "")
end


--==============================================================================
-- Private Methods
--==============================================================================

function FileToTableAux(file, t)
  local str = file:read()
  while (str) do
    if (string.find(str, '%["([^"]+)"%] = {')) then
      local _, _, field = string.find(str, '%["([^"]+)"%] = {')
      t[field] = FileToTableAux(file, {})
    elseif (string.find(str, '%[([^%]]+)%] = {')) then
      local _, _, n = string.find(str, '%[([^%]]+)%] = {')
      n = tonumber(n)
      t[n] = FileToTableAux(file, {})
    elseif (string.find(str, '%["([^"]+)"%]%s%=%s"([^"]+)"')) then
      local _, _, field, value = string.find(str, '%["([^"]+)"%]%s%=%s"([^"]+)"')
      t[field] = value
    elseif (string.find(str, '%[([^%]]+)%]%s%=%s"([^"]+)"')) then
      local _, _, n, value = string.find(str, '%[([^%]]+)%]%s%=%s"([^"]+)"')
      n = tonumber(n)
      t[n] = value
    elseif (string.find(str, "}")) then
      return t
    end
    str = file:read()
  end
end

function TablePrintAux (s, t, indent)
  s = s .. "{\n"
  local oldindent = indent
  indent = indent .. "  "
  for k, v in pairs(t) do
    if (type(k) == "string") then
      s = s .. indent .. "[" .. string.format("%q", k) .. "] = "
    elseif (type(k) == "number") then
      s = s .. indent .. "[" .. k .. "] = "
    end
    if (type(v) == "table") then
      s = TablePrintAux(s, v, indent)
    elseif (type(v) == "string") then
      s = s .. string.format("%q", v)
    else
      s = s .. tostring(v)
    end
    s = s .. ",\n"
  end
  s = s .. oldindent .. "}"
  return s
end

function TableToFileAux (file, s, t, indent)
  file:write("{\n")
  local oldindent = indent
  indent = indent .. "  "
  for k, v in pairs(t) do
    if (type(k) == "string") then
      file:write(indent .. "[" .. string.format("%q", k) .. "] = ")
    elseif (type(k) == "number") then
      file:write(indent .. "[" .. k .. "] = ")
    end
    if (type(v) == "table") then
      s = TableToFileAux(file, s, v, indent)
    elseif (type(v) == "string") then
      file:write(string.format("%q", v))
    else
      file:write(tostring(v))
    end
    file:write(",\n")
  end
  file:write(oldindent .. "}")
end


--==============================================================================
-- Return
--==============================================================================

