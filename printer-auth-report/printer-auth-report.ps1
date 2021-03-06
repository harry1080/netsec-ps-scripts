# Parameters
param(
    [Parameter(Mandatory=$True)] [string] $PrintServerList, # Path to the list of print servers
    [Parameter(Mandatory=$True)] [string] $TestPathList,   # Path 
    [string] $ReportPath = $(Join-Path -Path $PSScriptRoot -ChildPath "report.csv"),       # Path to the report to output
    [switch] $UseHTTPS = $false
)

# Constants
$PrintServers = Get-Content $PrintServerList
$TestPaths = Get-Content $TestPathList
If($UseHTTPS){
    $Protocol = "https"
}
Else{
    $Protocol = "http"
}

# Initialise the report array, including the first line
$report = @()
$report += ,@("Server","Hostname","IP", "Reachable?", "Requires authentication?")

# Get list of printers
$printers = @()
Try{
    $PrintServers | ForEach-Object{
        $server = $_
        Get-CimInstance -ClassName Win32_Printer -ComputerName $server | ForEach-Object{
            $printers += , @($_.Name, $($_.PortName).Replace('..','.'), $server)
        }
    }
}
Catch{
    Write-Error $_
}

# Test all printers
$printers | Foreach-Object{
    
    $printer_name, $printer_ip, $printer_server = $_
    $printer_reachable = $null
    $printer_secured = $null
    $return_codes = @()

    Write-Verbose -Verbose -Message "=== Testing $printer_name at $printer_ip ==="

    If(Test-Connection -Computername $printer_ip -Count 1 -Quiet -InformationAction Ignore ){
        Write-Verbose -Verbose -Message "Reached $printer_name at $printer_ip"
        $printer_reachable = $true

        # Test all web paths
        $TestPaths | ForEach-Object{


            $query_url = "$($Protocol)://$printer_ip/$_"
            Write-Verbose -Verbose -Message "Testing $printer_name at $query_url"

            try {
                $response = Invoke-WebRequest -URI $query_url -SkipCertificateCheck -MaximumRedirect 0
                $status_code = [int]$response.StatusCode
                if($status_code -eq 0){
                    $status_code = 200
                }
            }
            catch {
                $status_code = [int]$_.Exception.Response.StatusCode
            }

            $return_codes += , $status_code 
            Write-Verbose -Verbose -Message "$query_url returned HTTP $status_code"
    
        }
        
        If($return_codes.Contains(401)){
            $printer_secured = 'Secure'
        }
        Elseif($return_codes.Contains(200)){
            $printer_secured = 'Unsecured'
        }
        Else{
            $printer_secured = 'Needs Manual Review'
        }

    }
    Else{
        Write-Verbose -Verbose -Message "Couldn't reach $printer_name at $printer_ip"
        $printer_reachable = $false
        $printer_secured = 'Unreachable'
    }

    $report += ,@($printer_server, $printer_name,$printer_ip, $printer_reachable, $printer_secured)
}

Write-Verbose -Verbose -Message "=== Generating CSV report to $ReportPath ==="
# Create the CSV report
Add-Content $ReportPath -Value "SEP=,"                     # Write out the first line
$report | % { $_ -join ","} | Out-File $ReportPath -Append # Write out the rest of the report
Write-Verbose -Verbose -Message "Done!"
        $printer_reachable = $true

        # Test all web paths
        $TestPaths | ForEach-Object{


            $query_url = "$($Protocol)://$printer_ip/$_"
            Write-Output "Testing $printer_name at $query_url"

            try {
                $response = Invoke-WebRequest -URI $query_url -SkipCertificateCheck -MaximumRedirect 0
                $status_code = [int]$r.StatusCode
                if($status_code -eq 0){
                    $status_code = 200
                }
            }
            catch {
                $status_code = [int]$_.Exception.Response.StatusCode
            }

            $return_codes += , $status_code 
            Write-Output "$query_url returned HTTP $status_code"
    
        }
        
        If($return_codes.Contains(401)){
            $printer_secured = 'Secure'
        }
        Elseif($return_codes.Contains(200)){
            $printer_secured = 'Unsecured'
        }
        Else{
            $printer_secured = 'Needs Manual Review'
        }

    }
    Else{
        Write-Output "Couldn't reach $printer_name at $printer_ip"
        $printer_reachable = $false
        $printer_secured = 'Unreachable'
    }

    $report += ,@($printer_server, $printer_name,$printer_ip, $printer_reachable, $printer_secured)
}

Write-Output "`n=== Generating CSV report to $ReportPath ===`n"
# Create the CSV report
Add-Content $ReportPath -Value "SEP=,"                     # Write out the first line
$report | % { $_ -join ","} | Out-File $ReportPath -Append # Write out the rest of the report
Write-Output "Done!"
