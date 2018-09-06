$sln = '.\src\SmartHotel.Clients.sln'
$csproj = '.\src\SmartHotel.Clients\SmartHotel.Clients.Android\SmartHotel.Clients.Android.csproj'
$xaml = '.\src\SmartHotel.Clients\SmartHotel.Clients\App.xaml'
$verbosity = 'minimal'

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
    param ([string] $msbuild, [string] $version)
    
    # Reset working copy
    & git clean -dxf
    & $nuget restore $sln

    # First build
    $binlog = "./first-$version.binlog"
    & $msbuild $csproj /v:$verbosity /bl:$binlog
    if (!$?) {
        exit
    }
    & git add $binlog

    # Second build
    $binlog = "./second-$version.binlog"
    & $msbuild $csproj /v:$verbosity /bl:$binlog
    if (!$?) {
        exit
    }
    & git add $binlog

    # Third build (Touch XAML)
    $binlog = "./third-$version.binlog"
    Touch $xaml
    & $msbuild $csproj /v:$verbosity /bl:$binlog
    if (!$?) {
        exit
    }
    & git add $binlog
}

# 15.8.2
$msbuild = 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\MSBuild.exe'
MSBuild -msbuild $msbuild -version '15.8'

# 15.9 P2
$msbuild = 'C:\Program Files (x86)\Microsoft Visual Studio\Preview\Enterprise\MSBuild\15.0\Bin\MSBuild.exe'
MSBuild -msbuild $msbuild -version '15.9'