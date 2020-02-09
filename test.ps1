param (
    $FilePath = "$PSScriptRoot/Databases/Test.db"
)

Import-Module pslitedb
. $PSScriptRoot/Classes/Public.ps1

# Remove-Item ./test.db -Force
$Credential = Get-Credential -message "Database Credential for $FilePath"
$Database = New-Object Database -ArgumentList ($FilePath,$Credential)

$Database.GetCollection("TransactionQueue")
$Database.Document

$User