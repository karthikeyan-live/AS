$expectedReportPath = '/home/karthikeyan/Documents/AllState/expected-statistics.json'
$reportPath = '/home/karthikeyan/Documents/AllState/report/'
$jmeterPath = '/home/karthikeyan/Documents/Software/apache-jmeter-5.3/bin/jmeter.sh'
$jmxPath = '/home/karthikeyan/Documents/AllState/test.jmx';

function runJMeter {
    $arguments = '-n -t ' + $jmxPath + ' -l ' + $reportPath + 'report.csv -e -o ' + $reportPath
    Start-Process $jmeterPath $arguments -Wait
}

function exportReport {
    $expectedReport =(Get-Content $expectedReportPath | Out-String | ConvertFrom-Json)
    $report =(Get-Content "$($reportPath)statistics.json" | Out-String | ConvertFrom-Json)
    $arrayReport = @()

    $report.PSObject.Properties | ForEach-Object {
        
        write-host "|`r`n|->  $($_.Name)"
        foreach ($r in $expectedReport.PSObject.Properties) {
            $_.value  | add-member -Name "expected_$($r.Name)" -value $r.value -MemberType NoteProperty

            # <validate report>
            $failed=$false
            if(([String]$r.value.GetType() -eq 'long') -or ([String]$r.value.GetType() -eq 'double')){
                if($_.value."$($r.Name)" -ne [decimal]($r.value)){
                $failed=$true
                }
            }
            elseif(($r.value.StartsWith('<='))){
                if($_.value."$($r.Name)" -gt [decimal]($r.value.trimstart('<='))){
                $failed=$true
                }
            }
            elseif(($r.value.StartsWith('<'))){
                if($_.value."$($r.Name)" -ge [decimal]($r.value.trimstart('<'))){
                $failed=$true
                }
            }
            elseif(($r.value.StartsWith('>='))){
                if($_.value."$($r.Name)" -lt [decimal]($r.value.trimstart('>='))){
                $failed=$true
                }
            }
            elseif(($r.value.StartsWith('>'))){
                if($_.value."$($r.Name)" -le [decimal]($r.value.trimstart('>'))){
                $failed=$true
                }
            }
            elseif(($r.value.StartsWith('='))){
                if($_.value."$($r.Name)" -ne [decimal]($r.value.trimstart('='))){
                $failed=$true
                }
            }
            elseif($_.value."$($r.Name)" -ne [decimal]($r.value)){
                $failed=$true
                }
            if($failed -eq $true) {
                write-host "|      |-> $($r.Name)`r`n|      |      |-> Expected: $($r.Value)`r`n|      |      |-> Actual: $($_.value."$($r.Name)")" -ForegroundColor red
            } else {
                # write-host "|      |-> Success"
            }
            # </validate report>
        }
        if($failed -eq $false) {
            write-host "|      |-> Success"
        }
        $arrayReport += $_.value 
    }

    # save report in file
    $report | ConvertTo-Json | Set-Content "$($reportPath)report.json"
    $arrayReport  | Export-Csv -Path "$($reportPath)outfile.csv" -NoTypeInformation
    ($arrayReport | ConvertTo-Xml).Save("$($reportPath)outfile.xml")

    if($failed -eq $true) {
        write-host "Exiting with error" -ForegroundColor red
        exit 1
    }
}

runJMeter
exportReport