class User {
    $Name
    $RewardPoints
    $Consequence
	$Allowance

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
		$Queue = Find-LiteDBDocument -Collection "TransactionQueue" -Connection $this.Connection
		
		foreach ($Action in $Queue){
			if ($Action.TaskUnitId){
				$TaskUnit = $this.GetRecord($Action.TaskUnitId)
				Write-Host "$TaskUnit Processing..."
			}
			else {
				$TaskUnit = $Action
				Write-Host "$TaskUnit Processing..."
			}

			switch ($TaskUnit.TaskUnit.Type){
				"Habit" 		{$this.ProcessHabit($TaskUnit)}
				"Daily"			{$this.ProcessDaily($TaskUnit)}
				"Reward"		{$this.ProcessReward($TaskUnit)}
				"Todo" 			{$this.ProcessTodo($TaskUnit)}
				"Consequence" 	{$this.ProcessConsequence($TaskUnit)}
				"Allowance" 	{$this.ProcessAllowance($TaskUnit)}
			}
		}
	}

	[void] ProcessHabit ($TaskUnit) {

	}
	
	[void] ProcessDaily ($TaskUnit) {

	}
	
	[void] ProcessReward ($TaskUnit) {

	}
	
	[void] ProcessTodo ($TaskUnit) {

	}
	
	[void] ProcessConsequence ($TaskUnit) {

	}
	
	[void] ProcessAllowance ($TaskUnit) {

	}
	
}