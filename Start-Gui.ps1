<# This form was created using POSHGUI.com  a free online gui designer for PowerShell
.NAME
    KidTracker
#>
Import-Module pslitedb
. $PSScriptRoot/Classes/Public.ps1

$Credential = Get-StoredCredential -WarningAction 0 | ? username -eq "testdb"
$Database = New-Object Database -ArgumentList ('./Databases/test.db',$Credential)

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '647,586'
$Form.text                       = "Form"
$Form.TopMost                    = $false

$Submit                          = New-Object system.Windows.Forms.Button
$Submit.text                     = "Submit"
$Submit.width                    = 60
$Submit.height                   = 30
$Submit.location                 = New-Object System.Drawing.Point(216,307)
$Submit.Font                     = 'Microsoft Sans Serif,10'

$Kid                             = New-Object system.Windows.Forms.ComboBox
$Kid.width                       = 190
$Kid.height                      = 20
$Kid.location                    = New-Object System.Drawing.Point(45,20)
$Kid.Font                        = 'Microsoft Sans Serif,10'

$Dailies                         = New-Object system.Windows.Forms.ListBox
$Dailies.text                    = "listBox"
$Dailies.width                   = 193
$Dailies.height                  = 223
$Dailies.location                = New-Object System.Drawing.Point(44,79)
$Dailies.SelectionMode           = 'MultiExtended'

$Habits                          = New-Object system.Windows.Forms.ListBox
$Habits.text                     = "listBox"
$Habits.width                    = 193
$Habits.height                   = 223
$Habits.location                 = New-Object System.Drawing.Point(257,79)
$Habits.SelectionMode            = 'MultiExtended'

$Reward                          = New-Object system.Windows.Forms.ListBox
$Reward.text                     = "listBox"
$Reward.width                    = 193
$Reward.height                   = 223
$Reward.location                 = New-Object System.Drawing.Point(43,341)
$Reward.SelectionMode            = 'MultiExtended'

$Todo                            = New-Object system.Windows.Forms.ListBox
$Todo.text                       = "listBox"
$Todo.width                      = 193
$Todo.height                     = 223
$Todo.location                   = New-Object System.Drawing.Point(257,341)
$Todo.SelectionMode              = 'MultiExtended'

$Stats                           = New-Object system.Windows.Forms.TextBox
$Stats.multiline                 = $true
$Stats.width                     = 132
$Stats.height                    = 484
$Stats.location                  = New-Object System.Drawing.Point(470,80)
$Stats.Font                      = 'Microsoft Sans Serif,10'

$Kid_Label                       = New-Object system.Windows.Forms.Label
$Kid_Label.text                  = "Kid Selection"
$Kid_Label.AutoSize              = $true
$Kid_Label.width                 = 25
$Kid_Label.height                = 10
$Kid_Label.location              = New-Object System.Drawing.Point(242,24)
$Kid_Label.Font                  = 'Microsoft Sans Serif,12,style=Bold'

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Dailies"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(46,55)
$Label1.Font                     = 'Microsoft Sans Serif,12,style=Bold'

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "Habits"
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(397,55)
$Label2.Font                     = 'Microsoft Sans Serif,12,style=Bold'

$Label3                          = New-Object system.Windows.Forms.Label
$Label3.text                     = "Todo"
$Label3.AutoSize                 = $true
$Label3.width                    = 25
$Label3.height                   = 10
$Label3.location                 = New-Object System.Drawing.Point(410,315)
$Label3.Font                     = 'Microsoft Sans Serif,12,style=Bold'

$Label4                          = New-Object system.Windows.Forms.Label
$Label4.text                     = "Reward"
$Label4.AutoSize                 = $true
$Label4.width                    = 25
$Label4.height                   = 10
$Label4.location                 = New-Object System.Drawing.Point(45,315)
$Label4.Font                     = 'Microsoft Sans Serif,12,style=Bold'

$Label5                          = New-Object system.Windows.Forms.Label
$Label5.text                     = "Stats"
$Label5.AutoSize                 = $true
$Label5.width                    = 25
$Label5.height                   = 10
$Label5.location                 = New-Object System.Drawing.Point(560,55)
$Label5.Font                     = 'Microsoft Sans Serif,12,style=Bold'
$Form.controls.AddRange(@($Dailies,$Submit,$Kid,$Habits,$Reward,$Todo,$Stats,$Kid_Label,$Label1,$Label2,$Label3,$Label4,$Label5))

$Kid.Add_SelectedIndexChanged({ ModifyTaskUnits $Database $Kid})
$Submit.Add_Click({ Submit $Database $Dailies $Habits $Todo $Reward $Kid})

function AddItem ($Item, $AllTaskUnits){
    if (!$Item){return}
        
    $ItemToSubmit = $Null
    $ItemToSubmit = $AllTaskUnits | where {$_.TaskUnits.Title -eq $Item}

    return $ItemToSubmit
}

function Submit ($Database, $Dailies, $Habits, $Todo, $Reward, $Kid) {
    $Database.GetCollection('AllUserTaskUnits')
    $AllTaskUnits = $Database.Document | where Name -eq $Kid.Text

    $AllItemsToSubmit = @()
    foreach ($Daily in $Dailies.SelectedItems){
        $AllItemsToSubmit += AddItem $Daily $AllTaskUnits
    }

    foreach ($EachHabit in $Habits.SelectedItems){
        $AllItemsToSubmit += AddItem $EachHabit $AllTaskUnits
    }

    foreach ($Task in $Todo.SelectedItems){
        $AllItemsToSubmit += AddItem $Task $AllTaskUnits
    }

    foreach ($EachReward in $Reward.SelectedItems){
        $AllItemsToSubmit += AddItem $EachReward $AllTaskUnits
    }

    foreach ($Item in $AllItemsToSubmit){
        Write-Host $Item._id
        $Database.AddTaskUnitToQueue($Item._id)
    }

    $Dailies.Items.Clear()
    $Habits.Items.Clear()
    $Reward.Items.Clear()
    $Todo.Items.Clear()
}

function ModifyTaskUnits ($Database, $Kid) {
    $Database.GetCollection('AllUserTaskUnits')
    $Dailies.Items.Clear()
    $Habits.Items.Clear()
    $Reward.Items.Clear()
    $Todo.Items.Clear()
    
    $AllTaskUnits = $Database.Document | where Name -eq $Kid.Text
    $AllTaskUnits.TaskUnits | where {$_.taskunit_type -eq 'daily' -AND $_ -ne $null}    | ForEach-Object {[void] $Dailies.Items.Add($_.title)}
    $AllTaskUnits.TaskUnits | where {$_.taskunit_type -eq 'habit' -AND $_ -ne $null}    | ForEach-Object {[void] $Habits.Items.Add($_.title)}
    $AllTaskUnits.TaskUnits | where {$_.taskunit_type -eq 'reward' -AND $_ -ne $null}   | ForEach-Object {[void] $Reward.Items.Add($_.title)}
    $AllTaskUnits.TaskUnits | where {$_.taskunit_type -eq 'todo' -AND $_ -ne $null}     | ForEach-Object {[void] $Todo.Items.Add($_.title)}
}

#Write your logic code here
$Database.GetCollection('UserTracker')
$AllUsers = $Database.Document.Name | sort -Unique
$AllUsers | ForEach-Object {[void] $Kid.Items.Add($_)}

[void]$Form.ShowDialog()