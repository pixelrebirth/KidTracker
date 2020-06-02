param (
    $FilePath = "$PSScriptRoot\Databases\Test.db"
)

Import-Module pslitedb
. $PSScriptRoot/Classes/Public.ps1
$UserName = "TestDatabase"

Remove-Item $FilePath
New-StoredCredential -UserName $UserName -Password (New-Guid).guid -EA 0

$Credential = Get-StoredCredential -WarningAction 0 | ? UserName -eq $UserName
$Database = New-Object Database -ArgumentList ($FilePath,$Credential)

$Collections = @(
    "TransactionQueue",
    "TransactionHistory",
    "AllUserTaskUnits",
    "UserTracker"
)
$Collections | ForEach-Object {
    $Database.NewCollection($_)
}

$Database.WriteAllUserTaskUnitsFromFile()
$Database.WriteUserTrackerFromFile()
# 
