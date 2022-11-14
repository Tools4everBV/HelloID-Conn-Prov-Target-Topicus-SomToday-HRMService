#####################################################
# HelloID-Conn-Prov-Target-Topicus-Somtoday-HRMService-Create
#
# Version: 1.0.0
#####################################################
# Initialize default values
$config = $configuration | ConvertFrom-Json
$p = $person | ConvertFrom-Json
$success = $false
$auditLogs = [System.Collections.Generic.List[PSCustomObject]]::new()
$now = (Get-Date).ToUniversalTime()

# Account mapping
$HRMAdres = @{
    straat               = ""
    huisnummer           = ""       #House number, Mandatory for domestic addresses, value must be present in SOMtoday-postcode list
    postcode             = ""       #Postcode number, Mandatory for domestic addresses, value must be present in SOMtoday-postcode list
    plaatsnaam           = ""
    buitenland1          = ""       #Foreign address, Mandatory for foreign addresses
    buitenland2          = ""
    buitenland3          = ""
    telefoonnummer       = ""       #Home phone number
    geheimAdres          = ""       #Secret addres,  valid values are "J"= Yes or "N" = no
    geheimTelefoonnummer = ""       #Secret phone number,  valid values are "J"= Yes or "N" = no
    landcode             = ""       #Country Code, Must be a value from the SOMtoday-county list
}

$vestigingen = [System.Collections.Generic.List[PSCustomObject]]::new()
$contractsInScope = $p.contracts | Where-Object { $_.Context.InConditions -eq $true }

if ($contractsInScope)
{
    foreach ($Contract in $contractsInScope) {
        if (-not [string]::IsNullOrEmpty($contract.StartDate)) {
            if ($contract.StartDate -gt $now){continue}
        }
        if (-not [string]::IsNullOrEmpty($contract.EndDate)) {
            if ($contract.EndDate -lt $now){continue}
        }
        $curVestiging = @{
            afkorting  = $contract.location.code
            brinnumber = $contract.location.ExternalID}
        $null = $vestigingen.add($curVestiging)
    }
}

$account = [PSCustomObject]@{
    # ExternalId          = $p.ExternalId
    medewerkerNummer          = ""                          # Auto-generated by hrm
    afkorting                 = "TEST"                      # Short name
    achternaam                = "$p.Name.FamilyName"        # Last name
    meisjesnaam               = ""                          # Maiden name
    voorletters               = ""                          # Initials (with dots?)
    voorvoegsel               = ""                          # Prefix, must be a value from the SOMtoday-prefix list
    roepnaam                  = $p.Name.GivenName           # Nickname
    voornamen                 = ""                          # First name(s)
    geslacht                  = "ONBEKEND"                  # Gender. Valid values are: "MAN", "VROUW" and "ONBEKEND"
    geboortedatum             = ""                          # Birth date  Format yyyy-MM-dd
    geboorteplaats            = ""                          # Place of Birth
    geboortelandcode          = ""                          # Country of Birth, Must be a value from the SOMtoday country list
    nationaliteitcode         = ""                          # Nationality code, Must be a value from the SOMtoday country list
    burgerlijkestaat          = ""                          # Marital status Valid values are: "Gehuwd", "Geregistreerd partnerschap", "Gescheiden", "Ongehuwd" and "Ontbonden geregistreerd partnerschap".
    # bsn = $null
    ibanNummer                = ""
    bicNummer                 = ""
    casoNummer                = ""
    HRMAdres                  = $HRMAdres
    mobielNummer              = ""                          # Mobile phone number
    internNummer              = ""                          # Internal phone number
    onderwijsPersoneel        = ""                          # Teaching staff valid values are "1"= Yes or "0" = no
    ondersteunendPersoneel    = ""                          # Suppporting staff,  valid values are "1"= Yes or "0" = no
    externMedewerkerNummer    = $($p.ExternalId)            # used as identification on update
    vestigingen               = $Vestigingen
    gebruikersnaam            = $p.UserName                 # Username, must be unique in entire organization
    wachtwoord                = ""                          # password
    email                     = $p.Accounts.MicrosoftActiveDirectory.mail                       # email address
    actief                    = "N"                         # Active  valid values are "1"= Yes or "0" = no
    functie                   = ""                          # Value must be present in SOMtoday-function list (Beheer > Instelling > Functies)
    datumInDienst             = ""                          # Date in service. Format: yyyy-MM-dd
    datumUitDienst            = ""                          # Contract end date Format: yyyy-MM-dd
    redenUitDienst            = ""                          # Contract end date reason. Value must be present in SOMtoday list (Beheer > Instelling > Redenen uit dienst)
    uitsluitenCorrespondentie = ""                          # Disable correspondence  valid values are "1"= Yes or "0" = no
}

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

