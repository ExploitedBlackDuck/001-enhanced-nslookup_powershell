# PowerShell Script Documentation: nslookup Processing Script

## Purpose
This script performs `nslookup` operations on a list of IP addresses and Fully Qualified Domain Names (FQDNs) provided in an input text file. It logs the results and any errors encountered during execution. The final results are exported to a CSV file.

## Prerequisites
- PowerShell installed on the system.
- An input file (`input.txt`) containing a list of IP addresses and FQDNs, each on a new line.

## Script Components

### Variables
- `$inputFile`: Path to the input text file containing the list of IP addresses and FQDNs.
- `$outputFile`: Path to the output CSV file where results will be stored.
- `$logFile`: Path to the log file where script execution logs will be recorded.

### Log File Initialization
The script clears any previous logs from the log file before starting new logging operations:
```powershell
Clear-Content -Path $logFile -ErrorAction SilentlyContinue
```

### Results Initialization
An array to store results is initialized:
```powershell
$results = @()
```

### Logging Function
`Log-Message` function is defined to log messages with timestamps. It accepts two parameters:
- `message`: The message to log.
- `type`: The type of log message (default is "INFO").
```powershell
function Log-Message {
    param (
        [string]$message,
        [string]$type = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$type] $message"
    Add-Content -Path $logFile -Value $logMessage
    Write-Output $logMessage
}
```

### nslookup Function
`Perform-Nslookup` function is defined to perform `nslookup` for a given entry (IP address or FQDN). It determines if the entry is an IP address or a hostname and extracts the corresponding information:
```powershell
function Perform-Nslookup {
    param (
        [string]$entry
    )

    try {
        $nslookupResult = nslookup $entry

        if ($entry -match '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$') {
            # Entry is an IP address
            $hostnameLine = $nslookupResult | Select-String -Pattern "Name:"
            $hostname = if ($hostnameLine) { $hostnameLine.Line.Split(" ")[-1].Trim() } else { "Not Available" }
            $ipAddress = $entry
        } else {
            # Entry is an FQDN
            $ipAddressLine = $nslookupResult | Select-String -Pattern "Address:"
            $ipAddress = if ($ipAddressLine) { $ipAddressLine.Line.Split(" ")[-1].Trim() } else { "Not Available" }
            $hostname = $entry
        }
    } catch {
        Log-Message ("Failed to perform nslookup for {0}: {1}" -f $entry, $_) "ERROR"
        if ($entry -match '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$') {
            $ipAddress = $entry
            $hostname = "Not Available"
        } else {
            $ipAddress = "Not Available"
            $hostname = $entry
        }
    }

    return [PSCustomObject]@{
        IPAddress = $ipAddress
        Hostname  = $hostname
    }
}
```

### Reading Input File
The script reads the list of IP addresses and FQDNs from the input file:
```powershell
$entries = Get-Content -Path $inputFile
```

### Processing Each Entry
The script iterates over each entry, performs `nslookup`, logs the result, and stores it in the results array:
```powershell
foreach ($entry in $entries) {
    $result = Perform-Nslookup -entry $entry
    $results += $result
    Log-Message ("Processed {0}: IP {1}, Hostname: {2}" -f $entry, $result.IPAddress, $result.Hostname)
}
```

### Exporting Results to CSV
The script attempts to export the results to a CSV file and logs the success or failure:
```powershell
try {
    $results | Export-Csv -Path $outputFile -NoTypeInformation
    Log-Message "The results have been written to $outputFile"
} catch {
    Log-Message ("Failed to write the results to CSV: {0}" -f $_) "ERROR"
}
```

### Final Log Message
The script logs the completion of the script execution:
```powershell
Log-Message "Script completed."
```

## Usage Instructions
1. Ensure you have PowerShell installed.
2. Create an `input.txt` file with a list of IP addresses and FQDNs, each on a new line.
3. Save the script to a `.ps1` file, for example, `nslookup_script.ps1`.
4. Run the script in PowerShell:
   ```powershell
   .\nslookup_script.ps1
   ```
5. Check the `output.csv` file for results and `script_log.txt` for logs.

## Example
**input.txt**
```
google.com
8.8.8.8
microsoft.com
```

**Command**
```powershell
.\nslookup_script.ps1
```

**Output**
- `output.csv`: Contains the IP addresses and hostnames.
- `script_log.txt`: Contains detailed log messages of the script execution.

---

This document outlines the purpose, functionality, and usage of the PowerShell script for performing `nslookup` operations and exporting the results to a CSV file.
