<#
.SYNOPSIS
Utility function that dynamically generates a function within a module and exports it

.DESCRIPTION
Key is the use of the $CallingModuleScope, this enables the function to be exported into the
calling scope - generally the running powershell console
#>
function GenerateFunctionAndExportIntoCallingModule() {
	[CmdletBinding()]
	param (
		[Parameter( Position = 1, Mandatory = $true )]
		$FunctionName,
		[Parameter( Position = 2, Mandatory = $true )]
		$FunctionContent,
		[Parameter( Position = 3, Mandatory = $false )]
		$CallingModuleScope = $($PSCmdlet.SessionState.Module)
	)
	
	& $CallingModuleScope New-Item -Path "Function:$FunctionName" -Value $FunctionContent -ItemType Function -OutVariable $discarded 
	& $CallingModuleScope Export-ModuleMember -Function $FunctionName	
}

<#
.SYNOPSIS
Basic implemntation creating a function via a string.  The resultant function doesn't have a reference to
the object the function is being based of and will therefore not pick up any changes to properties on that object
#>
function CreateSimpleFunctionsViaString() {
	[CmdletBinding()]
	param (
		[Parameter(Position = 1, Mandatory = $true )]
		$Components
	)
	
	$componentProperties = Get-Member -InputObject $Components -MemberType NoteProperty
	
	foreach ( $componentProperty in $componentProperties ) {
		$component = $Components.$($componentProperty.Name)
		
		$functionBody = "Write-Host `"{0}`"" -f $component.Message
		$FunctionName = "Invoke-StringHelloFromComponent{0}" -f $component.Name
		
		# need to dot source this call
		. GenerateFunctionAndExportIntoCallingModule $FunctionName $functionBody
	}
}

<#
.SYNOPSIS
Creates a function accepting arguments by building up a string

.DESCRIPTION
Static function that doesn't reference the object the function is create from, so doens't pick up any property changes
Supports comment base help for the exported function
#>
function CreateArgsFunctionsViaString() {
	[CmdletBinding()]
	param (
		[Parameter(Position = 1, Mandatory = $true )]
		$Components
	)
	
	$componentProperties = Get-Member -InputObject $Components -MemberType NoteProperty
	
	foreach ( $componentProperty in $componentProperties ) {
		$component = $Components.$($componentProperty.Name)
		
		$functionBody = @"
<#
.SYNOPSIS
Cmdlet function generated from a string with comment based help
#>
[CmdletBinding()]
param(
	[Parameter(Position = 1, Mandatory = `$true)]
	[string] `$Name
)

Write-Host `"{0} says hello to `$Name`"
"@
		$functionBody = [string]::Format( $functionBody, $component.Name )
		$FunctionName = "Invoke-StringArgHelloFromComponent{0}" -f $component.Name
		
		# need to dot source this call
		. GenerateFunctionAndExportIntoCallingModule $FunctionName $functionBody 
	}
}

<#
.SYNOPSIS
Generates a function using a script block closure.

.DESCRIPTION
Has a live reference to the component so the implementation changes based on the current value of
properties on the component when the function executes
Doesn't seem to support comment based help
#>
function CreateFunctionsViaClosure() {
	[CmdletBinding()]
	param (
		[Parameter(Position = 1, Mandatory = $true )]
		$Components
	)
	
	$componentProperties = Get-Member -InputObject $Components -MemberType NoteProperty
	
	foreach ( $componentProperty in $componentProperties ) {
		$component = $Components.$($componentProperty.Name)
		
		$functionBody = {
			Write-Host ( "Hello from a script block for component {0}" -f $component.Name )
		}.GetNewClosure()
		
		$FunctionName = "Invoke-ScriptblockHelloFromComponent{0}" -f $component.Name
		
		# need to dot source this call
		. GenerateFunctionAndExportIntoCallingModule $FunctionName $functionBody
	}
}

<#
.SYNOPSIS
Generates a function that accepts arguments using a script block closure

