
#Récuperer les MX d'un fichier texte et tester chacune d'entre elles

#On récupere les domaines du fichier .txt et on met ça en forme pour le traitement  
#Pour le fonctionnement du code veillez à mettre votre propre fichier texte avec tout les domaines lignes par lignes

#Definir le fichier d'entrée et de sortie
$EntryPath = "C:\Users\adm_skosbur\Documents\GIT\MX-2\Scripting\mail.txt"
$EndPath = "C:\Users\adm_skosbur\Documents\GIT\MX-2\Scripting\ItWorks.csv"


#Lecture du fichier .txt
function Get-Domain { 
    
    #Fichier d'entrée     
    foreach($line in [System.IO.File]::ReadLines($EntryPath))
    {
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


 
#On test la mx et l'envoi de mails à chacune d'entre elles
function Get-MXConfig {
    Param (
    [string]$DomainRequest
    )
    $Domain = Get-Domain $DomainRequest

    $Subject = "TestEmailSend"
    $Body = "Test"
    $Port = "25"

    foreach($Domain in Get-Domain) { 
    $MXTotal =  Resolve-DnsName -Type MX -Name $Domain -ErrorAction SilentlyContinue | ? Type -eq MX | Select @{L="Host"; E={$_.NameExchange}}, Preference | Sort-Object Preference 
    $SPF = Resolve-DnsName -Name $Domain -Type TXT -Erroraction SilentlyContinue | ? {$_.Strings -match "v=spf1"} | Select -ExpandProperty Strings
 
    
     
     #Si pas de MX alors remplacement du champ MX par NULL
     if ($MXTotal -eq $null) {
     $MXTotal = "NULL"
      }
 
    foreach($MX in $MXTotal) {

    #Si la MX est NULL alors on n'effectue pas de TNC sur la MX
    if ($MXTotal -notlike "NULL") {
     $NetCo = TNC $MX.Host  -Port 25 -ErrorAction SilentlyContinue -InformationLevel "Quiet"
      }

     else{
     $NetCo = $false
     }
     write-host "---------------------------------------Contact $NetCo pour le domaine $Domain-----------------------------------------------------------------"

    $MXDiag = [PSCustomObject] @{
       Domain = $Domain 
       MX = (($MX.Host),($MX.Preference) -join " ")
       SPF = $SPF
       }  
       
       #Si $NetCo = True alors envoi d'un mail et repercution des resultats dans le CSV
       if($NetCo ){
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

        }else{

           $MXDiag | Add-Member -MemberType NoteProperty -Name Status -Value "Status Offline" -Force
           $MXDiag | Add-Member -MemberType NoteProperty -Name SendMail -Value "False" -Force

         }
         Write-Output $MXDiag
        }
         
        }
      
    }

     #Conversion vers un CSV
Get-MXConfig | Export-Csv -Path $EndPath -NoTypeInformation
 