# Set debug logging
switch ($($config.IsDebug)) {
    $true { $VerbosePreference = 'Continue' }
    $false { $VerbosePreference = 'SilentlyContinue' }
}

#region functions

function Get-SHA1String
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Phrase
    )
    [System.Security.Cryptography.SHA1CryptoServiceProvider] $sha1Hasher =  [System.Security.Cryptography.SHA1CryptoServiceProvider]::new()
    [byte[]] $hashedDataBytes = $sha1Hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Phrase));
    write-output $([system.convert]::ToBase64String($hashedDataBytes))

}
function Get-SoapBody
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [PSCustomObject] $Account
    )

    [system.text.StringBuilder] $soapPerson = [system.text.StringBuilder]::new()

    if(-not [string]::IsNullOrEmpty($Account.medewerkerNummer)){$temp = $soapPerson.Append("<medewerkernummer>$($Account.medewerkerNummer)</medewerkernummer>`n")}
    $temp = $soapPerson.Append("<afkorting>$($Account.afkorting)</afkorting>`n")
    $temp = $soapPerson.Append("<achternaam>$($Account.achternaam)</achternaam>`n")
    if(-not [string]::IsNullOrEmpty($Account.meisjesnaam)){$temp = $soapPerson.Append("<meisjesnaam>$($Account.meisjesnaam)</meisjesnaam>`n")}
    if(-not [string]::IsNullOrEmpty($Account.voorletters)){$temp = $soapPerson.Append("<voorletters>$($Account.voorletters)</voorletters>`n")}
    if(-not [string]::IsNullOrEmpty($Account.voorvoegsel)){$temp = $soapPerson.Append("<voorvoegsel>$($Account.voorvoegsel)</voorvoegsel>`n")}
    if(-not [string]::IsNullOrEmpty($Account.roepnaam)){$temp = $soapPerson.Append("<roepnaam>$($Account.roepnaam)</roepnaam>`n")}
    if(-not [string]::IsNullOrEmpty($Account.voornamen)){$temp = $soapPerson.Append("<voornamen>$($Account.voornamen)</voornamen>`n")}
    $temp = $soapPerson.Append("<geslacht>$($Account.geslacht)</geslacht>`n")
    if(-not [string]::IsNullOrEmpty($Account.geboortedatum)){$temp = $soapPerson.Append("<geboortedatum>$($Account.geboortedatum)</geboortedatum>`n")}
    if(-not [string]::IsNullOrEmpty($Account.geboorteplaats)){$temp = $soapPerson.Append("<geboorteplaats>$($Account.geboorteplaats)</geboorteplaats>`n")}
    if(-not [string]::IsNullOrEmpty($Account.geboortelandcode)){$temp = $soapPerson.Append("<geboortelandcode>$($Account.geboortelandcode)</geboortelandcode>`n")}
    if(-not [string]::IsNullOrEmpty($Account.nationaliteitcode)){$temp = $soapPerson.Append("<nationaliteitcode>$($Account.nationaliteitcode)</nationaliteitcode>`n")}
    if(-not [string]::IsNullOrEmpty($Account.burgerlijkestaat)){$temp = $soapPerson.Append("<burgerlijkestaat>$($Account.burgerlijkestaat)</burgerlijkestaat>`n")}
    if(-not [string]::IsNullOrEmpty($Account.ibanNummer)){$temp = $soapPerson.Append("<ibanNummer>$($Account.ibanNummer)</ibanNummer>`n")}
    if(-not [string]::IsNullOrEmpty($Account.bicNummer)){$temp = $soapPerson.Append("<bicNummer>$($Account.bicNummer)</bicNummer>`n")}
    if(-not [string]::IsNullOrEmpty($Account.casoNummer)){$temp = $soapPerson.Append("<casoNummer>$($Account.casoNummer)</casoNummer>`n")}

    $temp = $soapPerson.Append("<HRMAdres>`n")
    if(-not [string]::IsNullOrEmpty($Account.HRMAdres.straat)){$temp = $soapPerson.Append("<straat>$($Account.HRMAdres.straat)</straat>`n")}
    if(-not [string]::IsNullOrEmpty($Account.HRMAdres.huisnummer)){$temp = $soapPerson.Append("<huisnummer>$($Account.HRMAdres.huisnummer)</huisnummer>`n")}
    if(-not [string]::IsNullOrEmpty($Account.HRMAdres.postcode)){$temp = $soapPerson.Append("<postcode>$($Account.HRMAdres.postcode)</postcode>`n")}
    if(-not [string]::IsNullOrEmpty($Account.HRMAdres.plaatsnaam)){$temp = $soapPerson.Append("<plaatsnaam>$($Account.HRMAdres.plaatsnaam)</plaatsnaam>`n")}
    if(-not [string]::IsNullOrEmpty($Account.HRMAdres.buitenland1)){$temp = $soapPerson.Append("<buitenland1>$($Account.HRMAdres.buitenland1)</buitenland1>`n")}
    if(-not [string]::IsNullOrEmpty($Account.HRMAdres.buitenland2)){$temp = $soapPerson.Append("<buitenland2>$($Account.HRMAdres.buitenland2)</buitenland2>`n")}
    if(-not [string]::IsNullOrEmpty($Account.HRMAdres.buitenland3)){$temp = $soapPerson.Append("<buitenland3>$($Account.HRMAdres.buitenland3)</buitenland3>`n")}
    if(-not [string]::IsNullOrEmpty($Account.HRMAdres.telefoonnummer)){$temp = $soapPerson.Append("<telefoonnummer>$($Account.HRMAdres.telefoonnummer)</telefoonnummer>`n")}
    if(-not [string]::IsNullOrEmpty($Account.HRMAdres.geheimAdres)){$temp = $soapPerson.Append("<geheimAdres>$($Account.HRMAdres.geheimAdres)</geheimAdres>`n")}
    if(-not [string]::IsNullOrEmpty($Account.HRMAdres.geheimTelefoonnummer)){$temp = $soapPerson.Append("<geheimTelefoonnummer>$($Account.HRMAdres.geheimTelefoonnummer)</geheimTelefoonnummer>`n")}
    if(-not [string]::IsNullOrEmpty($Account.HRMAdres.landcode)){$temp = $soapPerson.Append("<landcode>$($Account.HRMAdres.landcode)</landcode>`n")}
    $temp = $soapPerson.Append("</HRMAdres>`n")

    if(-not [string]::IsNullOrEmpty($Account.mobielNummer)){$temp = $soapPerson.Append("<mobielNummer>$($Account.mobielNummer)</mobielNummer>`n")}
    if(-not [string]::IsNullOrEmpty($Account.geheimMobielNummer)){$temp = $soapPerson.Append("<geheimMobielNummer>$($Account.geheimMobielNummer)</geheimMobielNummer>`n")}
    if(-not [string]::IsNullOrEmpty($Account.internNummer)){$temp = $soapPerson.Append("<internNummer>$($Account.internNummer)</internNummer>`n")}
    if(-not [string]::IsNullOrEmpty($Account.onderwijsPersoneel)){$temp = $soapPerson.Append("<onderwijsPersoneel>$($Account.onderwijsPersoneel)</onderwijsPersoneel>`n")}
    if(-not [string]::IsNullOrEmpty($Account.ondersteunendPersoneel)){$temp = $soapPerson.Append("<ondersteunendPersoneel>$($Account.ondersteunendPersoneel)</ondersteunendPersoneel>`n")}
    if(-not [string]::IsNullOrEmpty($Account.externMedewerkerNummer)){$temp = $soapPerson.Append("<externMedewerkerNummer>$($Account.externMedewerkerNummer)</externMedewerkerNummer>`n")}

    foreach ($Vestiging in  $Account.vestigingen)
    {
        $temp = $soapPerson.Append("<Vestigingen>`n")
        $temp = $soapPerson.Append("<afkorting>$($Vestiging.afkorting)</afkorting>`n")
        if(-not [string]::IsNullOrEmpty($Vestiging.brinNummer)){$temp = $soapPerson.Append("<brinNummer>$($Vestiging.brinNummer)</brinNummer>`n")}
        $temp = $soapPerson.Append("</Vestigingen>`n")
    }
    if(-not [string]::IsNullOrEmpty($Account.gebruikersnaam)){$temp = $soapPerson.Append("<gebruikersnaam>$($Account.gebruikersnaam)</gebruikersnaam>`n")}
    if(-not [string]::IsNullOrEmpty($Account.wachtwoord)){$temp = $soapPerson.Append("<wachtwoord>$($Account.wachtwoord)</wachtwoord>`n")}
    if(-not [string]::IsNullOrEmpty($Account.email)){$temp = $soapPerson.Append("<email>$($Account.email)</email>`n")}
    if(-not [string]::IsNullOrEmpty($Account.functie)){$temp = $soapPerson.Append("<functie>$($Account.functie)</functie>`n")}
    if(-not [string]::IsNullOrEmpty($Account.datumInDienst)){$temp = $soapPerson.Append("<datumInDienst>$($Account.datumInDienst)</datumInDienst>`n")}
    if(-not [string]::IsNullOrEmpty($Account.datumUitDienst)){$temp = $soapPerson.Append("<datumUitDienst>$($Account.datumUitDienst)</datumUitDienst>`n")}
    if(-not [string]::IsNullOrEmpty($Account.redenUitDienst)){$temp = $soapPerson.Append("<redenUitDienst>$($Account.meisjesnaam)</redenUitDienst>`n")}
    if(-not [string]::IsNullOrEmpty($Account.uitsluitenCorrespondentie)){$temp = $soapPerson.Append("<uitsluitenCorrespondentie>$($Account.uitsluitenCorrespondentie)</uitsluitenCorrespondentie>`n")}

    [string] $soapbody = @"
    <hrm:createPerson>
        <HRMperson>
        $($soapPerson.ToString())
        </HRMperson>
    </hrm:createPerson>