.DESCRIPTION
Has a live reference to the component so the implementation changes based on the current value of
properties on the component when the function executes
Doesn't seem to support comment based help
#>
function CreateFunctionsViaClosureWithArg() {
	[CmdletBinding()]
	param (
		[Parameter(Position = 1, Mandatory = $true )]
		$Components
	)
	
	$componentProperties = Get-Member -InputObject $Components -MemberType NoteProperty
	
	foreach ( $componentProperty in $componentProperties ) {
		$component = $Components.$($componentProperty.Name)
		
		$functionBody = {
<#
.SYNOPSIS
This is comment based help
#>
[CmdletBinding()]
param(
	[Parameter( Position = 1, Mandatory = $true)]
	[string] $Name
)
Write-Host ( "Hello {0} from a script block for component {1}" -f $Name, $component.Name )
		}.GetNewClosure()
		
		$FunctionName = "Invoke-ScriptblockWithArgHelloFromComponent{0}" -f $component.Name
		
		# need to dot source this call
		. GenerateFunctionAndExportIntoCallingModule $FunctionName $functionBody $PSCmdlet.SessionState.Module
	}
}

<#
.SYNOPSIS
Adds a new property to the component that is a script block which runs code relating to the component
#>
function AddSayHelloScriptBlock() {
	[CmdletBinding()]
	param (
		[Parameter(Position = 1, Mandatory = $true )]
		$Components
	)
	
	$componentProperties = Get-Member -InputObject $Components -MemberType NoteProperty
	
	foreach ( $componentProperty in $componentProperties ) {
		$component = $Components.$($componentProperty.Name)
		
		$methodBody = { Write-Host ( "Hello from {0}" -f $component.Name ) }.GetNewClosure()
		Add-Member -InputObject $component -MemberType ScriptMethod -Name SayHello -Value $methodBody
	}
}

<#
.SYNOPSIS
Generates a function that calls into another function via a string
#>
function CreateSimpleFunctionWrapperViaString() {
	[CmdletBinding()]
	param (
		[Parameter(Position = 1, Mandatory = $true )]
		$Components
	)
	
	$componentProperties = Get-Member -InputObject $Components -MemberType NoteProperty
	
	foreach ( $componentProperty in $componentProperties ) {
		$component = $Components.$($componentProperty.Name)
		
		$functionBody = "[CmdletBinding()] param( [Parameter( Position = 1, Mandatory = `$true)] [string] `$Name ) Write-HelloString -Component `"{0}`" -Name `$Name" -f $component.Name
		$FunctionName = "Invoke-StringWrapperFromComponent{0}" -f $component.Name
		
		# need to dot source this call
		. GenerateFunctionAndExportIntoCallingModule $FunctionName $functionBody
	}
}

<#
.SYNOPSIS
Generates a function that calls another function through a script block

.DESCRIPTION
The function being called by the script block needs to exported from the module
The scriptblock doesn't seem to pass down Verbose, WhatIf and Confirm parameters automatically and requires some jiggery pokery
#>
function CreateSimpleFunctionWrapperViaScriptblock() {
	[CmdletBinding()]
	param (
		[Parameter(Position = 1, Mandatory = $true )]
		$Components
	)
	
	$componentProperties = Get-Member -InputObject $Components -MemberType NoteProperty
	
	foreach ( $componentProperty in $componentProperties ) {
		$component = $Components.$($componentProperty.Name)
		
		$functionBody = {
			[CmdletBinding( SupportsShouldProcess = $true)] 
			param( 
				[Parameter( Position = 1, Mandatory = $true)] 
				[string] $Name 
			) 
			
			Write-HelloObject -Component $component -Name $Name `
				-Verbose:($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Verbose")) `
				-WhatIf:($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("WhatIf")) `
				-Confirm:($PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Confirm"))
		}.GetNewClosure()
		$FunctionName = "Invoke-ScriptBlockWrapperFromComponent{0}" -f $component.Name
		
		# need to dot source this call
		. GenerateFunctionAndExportIntoCallingModule $FunctionName $functionBody
	}
}

function Write-HelloString() {
	[CmdletBinding()]
	param(
		[Parameter( Position = 1, Mandatory = $true)]
		[string] $Component,
		[Parameter( Position = 2, Mandatory = $false)]
		[string] $Name = $("")
	)
	
	Write-Verbose "Verbose is on"
	Write-Host ( "Hello {0} from component {1}" -f $Name, $component )
}

function Write-HelloObject() {
	[CmdletBinding( SupportsShouldProcess = $true )]
	param(
		[Parameter( Position = 1, Mandatory = $true)]
		$Component,
		[Parameter( Position = 2, Mandatory = $false)]
		[string] $Name = $("")
	)
	
	Write-Verbose "Verbose is on"
	Write-Host ( "Hello {0} from component {1}" -f $Name, $component.Name )
	
	if ( $PSCmdlet.ShouldProcess("First", "Second")) {
		Write-Host "Doing it"
	}
}
Export-ModuleMember -Function Write-HelloObject

