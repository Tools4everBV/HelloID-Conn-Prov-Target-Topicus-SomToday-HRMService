#####################################################
# HelloID-Conn-Prov-Target-Topicus-Somtoday-HRMService-Create
#
# Version: 2.0.0
#####################################################
# Initialize default values
$config = $configuration | ConvertFrom-Json
$p = $person | ConvertFrom-Json
$success = $false
$auditLogs = [System.Collections.Generic.List[PSCustomObject]]::new()
$now = (Get-Date).ToUniversalTime()



# Set TLS to accept TLS, TLS 1.1 and TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

# Set debug logging
switch ($($config.IsDebug)) {
    $true { $VerbosePreference = 'Continue' }
    $false { $VerbosePreference = 'SilentlyContinue' }
}

#region functions
function Get-RandomCharacters([int]$length, $characters) {
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length } 
    $ofs = "" 
    return [String]$characters[$random]
}
#region Support Functions
function New-RandomPassword() {
    #passwordSpecifications:
    $length = 8
    $upper = 2
    $number = 2
    $special = 2
    $lower = $length - $upper - $number - $special
      
    $chars = "abcdefghkmnprstuvwxyz"
    $NumberPool = "23456789"
    $specialPool = "!#%^*()"

    $CharPoolLower = $chars.ToLower()
    $CharPoolUpper = $chars.ToUpper()

    $password = Get-RandomCharacters -characters $CharPoolUpper -length $upper
    $password += Get-RandomCharacters -characters $NumberPool -length $number
    $password += Get-RandomCharacters -characters $specialPool -length $special
    $password += Get-RandomCharacters -characters $CharPoolLower -length $Lower

    $passwordArray = $password.ToCharArray()   
    $passwordScrambledArray = $passwordArray | Get-Random -Count $passwordArray.Length     
    $password = -join $passwordScrambledArray

    return $password
}

function Resolve-HTTPError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline
        )]
        [object]$ErrorObject
    )
    process {
        $httpErrorObj = [PSCustomObject]@{
            FullyQualifiedErrorId = $ErrorObject.FullyQualifiedErrorId
            MyCommand             = $ErrorObject.InvocationInfo.MyCommand
            RequestUri            = $ErrorObject.TargetObject.RequestUri
            ScriptStackTrace      = $ErrorObject.ScriptStackTrace
            ErrorMessage          = ''
        }
        if ($ErrorObject.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') {
            $httpErrorObj.ErrorMessage = $ErrorObject.ErrorDetails.Message
        }
        elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
            $httpErrorObj.ErrorMessage = [System.IO.StreamReader]::new($ErrorObject.Exception.Response.GetResponseStream()).ReadToEnd()
        }
        Write-Output $httpErrorObj
    }
}

function Get-SHA1String {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Phrase
    )
    [System.Security.Cryptography.SHA1CryptoServiceProvider] $sha1Hasher = [System.Security.Cryptography.SHA1CryptoServiceProvider]::new()
    [byte[]] $hashedDataBytes = $sha1Hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Phrase));
    write-output $([system.convert]::ToBase64String($hashedDataBytes))

}




