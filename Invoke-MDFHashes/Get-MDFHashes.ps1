# Created by XPN (xpn.github.io)


Try {
    $currentLocation = Get-Location
    [Reflection.Assembly]::LoadFile($currentLocation.Path + "\\OrcaMDF.RawCore.dll") | Out-Null
    [Reflection.Assembly]::LoadFile($currentLocation.Path + "\\OrcaMDF.Framework.dll") | Out-NUll
} Catch {
    Write-Host "Could not load OrcaMDF libraries, please make sure that you run Import-Module from the dir containing OrcaMDF.RawCore.dll and OrcaMDF.Framework.dll"
}

function Get-MDFHashes
{
    [CmdletBinding()]Param (
    [Parameter(Mandatory = $True, ParameterSetName="mdf")]
    [String]$mdf
    )
    
    $instance = New-Object "OrcaMDF.RawCore.RawDataFile" $mdf

    $records = $instance.Pages | where {$_.Header.ObjectID -eq 34 -and $_.Header.Type -eq 1} | select -ExpandProperty Records
    
    $model = @( [OrcaMDF.RawCore.Types.RawType]::Int("id"), 
                [OrcaMDF.RawCore.Types.RawType]::Sysname("name")
               )
    
    $sysxlgns_id = 0

    foreach($r in $records) {
            Try {
                $row = [OrcaMDF.RawCore.RawColumnParser]::Parse( [OrcaMDF.RawCore.Records.RawPrimaryRecord]$r, $model  )
                
                if ($row.name -eq "sysxlgns") {
                    $sysxlgns_id = $row.id
                }

            } Catch {
                # Unknown error :(
            }
    }

    if ($sysxlgns_id -eq 0) {
        Write-Host "Could not find sysxlgns ObjectID in database"
        return @{}
    }


    $records = $instance.Pages | where {$_.Header.ObjectID -eq $sysxlgns_id -and $_.Header.Type -eq 1} | select -ExpandProperty Records

    $model = @( [OrcaMDF.RawCore.Types.RawType]::Int("id"), 
                [OrcaMDF.RawCore.Types.RawType]::Sysname("name") 
                [OrcaMDF.RawCore.Types.RawType]::VarBinary("sid")
                [OrcaMDF.RawCore.Types.RawType]::Int("status")
                [OrcaMDF.RawCore.Types.RawType]::Char("type", 1)
                [OrcaMDF.RawCore.Types.RawType]::DateTime("crdate")
                [OrcaMDF.RawCore.Types.RawType]::DateTime("modate")
                [OrcaMDF.RawCore.Types.RawType]::Sysname("dbname")
                [OrcaMDF.RawCore.Types.RawType]::Sysname("lang")
                [OrcaMDF.RawCore.Types.RawType]::VarBinary("pwdhash")
               )

    $results = @{}

    foreach($r in $records) {

        Try {
            $row = [OrcaMDF.RawCore.RawColumnParser]::Parse( [OrcaMDF.RawCore.Records.RawPrimaryRecord]$r, $model  )
    
            if ($row.pwdhash) { 
                $results +=  @{$row.name="0x" + [BitConverter]::ToString($row.pwdhash).Replace("-", "")}
            } elseif ($row.name) {
                $results +=  @{$row.name=""}
            }
        } Catch {
            # Unknown error :(
        }
    }

    return $results
}