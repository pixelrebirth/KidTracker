param (
    $FilePath = "$PSScriptRoot/Databases/KidTracker.db"
)

Import-Module pslitedb
. $PSScriptRoot/Classes/Public.ps1

# Remove-Item ./test.db -Force
$Credential = Get-Credential -message "Database Credential for $FilePath"
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
