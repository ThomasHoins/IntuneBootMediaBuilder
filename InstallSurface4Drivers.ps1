Invoke-Webrequest "https://download.microsoft.com/download/f/7/0/f70b3d0a-59b1-4842-9130-0c152bb738ba/SurfaceLaptop4_Intel_Win11_22621_24.102.19170.0.msi" -Outfile "X:\Users\Public\Downloads\SurfaceLaptop4_Intel_Win11_22621_24.102.19170.0.msi"
Msiexec.exe /a "X:\Users\Public\Downloads\SurfaceLaptop4_Intel_Win11_22621_24.102.19170.0.msi" targetdir="X:\Users\Public\Downloads\surface4_laptop_drivers" /qn

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