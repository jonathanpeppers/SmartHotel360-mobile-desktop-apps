$sln = '.\src\SmartHotel.Clients.sln'
$csproj = '.\src\SmartHotel.Clients\SmartHotel.Clients.Android\SmartHotel.Clients.Android.csproj'
$xaml = '.\src\SmartHotel.Clients\SmartHotel.Clients\App.xaml'
$adb = 'C:\Program Files (x86)\Android\android-sdk\platform-tools\adb.exe'
$packageName = 'com.microsoft.smarthotel'
$verbosity = 'quiet'

$nuget = '.\nuget.exe'
if (!(Test-Path $nuget)) {
    Invoke-WebRequest https://dist.nuget.org/win-x86-commandline/latest/nuget.exe -OutFile $nuget
    & git add $nuget
}

function Touch {
    param ([string] $path)
    $date = (Get-Date)
    $date = $date.ToUniversalTime()
    $file = Get-Item $path
    $file.LastAccessTimeUtc = $date
    $file.LastWriteTimeUtc = $date
}

function MSBuild {
    param ([string] $msbuild, [string] $target, [string] $binlog)

    & $msbuild $csproj /t:$target /v:$verbosity /bl:$binlog
    if (!$?) {
        exit
    }

    # So git clean call doesn't delete
    & git add $binlog
}

function Profile {
    param ([string] $msbuild, [string] $version)
    
    # Reset working copy & device
    & $adb uninstall $packageName
    & git clean -dxf
    & $nuget restore $sln

    # First
    MSBuild -msbuild $msbuild -target 'Build' -binlog "./first-build-$version.binlog"
    MSBuild -msbuild $msbuild -target 'SignAndroidPackage' -binlog "./first-package-$version.binlog"
    MSBuild -msbuild $msbuild -target 'Install' -binlog "./first-install-$version.binlog"

    # Second
    MSBuild -msbuild $msbuild -target 'Build' -binlog "./second-build-$version.binlog" 
    MSBuild -msbuild $msbuild -target 'SignAndroidPackage' -binlog "./second-package-$version.binlog"
    MSBuild -msbuild $msbuild -target 'Install' -binlog "./second-install-$version.binlog"

    # Third (Touch XAML)
    Touch $xaml
    MSBuild -msbuild $msbuild -target 'Build' -binlog "./third-build-$version.binlog"
    MSBuild -msbuild $msbuild -target 'SignAndroidPackage' -binlog "./third-package-$version.binlog"
    MSBuild -msbuild $msbuild -target 'Install' -binlog "./third-install-$version.binlog"
}

# 15.8.2
$msbuild = 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\MSBuild.exe'
Profile -msbuild $msbuild -version '15.8'

# 15.9 P2 (TODO)
#$msbuild = 'C:\Program Files (x86)\Microsoft Visual Studio\Preview\Enterprise\MSBuild\15.0\Bin\MSBuild.exe'
#Profile -msbuild $msbuild -version '15.9'

# Print summary of results
$logs = Get-ChildItem .\*.binlog
foreach ($log in $logs) {
    $time = & $msbuild $log | Select-Object -Last 1
    Write-Host "$log $time"
}