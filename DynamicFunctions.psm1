$modulePath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

# Import other helper scripts
$powershellScripts = Get-ChildItem -Path $modulePath -Filter *.ps1
foreach ( $script in $powershellScripts ) {
	. $script.FullName
}

$ModuleConfiguration = New-Object -TypeName PsObject
Export-ModuleMember -Variable ModuleConfiguration



$componentOne = @{ 
	Name = "One"
	Message = "Hello from component one"
}
$componentTwo = @{ 
	Name = "Two"
	Message = "Hello from component two"
}

$components = @{
	ComponentOne = ( Convert-HashTableToObject $componentOne )
	ComponentTwo = ( Convert-HashTableToObject $componentTwo )
}
Add-PropertyToObject $ModuleConfiguration "Components" ( Convert-HashTableToObject $components )

# Need to dot source these calls
. CreateSimpleFunctionsViaString $ModuleConfiguration.Components
. CreateArgsFunctionsViaString $ModuleConfiguration.Components
. CreateFunctionsViaClosure $ModuleConfiguration.Components
. CreateFunctionsViaClosureWithArg $ModuleConfiguration.Components
AddSayHelloScriptBlock $ModuleConfiguration.Components
. CreateSimpleFunctionWrapperViaString $ModuleConfiguration.Components
. CreateSimpleFunctionWrapperViaScriptblock $ModuleConfiguration.Components

function Test() {
	[CmdletBinding()]
	param()
	
	$PsCmdlet | Out-Host
	$PSCmdlet.SessionState.Module | Out-Host
	$PSCmdlet.SessionState.Module.GetType() | Out-Host
	$PSCmdlet.SessionState.Module | gm | Out-Host
	
	$PSCmdlet.SessionState.Module.SessionState | gm | Out-Host
	$PSCmdlet.SessionState.Module.SessionState | Out-Host

}

. Test