function Get-SoapBody {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [PSCustomObject] $Account
    )

    [system.text.StringBuilder] $soapPerson = [system.text.StringBuilder]::new()

    if (-not [string]::IsNullOrEmpty($Account.medewerkerNummer)) { $temp = $soapPerson.Append("<medewerkernummer>$($Account.medewerkerNummer)</medewerkernummer>`n") }
    $temp = $soapPerson.Append("<afkorting>$($Account.afkorting)</afkorting>`n")
    $temp = $soapPerson.Append("<achternaam>$($Account.achternaam)</achternaam>`n")
    #if (-not [string]::IsNullOrEmpty($Account.meisjesnaam)) { $temp = $soapPerson.Append("<meisjesnaam>$($Account.meisjesnaam)</meisjesnaam>`n") }
    $temp = $soapPerson.Append("<meisjesnaam>$($Account.meisjesnaam)</meisjesnaam>`n")
    if (-not [string]::IsNullOrEmpty($Account.voorletters)) { $temp = $soapPerson.Append("<voorletters>$($Account.voorletters)</voorletters>`n") }
    if (-not [string]::IsNullOrEmpty($Account.voorvoegsel)) { $temp = $soapPerson.Append("<voorvoegsel>$($Account.voorvoegsel)</voorvoegsel>`n") }
    if (-not [string]::IsNullOrEmpty($Account.roepnaam)) { $temp = $soapPerson.Append("<roepnaam>$($Account.roepnaam)</roepnaam>`n") }
    if (-not [string]::IsNullOrEmpty($Account.voornamen)) { $temp = $soapPerson.Append("<voornamen>$($Account.voornamen)</voornamen>`n") }
    $temp = $soapPerson.Append("<geslacht>$($Account.geslacht)</geslacht>`n")
    if (-not [string]::IsNullOrEmpty($Account.geboortedatum)) { $temp = $soapPerson.Append("<geboortedatum>$($Account.geboortedatum)</geboortedatum>`n") }
    if (-not [string]::IsNullOrEmpty($Account.geboorteplaats)) { $temp = $soapPerson.Append("<geboorteplaats>$($Account.geboorteplaats)</geboorteplaats>`n") }
    if (-not [string]::IsNullOrEmpty($Account.geboortelandcode)) { $temp = $soapPerson.Append("<geboortelandcode>$($Account.geboortelandcode)</geboortelandcode>`n") }
    if (-not [string]::IsNullOrEmpty($Account.nationaliteitcode)) { $temp = $soapPerson.Append("<nationaliteitcode>$($Account.nationaliteitcode)</nationaliteitcode>`n") }
    if (-not [string]::IsNullOrEmpty($Account.burgerlijkestaat)) { $temp = $soapPerson.Append("<burgerlijkestaat>$($Account.burgerlijkestaat)</burgerlijkestaat>`n") }
    if (-not [string]::IsNullOrEmpty($Account.ibanNummer)) { $temp = $soapPerson.Append("<ibanNummer>$($Account.ibanNummer)</ibanNummer>`n") }
    if (-not [string]::IsNullOrEmpty($Account.bicNummer)) { $temp = $soapPerson.Append("<bicNummer>$($Account.bicNummer)</bicNummer>`n") }
    if (-not [string]::IsNullOrEmpty($Account.casoNummer)) { $temp = $soapPerson.Append("<casoNummer>$($Account.casoNummer)</casoNummer>`n") }

    $temp = $soapPerson.Append("<HRMAdres>`n")
    if (-not [string]::IsNullOrEmpty($Account.HRMAdres.straat)) { $temp = $soapPerson.Append("<straat>$($Account.HRMAdres.straat)</straat>`n") }
    if (-not [string]::IsNullOrEmpty($Account.HRMAdres.huisnummer)) { $temp = $soapPerson.Append("<huisnummer>$($Account.HRMAdres.huisnummer)</huisnummer>`n") }
    if (-not [string]::IsNullOrEmpty($Account.HRMAdres.postcode)) { $temp = $soapPerson.Append("<postcode>$($Account.HRMAdres.postcode)</postcode>`n") }
    if (-not [string]::IsNullOrEmpty($Account.HRMAdres.plaatsnaam)) { $temp = $soapPerson.Append("<plaatsnaam>$($Account.HRMAdres.plaatsnaam)</plaatsnaam>`n") }
    if (-not [string]::IsNullOrEmpty($Account.HRMAdres.buitenland1)) { $temp = $soapPerson.Append("<buitenland1>$($Account.HRMAdres.buitenland1)</buitenland1>`n") }
    if (-not [string]::IsNullOrEmpty($Account.HRMAdres.buitenland2)) { $temp = $soapPerson.Append("<buitenland2>$($Account.HRMAdres.buitenland2)</buitenland2>`n") }
    if (-not [string]::IsNullOrEmpty($Account.HRMAdres.buitenland3)) { $temp = $soapPerson.Append("<buitenland3>$($Account.HRMAdres.buitenland3)</buitenland3>`n") }
    if (-not [string]::IsNullOrEmpty($Account.HRMAdres.telefoonnummer)) { $temp = $soapPerson.Append("<telefoonnummer>$($Account.HRMAdres.telefoonnummer)</telefoonnummer>`n") }
    if (-not [string]::IsNullOrEmpty($Account.HRMAdres.geheimAdres)) { $temp = $soapPerson.Append("<geheimAdres>$($Account.HRMAdres.geheimAdres)</geheimAdres>`n") }
    if (-not [string]::IsNullOrEmpty($Account.HRMAdres.geheimTelefoonnummer)) { $temp = $soapPerson.Append("<geheimTelefoonnummer>$($Account.HRMAdres.geheimTelefoonnummer)</geheimTelefoonnummer>`n") }
    if (-not [string]::IsNullOrEmpty($Account.HRMAdres.landcode)) { $temp = $soapPerson.Append("<landcode>$($Account.HRMAdres.landcode)</landcode>`n") }
    $temp = $soapPerson.Append("</HRMAdres>`n")

    if (-not [string]::IsNullOrEmpty($Account.mobielNummer)) { $temp = $soapPerson.Append("<mobielNummer>$($Account.mobielNummer)</mobielNummer>`n") }
    if (-not [string]::IsNullOrEmpty($Account.geheimMobielNummer)) { $temp = $soapPerson.Append("<geheimMobielNummer>$($Account.geheimMobielNummer)</geheimMobielNummer>`n") }
    if (-not [string]::IsNullOrEmpty($Account.internNummer)) { $temp = $soapPerson.Append("<internNummer>$($Account.internNummer)</internNummer>`n") }
    if (-not [string]::IsNullOrEmpty($Account.onderwijsPersoneel)) { $temp = $soapPerson.Append("<onderwijsPersoneel>$($Account.onderwijsPersoneel)</onderwijsPersoneel>`n") }
    if (-not [string]::IsNullOrEmpty($Account.ondersteunendPersoneel)) { $temp = $soapPerson.Append("<ondersteunendPersoneel>$($Account.ondersteunendPersoneel)</ondersteunendPersoneel>`n") }
    if (-not [string]::IsNullOrEmpty($Account.externMedewerkerNummer)) { $temp = $soapPerson.Append("<externMedewerkerNummer>$($Account.externMedewerkerNummer)</externMedewerkerNummer>`n") }

    foreach ($Vestiging in  $Account.vestigingen) {
        $temp = $soapPerson.Append("<vestigingen>`n")   
        $temp = $soapPerson.Append("<afkorting>$($Vestiging.afkorting)</afkorting>`n")
        if (-not [string]::IsNullOrEmpty($Vestiging.brinNummer)) { $temp = $soapPerson.Append("<brinNummer>$($Vestiging.brinNummer)</brinNummer>`n") }
        $temp = $soapPerson.Append("</vestigingen>`n")
    }

    if (-not [string]::IsNullOrEmpty($Account.gebruikersnaam)) { $temp = $soapPerson.Append("<gebruikersnaam>$($Account.gebruikersnaam)</gebruikersnaam>`n") }
    if (-not [string]::IsNullOrEmpty($Account.wachtwoord)) { $temp = $soapPerson.Append("<wachtwoord>$($Account.wachtwoord)</wachtwoord>`n") }
    if (-not [string]::IsNullOrEmpty($Account.email)) { $temp = $soapPerson.Append("<email>$($Account.email)</email>`n") }
    if (-not [string]::IsNullOrEmpty($Account.functie)) { $temp = $soapPerson.Append("<functie>$($Account.functie)</functie>`n") }
    if (-not [string]::IsNullOrEmpty($Account.datumInDienst)) { $temp = $soapPerson.Append("<datumInDienst>$($Account.datumInDienst)</datumInDienst>`n") }
    if (-not [string]::IsNullOrEmpty($Account.datumUitDienst)) { $temp = $soapPerson.Append("<datumUitDienst>$($Account.datumUitDienst)</datumUitDienst>`n") }
    if (-not [string]::IsNullOrEmpty($Account.redenUitDienst)) { $temp = $soapPerson.Append("<redenUitDienst>$($Account.redenUitDienst)</redenUitDienst>`n") }
    if (-not [string]::IsNullOrEmpty($Account.uitsluitenCorrespondentie)) { $temp = $soapPerson.Append("<uitsluitenCorrespondentie>$($Account.uitsluitenCorrespondentie)</uitsluitenCorrespondentie>`n") }

    [string] $soapbody = @"
    <createPerson xmlns="http://hrm.webservices.iridium.topicus.nl/">
        <HRMperson xmlns="">
        $($soapPerson.ToString())
        </HRMperson>
    </createPerson>
