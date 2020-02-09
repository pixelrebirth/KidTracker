. ./Classes/Public.ps1
$Credential = Get-Credential -message "Database Credential for $FilePath"
$Database = New-Object Database -ArgumentList ('./test.db',$Credential)

Get-UDRestApi | Stop-UDRestApi

$Endpoints = @(
    New-UDEndpoint -Url "/docology" -Method "POST" -Endpoint {
        Param($Body)
        $Parameters = $Body | ConvertFrom-Json
        if (!$Parameters){return "Damnit!"}
        $Parameters

        #Write to 
    }
    
    New-UDEndpoint -Url "/kidtracker/allusers" -Method "GET" -Endpoint {
        $Database.GetCollection("AllUserTaskUnits")
        $Database.Document | ConvertTo-Json
    }
    New-UDEndpoint -Url "/kidtracker/taskunit" -Method "POST" -Endpoint {
        Param($Body)
        $Parameters = $Body | ConvertFrom-Json
        if (!$Parameters){return "Damnit!"}
        $Parameters

        #Write to 
    }

    New-UDEndpoint -Url "/redgreen" -Method "POST" -Endpoint {
        Param($Body)
        $Parameters = $Body | ConvertFrom-Json
        if (!$Parameters){return "Damnit!"}
        $Parameters
    }
)

while ($true){
    Get-UDRestApi | Stop-UDRestApi
    Start-UDRestApi -Endpoint $Endpoints -port 8081
    Start-Sleep -seconds 3300
}