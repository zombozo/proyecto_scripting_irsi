param(
    [Parameter(Mandatory=$false)]
    [string] $NombreDeTarea    = "CrearUsuariosEmpleados",

    [Parameter(Mandatory=$false)]
    [string] $rutaDelScript = "$PSScriptRoot\crear_usuarios.ps1",

    [Parameter(Mandatory=$false)]
    [ValidateRange(0,23)]
    [int] $Hora           = 3,

    [Parameter(Mandatory=$false)]
    [ValidateRange(0,59)]
    [int] $Minuto         = 0
)

# 1) Verificar que el .ps1 existe
if (-not (Test-Path $rutaDelScript)) {
    Write-Error "No se encontró el script en '$rutaDelScript'. Ajusta la ruta e intenta de nuevo."
    exit 1
}

# Construye un DateTime con la hora/minuto indicados 
$horaTrigger = [datetime]::Today.AddHours($Hora).AddMinutes($Minuto)

# 2) PowerShell llama al .ps1 con ExecutionPolicy Bypass
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$rutaDelScript`""

# 3) Trigger diario a la hora indicada
$trigger = New-ScheduledTaskTrigger -Daily -At $horaTrigger

# 4) Ejecutar como SYSTEM con privilegios elevados
$principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" `
    -LogonType ServiceAccount -RunLevel Highest

# 5) Si ya existe, eliminar para recrear con parámetros actualizados
if (Get-ScheduledTask -TaskName $NombreDeTarea -ErrorAction SilentlyContinue) {
    Write-Warning "ya existe una tarea programada, se reemplazará"
    Unregister-ScheduledTask -TaskName $NombreDeTarea -Confirm:$false
}

# 6) Registrar la nueva tarea
Register-ScheduledTask -TaskName $NombreDeTarea `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal

Write-Output "Tarea programada '$NombreDeTarea' creada."
Write-Output "   • Script:     $rutaDelScript"
Write-Output "   • Se ejecutará diariamente a las $horaTrigger"