"@

    Write-Output $soapbody
}
function Get-SoapHeader {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $brincode
    )
    [DateTime] $created = [DateTime]::Now.ToUniversalTime()
    [string] $createdStr = $created.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    [string] $phrase = [Guid]::NewGuid().ToString();
    [string] $nonce = Get-SHA1String($phrase);

    if ($brincode.Length -ne 6) {
        Throw "brin is invalid length (6)"
    }

    $brincode4 = $brincode.Substring(0, 4)

    $Header = @"
    <Security xmlns="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
        <UsernameToken wsu:Id="UsernameToken - 1AEA5E598817F48387146183029981292" xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">
            	<Username>$($config.SomHrmUserName)</Username>
            <Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">$($config.SomHrmPassword)</Password>
            <Nonce EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">$nonce</Nonce>
			<Created>
            $createdStr</Created>
			</UsernameToken>
		</Security>
		<Brinnummer xmlns="http://hrm.koppelingen.iridium.topicus.nl/">$brincode4</Brinnummer>
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
        }
        elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
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

function Generate-MiddleName {
    [cmdletbinding()]
    Param (
        [object]$person
    )
    try {
        $FamilyNamePrefix = $person.Name.FamilyNamePrefix 
        $PartnerNamePrefix = $person.Name.FamilyNamePartnerPrefix
        $convention = $person.Name.Convention

        $middlename = ""
        switch ($convention) {
            "B" {
                $middlename = $FamilyNamePrefix;
            }
            "P" {
                $middlename = $PartnerNamePrefix;                 
            }
            "BP" {
                $middlename = $FamilyNamePrefix;
            }
            "PB" {
                $middlename = $PartnerNamePrefix;   
            }
            Default {
                $middlename = $FamilyNamePrefix;
            }
        }

        return $middlename
    }
    catch {
        throw("An error was found in the name convention algorithm: $($_.Exception.Message): $($_.ScriptStackTrace)")
    
    }
}

