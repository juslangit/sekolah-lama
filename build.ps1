# Packs the Luau files in src\ into SekolahLama.rbxlx, which Roblox Studio opens directly.
# Run:  powershell -ExecutionPolicy Bypass -File build.ps1
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ref = 0

function New-Item-Xml([string]$class, [string]$name, [string]$inner) {
    $script:ref++
    return '<Item class="{0}" referent="RBX{1}"><Properties><string name="Name">{2}</string></Properties>{3}</Item>' -f $class, $script:ref, $name, $inner
}

function New-Script-Xml([string]$class, [string]$name, [string]$file) {
    $code = [IO.File]::ReadAllText((Join-Path $root "src\$file"))
    if ($code.Contains(']]>')) { throw "$file contains ']]>' which cannot be stored in the place file." }
    $script:ref++
    return '<Item class="{0}" referent="RBX{1}"><Properties><string name="Name">{2}</string><ProtectedString name="Source"><![CDATA[{3}]]></ProtectedString></Properties></Item>' -f $class, $script:ref, $name, $code
}

$replicated = New-Item-Xml 'ReplicatedStorage' 'ReplicatedStorage' (
    New-Script-Xml 'ModuleScript' 'Config' 'Config.lua')

$server = New-Item-Xml 'ServerScriptService' 'ServerScriptService' (
    (New-Script-Xml 'ModuleScript' 'World' 'World.lua') +
    (New-Script-Xml 'ModuleScript' 'Ghost' 'Ghost.lua') +
    (New-Script-Xml 'Script' 'Main' 'Main.server.lua'))

$starter = New-Item-Xml 'StarterPlayer' 'StarterPlayer' (
    New-Item-Xml 'StarterPlayerScripts' 'StarterPlayerScripts' (
        (New-Script-Xml 'LocalScript' 'Hud' 'Hud.client.lua') +
        (New-Script-Xml 'LocalScript' 'Sprint' 'Sprint.client.lua') +
        (New-Script-Xml 'LocalScript' 'Flashlight' 'Flashlight.client.lua')))

$xml = '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">' +
    $replicated + $server + $starter + '</roblox>'

$out = Join-Path $root 'SekolahLama.rbxlx'
[IO.File]::WriteAllText($out, $xml, (New-Object Text.UTF8Encoding($false)))
Write-Output "Built $out"
