# Machine Detection Script (Windows PowerShell)
# Automatically detects OS and hardware info
#

function Detect-OS {
    $os = Get-WmiObject -Class Win32_OperatingSystem
    $osVersion = $os.Caption
    
    if ($osVersion -match "Windows 11") {
        return "Windows_11"
    } elseif ($osVersion -match "Windows 10") {
        return "Windows_10"
    } elseif ($osVersion -match "Windows Server") {
        return "Windows_Server"
    } else {
        return "Windows_Other"
    }
}

function Detect-Architecture {
    $arch = (Get-WmiObject -Class Win32_Processor).AddressWidth
    if ($arch -eq 64) {
        return "x86_64"
    } else {
        return "x86_32"
    }
}

function Detect-Memory {
    $memory = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory
    $memoryGB = [math]::Round($memory / 1GB)
    return $memoryGB
}

function Detect-Disk {
    $disk = Get-PSDrive C
    $freeSpace = [math]::Round($disk.Free / 1GB)
    return "$freeSpace GB"
}

# Main detection
$OS = Detect-OS
$ARCH = Detect-Architecture
$MEMORY = Detect-Memory
$DISK = Detect-Disk

# Output in JSON-like format for easy parsing
@{
    "os" = $OS
    "architecture" = $ARCH
    "memory_gb" = $MEMORY
    "free_disk" = $DISK
} | ConvertTo-Json