"@

    Write-Output $soapbody
}
function Get-SoapHeader
{
    [DateTime] $created = [DateTime]::Now.ToUniversalTime()
    [string] $createdStr = $created.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    [string] $phrase = [Guid]::NewGuid().ToString();
    [string] $nonce = Get-SHA1String($phrase);
    $Header = @"
    <wsse:Security soapenv:mustUnderstand="1" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
        <wsse:UsernameToken wsu:Id="UsernameToken - 1AEA5E598817F48387146183029981292 ">
            <wsse:Username> $($config.UserName)</wsse:Username>
            <wsse:Password Type= "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">$($config.Password)</wsse:Password>
            <wsse:Nonce EncodingType= "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">$nonce</wsse:Nonce>
            <wsu:Created>$createdStr</wsu:Created>
        </wsse:UsernameToken>
    </wsse:Security>
    <auth:Brinnummer xmlns:auth="http://hrm.koppelingen.iridium.topicus.nl/">$($config.BrinNr)</auth:Brinnummer>
"@
    Write-Output $Header

}

function Resolve-Topicus-Somtoday-HRMServiceError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]
        $ErrorObject
    )
    process {
        $httpErrorObj = [PSCustomObject]@{
            ScriptLineNumber = $ErrorObject.InvocationInfo.ScriptLineNumber
            Line             = $ErrorObject.InvocationInfo.Line
            ErrorDetails     = ''
            FriendlyMessage  = ''
        }
        if ($ErrorObject.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') {
            $httpErrorObj.ErrorDetails = $ErrorObject.ErrorDetails.Message
        } elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
            if ($null -eq $ErrorObject.Exception.Response) {
                $httpErrorObj.ErrorDetails = $ErrorObject.Exception.Message
                $httpErrorObj.FriendlyMessage = $ErrorObject.Exception.Message
            }
            $streamReaderResponse = [System.IO.StreamReader]::new($ErrorObject.Exception.Response.GetResponseStream()).ReadToEnd()
            $httpErrorObj.ErrorDetails = $streamReaderResponse
            $httpErrorObj.FriendlyMessage = $streamReaderResponse   #Todo:  modify response to make the message friendly for the user.
        }
        Write-Output $httpErrorObj
    }
}
#endregion

