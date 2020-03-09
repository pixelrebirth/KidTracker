param (
    $FilePath = "$PSScriptRoot/Databases/Test.db"
)

Import-Module pslitedb
. $PSScriptRoot/Classes/Public.ps1

$Credential = Get-StoredCredential -WarningAction 0 | ? username -eq "testdb"
$Database = New-Object Database -ArgumentList ($FilePath,$Credential)

$Database.GetCollection("TransactionQueue")
$Transactions = $Database.Document

$Transactions