function Generate-LastName {
    [cmdletbinding()]
    Param (
        [object]$person
    )

    try {
        $suffix = "";
        $givenname = if ([string]::IsNullOrEmpty($person.Name.Nickname)) { $person.Name.Initials.Substring(0, 1) }else { $person.Name.Nickname }
        $FamilyNamePrefix = $person.Name.FamilyNamePrefix
        $FamilyName = $person.Name.FamilyName           
        $PartnerNamePrefix = $person.Name.FamilyNamePartnerPrefix
        $PartnerName = $person.Name.FamilyNamePartner 
        $convention = $person.Name.Convention

        $LastName = ""

        switch ($convention) {
            "B" {
                #  $LastName += if (-NOT([string]::IsNullOrEmpty($FamilyNamePrefix))) { $FamilyNamePrefix + " " }
                $LastName += $FamilyName  
            }
            "P" {
                #   $LastName += if (-NOT([string]::IsNullOrEmpty($FamilyNamePrefix))) { $FamilyNamePrefix + " " }
                $LastName += $PartnerName                    
            }
            "BP" {
                #   $LastName += if (-NOT([string]::IsNullOrEmpty($FamilyNamePrefix))) { $FamilyNamePrefix + " " }
                $LastName += $FamilyName + " - "
                $LastName += if (-NOT([string]::IsNullOrEmpty($PartnerNamePrefix))) { $PartnerNamePrefix + " " }
                $LastName += $PartnerName
            }
            "PB" {
                #   $LastName += if (-NOT([string]::IsNullOrEmpty($PartnerNamePrefix))) { $PartnerNamePrefix + " " }
                $LastName += $PartnerName + " - "
                $LastName += if (-NOT([string]::IsNullOrEmpty($FamilyNamePrefix))) { $FamilyNamePrefix + " " }
                $LastName += $FamilyName
            }
            Default {
                #   $LastName += if (-NOT([string]::IsNullOrEmpty($FamilyNamePrefix))) { $FamilyNamePrefix + " " }
                $LastName += $FamilyName

            }
        }
        return $LastName
            
    }
    catch {
        throw("An error was found in the name convention algorithm: $($_.Exception.Message): $($_.ScriptStackTrace)")
    } 
}

function Generate-Gender {
    [cmdletbinding()]
    Param (
        [object]$person
    )

    try {
        $gender = $person.Details.Gender

        switch ($gender) {
            "M" {
                $gender = "MAN"
                break;
            }
            "V" {
                $gender = "VROUW"                
            }
            Default {
                $gender = "ONBEKEND"
            }
        }
        return $gender
    }
    catch {
        throw("An error was found in the name convention algorithm: $($_.Exception.Message): $($_.ScriptStackTrace)")
    } 
}

