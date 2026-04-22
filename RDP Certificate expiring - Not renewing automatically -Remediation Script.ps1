#REMEDIATION-SCRIPT
# ==============================

# Regenerate and Bind RDP Certificate

# Tested for Cloud PC / RDS / AVD

# Run as SYSTEM (Intune)

# ==============================

$ErrorActionPreference = "Stop"

try {

    Write-Output "Starting RDP certificate regeneration..."

    # Set DNS name (use computer name if unsure)

    $DnsName = $env:COMPUTERNAME
 
    # Create self-signed certificate in LocalMachine\RemoteDesktop

    $cert = New-SelfSignedCertificate `

        -DnsName $DnsName `

        -CertStoreLocation "Cert:\LocalMachine\My" `

        -KeySpec KeyExchange `

        -NotAfter (Get-Date).AddYears(2)

    if (-not $cert) {

        throw "Failed to create self-signed certificate"

    }

    $rdStore = New-Object System.Security.Cryptography.X509Certificates.X509Store("Remote Desktop","LocalMachine")

    $rdStore.Open("ReadWrite")

    $rdStore.Add($cert)

    $rdStore.Close()

    $thumbprint = $cert.Thumbprint

    # Bind certificate to RDP service
    Write-Output "Binding certificate to RDP listener..."
    $ts = Get-WmiObject -Namespace 'root\cimv2\TerminalServices' `
    -Class Win32_TSGeneralSetting `
    -Filter "TerminalName='RDP-tcp'"
 
    $ts.SSLCertificateSHA1Hash = $thumbprint
    $ts.Put() | Out-Null # only works if cert is in Personal Store 

    $cert | Remove-Item

    Write-Output "Certificate created successfully and binded - cert deleted from personal store, copy made to remote desktop store"

    Write-Output "Thumbprint: $thumbprint"  

    # Restart RDP service to force reload

    Write-Output "Restarting Remote Desktop Services..."

    Restart-Service TermService -Force

    Write-Output "RDP certificate regeneration and binding completed successfully"

}

catch {

    Write-Error "RDP certificate remediation failed: $_"

    exit 1

}

 
