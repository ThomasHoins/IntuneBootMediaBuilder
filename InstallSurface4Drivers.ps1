Invoke-Webrequest "https://download.microsoft.com/download/f/7/0/f70b3d0a-59b1-4842-9130-0c152bb738ba/SurfaceLaptop4_Intel_Win11_22621_24.102.19170.0.msi" -Outfile "X:\Users\Public\Downloads\SurfaceLaptop4_Intel_Win11_22621_24.102.19170.0.msi"
Invoke-Webrequest "https://msdl.microsoft.com/download/symbols/msiexec.exe/DD894DD217000/msiexec.exe" -Outfile "X:\Users\Public\Downloads\msiexec.exe"

"X:\Windows\System32\msiexec.exe" /i "X:\Users\Public\Downloads\SurfaceLaptop4_Intel_Win11_22621_24.102.19170.0.msi" /qn

TglSerial
IntelPreciseTouch
SurfaceEthernetAdapter
SurfaceBattery
SurfaceHidMini
SurfaceHotPlug
SurfaceSerialHub
SurfaceTconDriver
surfacetimealarmacpifilter
surfacevirtualfunctionenum
TglChipset
ManagementEngine
