
#Récuperer les MX d'un fichier texte et tester chacune d'entre elles V2.0 (Il est tard)

#On récupere les domaines du fichier texte et on met ça en forme pour le traitement  
#Pour le fonctionnement du code veillez à mettre votre propre fichier texte
function Get-Domain {   
    foreach($line in [System.IO.File]::ReadLines("C:\Users\adm_skosbur\Documents\Scripting\mail.txt"))
    {
        
            #Write-Output $line
        try {
            $Domain = ([Net.Mail.MailAddress]$line).Host
        }
        catch {
            $Domain = ([System.Uri]$line).Host
        }

        if (($null -eq $Domain) -or ($Domain -eq "")) {$Domain = $line}
        $Domain = $Domain -replace '^www\.',''

        Write-Output $Domain
        }
 }


 
#On test la mx et on classe les preference dans l'ordre
function Get-MXConfig {
    Param (
    [string]$DomainRequest
    )
    $Domain = Get-Domain $DomainRequest

    $Subject = "TestEmailSend"
    $Body = "Test"
    $Port = "25"
   


    foreach($Domain in Get-Domain) {
    $MX = Resolve-DnsName -Type MX -Name $Domain -ErrorAction SilentlyContinue | ? Type -eq MX | Select @{L="Host"; E={$_.NameExchange}}, Preference | Sort-Object Preference 
    $MXTotal = Resolve-DnsName -Type MX -Name $Domain -ErrorAction SilentlyContinue | ? Type -eq MX | Select @{L="Host"; E={$_.NameExchange}}, Preference | Sort-Object Preference
    $SPF = Resolve-DnsName -Name $Domain -Type TXT -Erroraction SilentlyContinue | ? {$_.Strings -match "v=spf1"} | Select -ExpandProperty Strings
    

    $NbMX = 0
    
    $MXName = $MX
    Write-Host $MXName.Host 
    $NbMX = ($MX.Host).Count
    $Split = $MXName.Host 
    
    

    #write-output $MX.preferences
    #NetCo ralentie considérablement le système 


    $MXDiag = [PSCustomObject] @{
       Domain = $Domain 
       #MX = (( $MX.Host)  -join("`r`n"))
       MX = (( $MX.Host)) | Select-object -Index 0
       #MX2 = (($MX.Host)  -Split("{,}"))
       #MX = (($MX.Host) -and ($MX.Preference)  -join(' '))
       SPF = $SPF
       #Status = $NetCo
       SendMail = $Answer
       }
     Write-Host "Le nombre de MX est de $NbMX"   

        if ($NbMX > 1) {
        Write-host "----------ça passe-----------"
        
        }else{

        Write-host "Pas Besoin"
        }





     #$NetCo = TNC $MX.Host  -Port 25 -ErrorAction SilentlyContinue -InformationLevel "Quiet"
       
       if($NetCo){
       #Write-Host($Domain," ",(@($MX.Host)  -join(' ')) + " is online")
       $MXDiag | Add-Member -MemberType NoteProperty -Name Status -Value "Status Online" -Force
        
        try
        {
        write-Host "------------------------------------------Envoi de mail à $Domain -----------------------------------------------------------------------"
         
        $SMTPServer = $MX.Host
        Send-MailMessage -From "test@$Domain" -To "test@$Domain" -Subject $Subject -Body $Body -Priority High -SmtpServer $SMTPServer -Port $Port -BodyAsHtml -ErrorAction Stop

 
         write-Host "The test email was successfully sent to $Domain MX : $SMTPServer"
         $Envoi= "True"
         $MXDiag | Add-Member -MemberType NoteProperty -Name SendMail -Value $Envoi -Force
        } 
         catch { 
         Write-Host "Failed to send the email to $Domain MX : $SMTPServer"
         $EnvoiFailed = "False"
         $MXDiag | Add-Member -MemberType NoteProperty -Name SendMail -Value $EnvoiFailed -Force
        }

        }


         
         else{


           #Write-Host($Domain, " " ,(@($MX.Host)  -join(' ')) + " is not reachable")
           $MXDiag | Add-Member -MemberType NoteProperty -Name Status -Value "Status Offline" -Force
           $MXDiag | Add-Member -MemberType NoteProperty -Name SendMail -Value "False" -Force



         } 
           Write-Output $MXDiag 
        }

    }

Get-MXConfig | Format-Table -wrap

Get-MXConfig -Name ItWorks | Export-Csv -Path "C:\Users\adm_skosbur\Documents\Scripting\ItWorks.csv" -NoTypeInformation
