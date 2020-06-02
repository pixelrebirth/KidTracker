class User {
    $Name
    $RewardPoints
    $Consequence
	$Allowance
	$DailiesDue = 0
	$DailiesDone = 0

	UpdateUserTrackerCollection ([Database]$Database) {
		$Document = $this | ConvertTo-LiteDbBSON
		$DocumentOid = (Add-LiteDBDocument -Collection "UserTracker" -Document $Document -Connection $Database.Connection -ErrorAction 0).oid
		if (!$DocumentOid){
			$Document.AsDocument.tostring() -match '.*\{\"\$oid\"\:\"(?<id>.*)\"\}.*' | Out-Null
			$oid = $matches.id
			Update-LiteDBDocument -Collection "UserTracker" -Connection $Database.Connection -Id $oid -Document $Document
		}
	}
}

class Database {
	$FilePath
	$Connection
	$Document
	$Users
	$Queue

	Database ($FilePath, [PSCredential]$Credential) {
		$this.FilePath = $FilePath
		if (!(Test-Path $this.FilePath)){
			New-LiteDBDatabase -Path $FilePath -Credential $Credential
		}
		$this.Connection = Open-LiteDBConnection -Path $FilePath -Credential $Credential
	}

	[void] NewCollection ($CollectionName) {
		New-LiteDBCollection $CollectionName -Connection $this.Connection
	}

	[void] GetCollection ($CollectionName) {
		$this.document = Find-LiteDBDocument -Collection $CollectionName -Connection $this.Connection
	}

	[void] WriteAllUserTaskUnitsFromFile () {
		$FileCollection = Get-Content "$PSScriptRoot/../Configs/TaskUnit_Config.json" | ConvertFrom-Json
		Remove-LiteDBCollection -Collection "AllUserTaskUnits" -Connection $this.Connection -Confirm:$False
		$this.NewCollection("AllUserTaskUnits")

		foreach ($Name in $FileCollection.UniqueTaskUnits.Name | sort -Unique){
			foreach ($TaskUnit in $FileCollection.AllUserTaskUnits){
				$hash = [pscustomobject]@{}
				$hash | Add-Member -MemberType NoteProperty -Name 'name' -Value $Name -Force
				$hash | Add-Member -MemberType NoteProperty -Name 'taskunits' -Value $TaskUnit -Force
				$BSON = $hash | ConvertTo-LiteDbBson
				Add-LiteDBDocument -Connection $this.connection -Collection "AllUserTaskUnits" -Document $BSON
			}
		}
		foreach ($TaskUnit in $FileCollection.UniqueTaskUnits){
			$BSON = $TaskUnit | ConvertTo-LiteDbBson
			Add-LiteDBDocument -Connection $this.connection -Collection "AllUserTaskUnits" -Document $BSON
		}

	}

	[void] WriteUserTrackerFromFile () {
		$FileConfig = Get-Content "$PSScriptRoot/../Configs/User_Base_Config.json" | ConvertFrom-Json
		Remove-LiteDBCollection -Collection "UserTracker" -Connection $this.connection -Confirm:$False
		$this.NewCollection("UserTracker")

		Foreach ($User in $FileConfig.users){
			$BSON = $User | ConvertTo-LiteDbBson
			Add-LiteDBDocument -Connection $this.connection -Collection "UserTracker" -Document $BSON
		}
	}

	[void] AddTaskUnitToQueue ($TaskUnitId) {
		$BSON = [pscustomobject]@{"TaskUnitId" = [string]$TaskUnitId} | ConvertTo-LiteDbBSON
		Write-Host $Bson
		Add-LiteDBDocument -Collection "TransactionQueue" -Document $BSON -Connection $this.Connection
	}

	[PSCustomObject] GetRecord ($TaskUnitId) {
		return $this.Document | where {$_._id -eq $TaskUnitId}
	}

