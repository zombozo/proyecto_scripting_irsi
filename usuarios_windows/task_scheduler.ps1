param(
    [Parameter(Mandatory=$false)]
    [string] $TaskName    = "CrearUsuariosEmpleados",

    [Parameter(Mandatory=$false)]
    [string] $ScriptPath = "$PSScriptRoot\crear_usuarios.ps1",

    [Parameter(Mandatory=$false)]
    [ValidatePattern('^(?:[01]\d|2[0-3]):[0-5]\d$')]
    [string] $TriggerTime = "23:01"
)

# 1) Verificar que el .ps1 existe
if (-not (Test-Path $ScriptPath)) {
    Write-Error "No se encontró el script en '$ScriptPath'. Ajusta la ruta e intenta de nuevo."
    exit 1
}

# 2) PowerShell llama al .ps1 con ExecutionPolicy Bypass
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$ScriptPath`""

# 3) Trigger diario a la hora indicada
$trigger = New-ScheduledTaskTrigger -Daily -At $TriggerTime

# 4) Ejecutar como SYSTEM con privilegios elevados
$principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" `
    -LogonType ServiceAccount -RunLevel Highest

# 5) Si ya existe, eliminar para recrear con parámetros actualizados
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Write-Warning "ya existe una tarea programada, se reemplazará"
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# 6) Registrar la nueva tarea
Register-ScheduledTask -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal

Write-Output "Tarea programada '$TaskName' creada."
Write-Output "   • Script:     $ScriptPath"
Write-Output "   • Se ejecutará diariamente a las $TriggerTime"