# Define the input and output file paths
$inputFile = "input.txt"
$outputFile = "output.csv"
$logFile = "script_log.txt"

# Clear previous logs
Clear-Content -Path $logFile -ErrorAction SilentlyContinue

# Initialize an array to hold the results
$results = @()

# Function to log messages
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

# Function to perform nslookup
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

# Read the list of IP addresses and FQDNs from the input file
$entries = Get-Content -Path $inputFile

# Perform nslookup for each entry
foreach ($entry in $entries) {
    $result = Perform-Nslookup -entry $entry
    $results += $result
    Log-Message ("Processed {0}: IP {1}, Hostname: {2}" -f $entry, $result.IPAddress, $result.Hostname)
}

# Export the results to a CSV file
try {
    $results | Export-Csv -Path $outputFile -NoTypeInformation
    Log-Message "The results have been written to $outputFile"
} catch {
    Log-Message ("Failed to write the results to CSV: {0}" -f $_) "ERROR"
}

Log-Message "Script completed."