	[void] ProcessQueue () {
		$this.GetCollection('AllUserTaskUnits')
		$this.Queue = Find-LiteDBDocument -Collection "TransactionQueue" -Connection $this.Connection
		$this.Users = Find-LiteDBDocument -Collection "UserTracker" -Connection $this.Connection
		
		foreach ($user in $this.users){
			($this.users | ? name -eq $user.name).DailiesDue += ($this.Queue | where {$_.taskunits.taskunit_type -eq "daily"}).count
		}

		foreach ($Action in $this.Queue){
			if ($Action.TaskUnitId){
				$TaskUnit = $this.Document | ? {$_._id -eq $Action.TaskUnitId}
				Write-Host "$TaskUnit`: $($TaskUnit.taskunits)"
			}
			else {
				$TaskUnit = $Action
				Write-Host "Raw $TaskUnit`: $($TaskUnit.taskunits)"
			}

			switch ($TaskUnit.taskunits.taskunit_type){
				"habit" 		{$this.ProcessHabit($TaskUnit)}
				"daily"			{$this.ProcessDaily($TaskUnit)}
				"reward"		{$this.ProcessReward($TaskUnit)}
				"todo" 			{$this.ProcessTodo($TaskUnit)}
				"consequence" 	{$this.ProcessConsequence($TaskUnit)}
				"allowance" 	{$this.ProcessAllowance($TaskUnit)}
				default			{
					Remove-LiteDBDocument -Collection "TransactionQueue" -id $Action._id -Connection $this.Connection
					Write-Error "Missing ID in AllUserTaskUnits: $($Action.TaskUnitId) - Removing from TransactionQueue"
				}
			}
		}

		foreach ($user in $this.users){
			if ($user.DailiesDue -ne $user.DailiesDone){
				($this.users | ? name -eq $user.name).Consequence += 1
			}
			else {
				($this.users | ? name -eq $user.name).Consequence = 0
			}
		}

		foreach ($user in $this.users){
			$Bson = $user | ConvertTo-LiteDbBSON
			Update-LiteDBDocument -id $user._id -Document $Bson -Collection "UserTracker" -Connection $this.Connection
		}
	}

	[void] ProcessTransaction ($TaskUnitUser, $TaskUnit) {
		try {
			$UserBson = $TaskUnitUser | ConvertTo-LiteDbBSON
			$TaskUnitBson = $this.Queue | ? TaskUnitId -eq $TaskUnit._id | ConvertTo-LiteDbBSON
			$id = $TaskUnitUser._id

			Update-LiteDBDocument -Collection "UserTracker" -id $id -Document $UserBson -Connection $this.Connection
			Add-LiteDBDocument -Collection "TransactionHistory" -Document $TaskUnitBson -Connection $this.Connection
			$this.Queue | ? TaskUnitId -eq $TaskUnit._id | Remove-LiteDBDocument -Collection "TransactionQueue" -Connection $this.Connection

			Write-Host "Completed Processing: $TaskUnit"
		} 
		catch {
			Write-Error "Cannot update document with $TaskUnit"
		}
	}

	[void] ProcessHabit ($TaskUnit) {
		$TaskUnitUser = $this.Users | ? {$_.name -eq $TaskUnit.name}
		$TaskUnitUser.RewardPoints += $TaskUnit.taskunits.points

		$this.ProcessTransaction($TaskUnitUser, $TaskUnit)
	}

	[void] ProcessDaily ($TaskUnit) {
		$TaskUnitUser = $this.Users | ? {$_.name -eq $TaskUnit.name}
		$TaskUnitUser.DailiesDone += 1

		$this.ProcessTransaction($TaskUnitUser, $TaskUnit)
	}

	[void] ProcessReward ($TaskUnit) {
		$TaskUnitUser = $this.Users | ? {$_.name -eq $TaskUnit.name}
		$TaskUnitUser.RewardPoints -= $TaskUnit.taskunits.points

		$this.ProcessTransaction($TaskUnitUser, $TaskUnit)
	}

	[void] ProcessTodo ($TaskUnit) {

	}

	[void] ProcessConsequence ($TaskUnit) {

	}

	[void] ProcessAllowance ($TaskUnit) {

	}

}