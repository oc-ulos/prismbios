-- menus?

local eeprom=component.proxy((component.list("eeprom")()))
local bootable={}
local selected=0
for i=1,#drives do
  local drive=drives[i]
  for j=1,#drive.ptt do
    if drive.ptt[j].boot then
      bootable[#bootable+1]={drive=drive.drive,start=drive.ptt[j].start,size=drive.ptt[j].size,type=drive.ptt[j].type}
      if drive.address == eeprom.getData() then
        selected = #bootable
      end
    end
  end
end
write("")
if #bootable==0 then
  computer.beep("....")
  write("No bootable medium found.")
  while true do computer.pullSignal() end
elseif #bootable>1 then
  write("Please select a boot device.")
  for i=1,#bootable do
    local b=bootable[i]
    write(("%d) %s (%s)"):format(i,b.drive.address:sub(1,8),b.type))
  end
  if selected>0 then
    write("Will default to "..selected.." if no choice is made")
  end
  repeat
    local signal=table.pack(computer.pullSignal(5))
    local char
    if signal[1]=="key_down" then
      char=string.char(signal[3])
      selected=tonumber(char)
    end
  until char or bootable[selected]
end
local boot = bootable[selected]
write("Booting from "..boot.drive.address:sub(1,8))
eeprom.setData(boot.drive.address)
function computer.getBootAddress()return boot.drive.address end
local ok,err=xpcall(function()
  assert(load((readers[boot.type] or readers.generic)(boot),"="..boot.drive.address:sub(1,8)))()
end, debug.traceback)
if not ok and err then
  for line in err:gsub("\t","  "):gmatch("[^\n]+") do
    write(line)
  end
end
while true do computer.pullSignal() end
