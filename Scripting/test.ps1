$MXS = Resolve-DnsName -Type MX -Name "esdown.fr" -ErrorAction SilentlyContinue | ? Type -eq MX | Select @{L="Host"; E={$_.NameExchange}}, Preference | Sort-Object Preference 
Remove-Item "C:\Users\ASUS\Desktop\Nouveau dossier\ItWorks.csv"

foreach($MX in $MXS.Host) {
    Write-Host $MX

    $MXDiag = [PSCustomObject] @{
        Domain = "esdown.fr"
        MX = $MX
        SendMail = "False"
    }

    Write-Output $MXDiag | Export-Csv -Path "C:\Users\ASUS\Desktop\Nouveau dossier\ItWorks.csv" -NoTypeInformation -Append
}