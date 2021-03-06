<#
.SYNOPSIS
Adds a new property to powershell object and sets the value

.PARAMETER Object
Powershell object to add the property to
#>
function Add-PropertyToObject() {
	param(
		[Parameter( Position = 1, Mandatory = $true )]
		$Object,
		[Parameter( Position = 2, Mandatory = $true )]
		[string]
		$PropertyName,
		[Parameter( Position = 3, Mandatory = $true )]
		[AllowNull()]
		$Value
	)
	
	Add-Member -InputObject $Object -MemberType NoteProperty -Name $PropertyName -Value $Value
}

<#
.SYNOPSIS
Takes a hash table and converts the keys into properties on an object

.PARAMETER HashTableToConvert
Hashtable to be converted into an object

.PARAMETER ObjectToAddPropertiesTo
Existing object to add the properties to
#>
function Convert-HashTableToObject() {
	param(
		[Parameter( Position = 1, Mandatory = $true )]		
		$HashTableToConvert,
		[Parameter( Mandatory = $false )]
		$ObjectToAddPropertiesTo
	)
	
	if ( $ObjectToAddPropertiesTo -eq $null ) {
		$ObjectToAddPropertiesTo = New-Object PsObject
	}
	
	$HashTableToConvert.Keys |
		ForEach-Object {
			$Value = $HashTableToConvert.$_
			
			if ( $Value -is [HashTable] ) {
				$Value = Convert-HashTableToObject $Value
			}
			
			Add-PropertyToObject $ObjectToAddPropertiesTo $_ $Value
		}
		
	return $ObjectToAddPropertiesTo
}