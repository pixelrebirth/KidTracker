param (
    $FilePath = "$PSScriptRoot/KidTracker.db"
)

Import-Module pslitedb
. $PSScriptRoot/Classes/Public.ps1

$Credential = Get-Credential -message "Database Credential for $FilePath"
$Database = [Database]::new($FilePath, $Credential)
$Collections = @(
    "TransactionQueue",
    "TransactionHistory",
    "AllUsers"
)
$Collections | ForEach-Object {
    $Database.NewCollection($_)
}
# 