# Begin
try {
    $action = "Create/update"

    # Add a warning message showing what will happen during enforcement
    if ($dryRun -eq $true) {
        Write-Warning "[DryRun] $action Topicus-Somtoday-HRMService account for: [$($p.DisplayName)], will be executed during enforcement"
    }
    # Process

    $splatRestMethodParams = @{
        Uri         = $($config.BaseUrl)
        Method      = 'POST'
        ContentType = "text/xml; charset=utf-8"
    }
    if (-not  [string]::IsNullOrEmpty($config.ProxyAddress)) {
        $splatRestMethodParams['Proxy'] = $config.ProxyAddress
    }

    $SoapHeader = Get-SoapHeader
    $SoapBody = Get-SoapBody -account $account

    $createPersonXmlBody = @"
<soapenv:Envelope xmlns:hrm="http://hrm.webservices.iridium.topicus.nl/" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
    <soapenv:Header>
        $SoapHeader
    </soapenv:Header>
    <soapenv:Body>
        $SoapBody
    </soapenv:Body>
</soapenv:Envelope>
"@
    $splatRestMethodParams['Body'] = $createPersonXmlBody
    $responseCreatePerson = Invoke-RestMethod @splatRestMethodParams -Verbose:$false

    $success = $true
    $accountReference = $account.externMedewerkerNummer
    $auditLogs.Add([PSCustomObject]@{
            Message = "$action account was successful. AccountReference is: [$accountReference]"
            IsError = $false
        })

} catch {
    $success = $false
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
        $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-Topicus-Somtoday-HRMServiceError -ErrorObject $ex
        $auditMessage = "Could not $action Topicus-Somtoday-HRMService account. Error: $($errorObj.FriendlyMessage)"
        Write-Verbose "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
    } else {
        $auditMessage = "Could not $action Topicus-Somtoday-HRMService account. Error: $($ex.Exception.Message)"
        Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    }
    $auditLogs.Add([PSCustomObject]@{
            Message = $auditMessage
            IsError = $true
        })
# End
} finally {

    $dataStorage = @{
        Permissions = $vestigingen
    }
    $result = [PSCustomObject]@{
        Success          = $success
        AccountReference = $accountReference
        Auditlogs        = $auditLogs
        Account          = $account
        DataStorage    = $dataStorage
    }
    Write-Output $result | ConvertTo-Json -Depth 10
}
