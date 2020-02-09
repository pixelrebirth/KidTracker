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

# class TaskUnit {
# 	[string]$Title
# 	[string]$Description
# 	[ValidateSet("open","closed")]$State
# 	[ValidateSet("todo","habit","daily","reward","task","allowance","consequence")]$Type
# 	[ValidatePattern('M|Tu|W|Th|F|Sa|Su')]$DayPattern
# 	[int]$Points
# 	[bool]$Negative
# 	[int]$Stage
# 	[string]$UserName

# 	[ValidatePattern('^\d+\.\d\d$')]$Dollars
# 	[datetime]$DateCreated
# 	[datetime]$DateDue
# 	[datetime]$PauseStart
# 	[datetime]$PauseEnd
# 	[datetime]$SubmitDateTime
# 	[int]$Streak

# 	TaskUnit ($Data) {
# 		$this.type = $Data.TaskUnit_Type
# 		$this.Title = $Data.Title
# 		$this.Description = $Data.Description
# 		if ($Data.DayPattern){$this.DayPattern = $Data.DayPattern.split(',')}
# 		$this.Points = $Data.Points
# 		$this.Negative = $Data.Negative
# 		$this.Stage = $Data.Stage
# 	}
# }

class Database {
	$FilePath
	$Connection
	$Document
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
		$FileCollection = Get-Content "$PSScriptRoot/../TaskUnit_Config.json" | ConvertFrom-Json
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
		$FileConfig = Get-Content "$PSScriptRoot/../User_Base_Config.json" | ConvertFrom-Json
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

	[void] ProcessQueue () {
		# $this.Queue = Find-LiteDBDocument -Collection TransactionQueue -Connection $this.Connection
		# foreach ($Item in $this.Queue | where name -eq $User.name) {
		# 	switch ($Item.type){
		# 		"habit" 		{$Item}
		# 		"daily"			{$Item}
		# 		"reward"		{$Item}
		# 		"todo" 			{$Item}
		# 		"consequence" 	{$Item}
		# 	}
		# }
	}
}