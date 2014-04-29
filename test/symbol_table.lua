local tab = require "src/symbol_table"

print("First Step")
tab.AddScope()
tab.Print()
print("Second Step")
tab.AddScope()
tab.AddScope()
tab.AddScope()
tab.Print()
print("Third Step")
tab.RemoveScope()
tab.Print()