function format-date {
    [CmdletBinding()]
    Param
    (
        [string]$date,
        [string]$InputFormat,
        [string]$OutputFormat
    )
    try {
        if (-NOT([string]::IsNullOrEmpty($date))) {    
            $dateString = get-date([datetime]::ParseExact($date, $InputFormat, $null)) -Format($OutputFormat)
        }
        else {
            $dateString = $null
        }

        return $dateString
    }
    catch {
        throw("An error was thrown while formatting date: $($_.Exception.Message): $($_.ScriptStackTrace)")
    }
    
}

#endregion

# Begin
try {    
    # Account mapping
    $HRMAdres = @{
        straat               = ""
        huisnummer           = "1A"       #House number, Mandatory for domestic addresses, value must be present in SOMtoday-postcode list
        postcode             = "1234AB"       #Postcode number, Mandatory for domestic addresses, value must be present in SOMtoday-postcode list
        plaatsnaam           = ""
        buitenland1          = ""       #Foreign address, Mandatory for foreign addresses
        buitenland2          = ""
        buitenland3          = ""
        telefoonnummer       = ""       #Home phone number
        geheimAdres          = ""       #Secret addres,  valid values are "J"= Yes or "N" = no
        geheimTelefoonnummer = ""       #Secret phone number,  valid values are "J"= Yes or "N" = no
        landcode             = "6030"       #Country Code, Must be a value from the SOMtoday-county list
    }

    $vestigingen = [System.Collections.Generic.List[PSCustomObject]]::new()


    $curVestiging = @{
        afkorting  = $p.primarycontract.custom.schoolBrinCode
        brinNummer = $p.primarycontract.custom.schoolBrinCode
    }
    $vestigingen.add($curVestiging)


    $account = [PSCustomObject]@{
        #medewerkerNummer          = $p.externalID                       # Auto-generated by hrm
        afkorting              = $p.externalID                    # Short name (MANDATORY)
        achternaam             = Generate-LastName -person $p       # Last name
        meisjesnaam            = ""                          # Maiden name
        voorletters            = $p.name.initials                          # Initials (with dots?)
        voorvoegsel            = Generate-MiddleName -person $p     # Prefix, must be a value from the SOMtoday-prefix list
        roepnaam               = $p.name.Nickname   # Nickname
        #NIET voornamen                 = ""                          # First name(s)
        geslacht               = Generate-Gender $p                 # Gender. Valid values are: "MAN", "VROUW" and "ONBEKEND"
        #NIET geboortedatum             = ""                          # Birth date  Format yyyy-MM-dd
        #NIET geboorteplaats            = ""                          # Place of Birth
        #NIET geboortelandcode          = ""                          # Country of Birth, Must be a value from the SOMtoday country list
        #NIET nationaliteitcode         = ""                          # Nationality code, Must be a value from the SOMtoday country list
        #NIET burgerlijkestaat          = ""                          # Marital status Valid values are: "Gehuwd", "Geregistreerd partnerschap", "Gescheiden", "Ongehuwd" and "Ontbonden geregistreerd partnerschap".
        #NIET bsn = $null
        #NIET ibanNummer                = ""
        #NIET bicNummer                 = ""
        #NIET casoNummer                = ""
        HRMAdres               = $HRMAdres
        #NIET mobielNummer              = ""                          # Mobile phone number
        internNummer           = "HelloID"                          # Internal phone number
        #NIET onderwijsPersoneel        = ""                          # Teaching staff valid values are "1"= Yes or "0" = no
        #NIET ondersteunendPersoneel    = ""                          # Suppporting staff,  valid values are "1"= Yes or "0" = no
        externMedewerkerNummer = $p.externalID       # used as identification on update
        vestigingen            = $Vestigingen
        gebruikersnaam         = $p.accounts.MicrosoftActiveDirectory.userprincipalname.split("@")[0]            # Username, must be unique in entire organization
        wachtwoord             = New-RandomPassword                      # password
        email                  = $p.accounts.MicrosoftActiveDirectory.mail          # email address
        #actief                    = "N"                         # Active  valid values are "1"= Yes or "0" = no
        functie                = $p.PrimaryContract.custom.somtodayTitleDescription -replace ("&", "&amp;")                       # Value must be present in SOMtoday-function list (Beheer > Instelling > Functies)
        datumInDienst          = format-date -date $p.PrimaryContract.StartDate  -InputFormat 'yyyy-MM-ddThh:mm:ssZ' -OutputFormat "yyyy-MM-dd"                          # Date in service. Format: yyyy-MM-dd
        datumUitDienst         = $null
        redenUitDienst         = $null                       # Contract end date reason. Value must be present in SOMtoday list (Beheer > Instelling > Redenen uit dienst)
        #   uitsluitenCorrespondentie = ""                          # Disable correspondence  valid values are "1"= Yes or "0" = no
    }
    
    if (-NOT[string]::IsNullOrEmpty($p.PrimaryContract.EndDate)) {
        if ($(get-date $p.PrimaryContract.EndDate) -le $(get-date)) {
            $account.datumUitDienst = format-date -date $p.PrimaryContract.EndDate  -InputFormat 'yyyy-MM-ddThh:mm:ssZ' -OutputFormat "yyyy-MM-dd"                          # Contract end date Format: yyyy-MM-dd
            $account.redenUitDienst = "Uit dienst"
        }
    }

    try {
        Write-Verbose "Retrieving Somtoday organizationUUID's"
        $splatRestParams = @{
            Method = 'GET'
            Uri    = "$($config.ConnectBaseUrl)/rest/v1/connect/instelling"
        }
        $responseOrganizations = Invoke-RestMethod @splatRestParams -verbose:$false
        $organization = $responseOrganizations.instellingen.Where({ $_.naam -eq "$($config.Connectorganization)" })

        if ([string]::isNullOrEmpty($organization.uuid)) {
            Throw "Failed to retrieve organization: uuid is missing or not found"
        }

        Write-Verbose "found uuid $($organization.uuid) for organisation $($config.Connectorganization)"

        $splatRestParams = @{
            Method          = 'POST'
            Uri             = "https://connectors.helloid.cloud/service/proxy/api/connector/somtoday/oauth2/token?organisation=$($organization.uuid)"
            body            = "client_id=$($config.ConnectClientId)&client_secret=$($config.ConnectClientSecret)&grant_type=client_credentials"
            UseBasicParsing = $true
        }

        $responseToken = Invoke-RestMethod @splatRestParams -verbose:$false

        if ([string]::isNullOrEmpty($responseToken)) {
            Throw "Failed to retrieve token - tonen response is missing"
        }

        Write-Verbose 'Adding authorizationToken to headers'
        $headers = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
        $headers.Add("Authorization", "Bearer $($responseToken.access_token)")

        $splatRestParams = @{
            Method          = 'GET'
            Uri             = "$($config.ConnectBaseUrl)/rest/v1/connect/vestiging"
            headers         = $headers
            UseBasicParsing = $true
        }
        $responseVestigingen = Invoke-RestMethod @splatRestParams -verbose:$false

        $currentSchoolName = $p.Primarycontract.custom.schoolNaam    
        $currentSchoolCode = $p.primarycontract.custom.schoolBrinCode
        write-verbose -verbose "$currentSchoolCode"

        if ([string]::IsNullOrEmpty($currentSchoolCode)) {       
            $currentSchoolCode = "01UC00"
        }

        $currentSchoolUUID = ($responseVestigingen.vestigingen.Where({ $_.afkorting -eq $currentSchoolCode })).uuid
   
        write-verbose "found uuid: $($currentSchoolUUID) for school $currentSchoolCode"

        #search for employee on externnummer stop when found
        $amount = 50
        $offset = 0
        $employeeFound = $null

        $correlationField = "externnummer"
        $correlationValue = $p.externalID

        #  $correlationField = "gebruikersnaam"
        # $correlationValue = "NBR"
        do {
            $splatRestParams = @{
                Method          = 'GET'
                Uri             = "$($config.ConnectBaseUrl)/rest/v1/connect/vestiging/$currentSchoolUUID/medewerker?amount=$amount&offset=$offset"
                headers         = $headers
                UseBasicParsing = $true
            }
            $responseEmployee = Invoke-RestMethod @splatRestParams -verbose:$false -erroraction silentlycontinue

            $offset = $offset + $amount
            $employeeFound = $responseEmployee.medewerkers | Where-Object $correlationField -eq $correlationValue

        } until (        
        (($responseEmployee.medewerkers | Measure-Object).count -lt $amount) -OR ($null -ne $employeeFound)
        )


        if (($employeeFound | Measure-Object).count -eq 1) {
            write-verbose "found employee $($employeeFound.uuid) with $correlationField = $correlationValue"
            $previousAccount = $employeeFound

            if (-NOT [string]::IsNullOrEmpty($employeeFound.afkorting)) { 
                $account.afkorting = $employeeFound.afkorting  
            }
            $account.gebruikersnaam = $null
            $account.wachtwoord = $null
        }
        elseif (($employeeFound | Measure-Object).count -gt 1) {
            Throw "found multiple ($($employeeFound.uuid -join ";")) employees with $correlationField = $correlationValue"
        }
    }
    catch {

        $success = $false
        $ex = $PSItem
        if ($ex.Exception.response.statuscode -eq "404") {
            write-verbose -verbose "Could not find employee - create employee for $($p.DisplayName)"
        }
        elseif ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
            $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
            $errorObj = Resolve-HTTPError -ErrorObject $ex

            $errorMessage = "Connect-API Failed: [$($p.DisplayName)]. Error: $($ex.Exception.Message) $($errorObj.ErrorMessage) "
        }
        else {
            $errorMessage = "Connect-API Failed: [$($p.DisplayName)]. Error: $($ex.Exception.Message)"
        }

        if ($errorMessage) {
            Throw $errorMessage  
        }

    }
    $action = "Create/update"

    $splatRestMethodParams = @{
        Uri             = "https://oop.somtoday.nl/services/HRMService?wsdl"
        Method          = 'POST'
        ContentType     = "text/xml; charset=utf-8"
        UseBasicParsing = $true
    }
    if (-not  [string]::IsNullOrEmpty($config.ProxyAddress)) {
        $splatRestMethodParams['Proxy'] = $config.ProxyAddress
    }

    $SoapHeader = Get-SoapHeader -Brincode $config.SomhrmBrinNr
    $SoapBody = Get-SoapBody -account $account

    $createPersonXmlBody = @"
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
    <soapenv:Header>
      $SoapHeader
    </soapenv:Header>
    <soapenv:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        $SoapBody
    </soapenv:Body>
