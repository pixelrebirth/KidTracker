param (
    $FilePath = "$PSScriptRoot/Databases/Test.db"
)

Import-Module pslitedb
. $PSScriptRoot/Classes/Public.ps1

Remove-Item $FilePath
$Credential = Get-StoredCredential -WarningAction 0 | ? username -eq "testdb"
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
