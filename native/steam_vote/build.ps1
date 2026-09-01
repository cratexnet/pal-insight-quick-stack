$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$nativeRoot = $PSScriptRoot
$portableCandidates = @(
    (Join-Path $repoRoot 'toolchain/tools/portable-msvc/msvc'),
    (Join-Path (Split-Path -Parent $repoRoot) 'pal-insight/toolchain/tools/portable-msvc/msvc')
)
$portable = $portableCandidates | Where-Object { Test-Path -LiteralPath $_ } |
    Select-Object -First 1
if ($null -eq $portable) {
    throw 'Portable MSVC toolchain was not found in this repo or the sibling Pal Insight repo.'
}
$msvc = Join-Path $portable 'VC/Tools/MSVC/14.44.35207'
$sdk = Join-Path $portable 'Windows Kits/10'
$sdkVersion = '10.0.26100.0'
$build = Join-Path $nativeRoot 'build'
$bin = Join-Path $nativeRoot 'bin'
$cl = Join-Path $msvc 'bin/Hostx64/x64/cl.exe'
$link = Join-Path $msvc 'bin/Hostx64/x64/link.exe'

foreach ($required in @($cl, $link)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Required build dependency is missing: $required"
    }
}

New-Item -ItemType Directory -Force $build, $bin | Out-Null

$includes = @(
    "/I$($msvc)\include",
    "/I$($sdk)\Include\$sdkVersion\ucrt",
    "/I$($sdk)\Include\$sdkVersion\shared",
    "/I$($sdk)\Include\$sdkVersion\um"
)
$libraries = @(
    "/LIBPATH:$($msvc)\lib\x64",
    "/LIBPATH:$($sdk)\Lib\$sdkVersion\ucrt\x64",
    "/LIBPATH:$($sdk)\Lib\$sdkVersion\um\x64"
)

$object = Join-Path $build 'pal_insight_quick_stack_steam_vote.obj'
& $cl /nologo /c /O2 /std:c++20 /EHsc /W4 /WX /MT `
    /D_CRT_SECURE_NO_WARNINGS @includes `
    (Join-Path $nativeRoot 'pal_insight_quick_stack_steam_vote.cpp') "/Fo:$object"
if ($LASTEXITCODE -ne 0) { throw 'Quick Stack Steam vote bridge compilation failed.' }

$output = Join-Path $bin 'PalInsightQuickStackSteamVote.dll'
& $link /nologo /DLL /OPT:REF /OPT:ICF /INCREMENTAL:NO /Brepro `
    "/DEF:$($nativeRoot)\PalInsightQuickStackSteamVote.def" "/OUT:$output" `
    @libraries $object
if ($LASTEXITCODE -ne 0) { throw 'Quick Stack Steam vote bridge link failed.' }

Write-Output "Built $output"