</soapenv:Envelope>
"@

    $splatRestMethodParams['Body'] = $createPersonXmlBody

    if (-Not($dryRun -eq $true)) {
        $responseCreatePerson = Invoke-RestMethod @splatRestMethodParams -Verbose:$true
    }
    else {
        Write-Verbose -Verbose "will send create/update user: $SoapBody"
    }
    $success = $true

    $aRef = [PSCustomObject]@{
        externMedewerkerNummer = $account.externMedewerkerNummer
        UUID                   = $employeeFound.uuid
        afkorting              = $account.afkorting
    }

    $auditLogs.Add([PSCustomObject]@{
            Message = "$action account was successful. AccountReference is: [$($aRef.externMedewerkerNummer)]"
            IsError = $false
        })

}
catch {
    $success = $false
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
        $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-Topicus-Somtoday-HRMServiceError -ErrorObject $ex
        $auditMessage = "Could not $action Topicus-Somtoday-HRMService account. Error: $($errorObj.FriendlyMessage)"
        Write-Verbose "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
    }
    else {
        $auditMessage = "Could not $action Topicus-Somtoday-HRMService account. Error: $($ex.Exception.Message)"
        Write-Verbose "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    }
    $auditLogs.Add([PSCustomObject]@{
            Message = $auditMessage
            IsError = $true
        })
    # End
}
finally {

    $dataStorage = @{
        Permissions = $vestigingen
    }


    $result = [PSCustomObject]@{
        Success          = $success
        AccountReference = $aRef
        Auditlogs        = $auditLogs
        Account          = $account
        PreviousAccount  = $previousAccount 
        # Optionally return data for use in other systems
        ExportData       = [PSCustomObject]@{
            externMedewerkerNummer = $aRef.externMedewerkerNummer
            UUID                   = $aRef.uuid
            afkorting              = $aref.afkorting
        }

        
    }
    Write-Output $result | ConvertTo-Json -Depth 10
}