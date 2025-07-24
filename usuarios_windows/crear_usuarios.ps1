# Ruta al directorio del script y archivos
$ScriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$path         = Join-Path  $ScriptDir 'empleados.csv'
$pythonScript = Join-Path  $ScriptDir 'crear_usuarios.py'
$logPath      = Join-Path  $ScriptDir 'empleados.log'
$delimiter    = ','

# Asegurarnos de que trabajamos en el directorio correcto
Set-Location $ScriptDir

function Write-Log {
    param (
        [Parameter(Mandatory)][string] $Message,
        [ValidateSet("INFO","ERROR","WARN")][string] $Level = "INFO"
    )
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    "$ts [$Level] $Message" |
        Out-File -FilePath $logPath -Append -Encoding UTF8
}

# Debug inicial
Write-Log "Working directory: $(Get-Location)"
Write-Log "Log file path:   $logPath"

function Leer-CSV {
    Write-Log "Iniciando tarea Leer-CSV"

    do {
        Write-Log "Cargando datos de '$path' (delimitador='$delimiter')"
        $datos      = Import-Csv -Path $path -Delimiter $delimiter
        $pendientes = $datos | Where-Object { $_.estado -ne "creado" }

        Write-Log "Registros pendientes: $($pendientes.Count)"
        if ($pendientes.Count -eq 0) {
            Write-Log "No hay registros pendientes. Ejecutando Python: $pythonScript"
            try {
                & python $pythonScript
                Write-Log "Script Python ejecutado correctamente"
            }
            catch {
                Write-Log "Error al ejecutar Python: $_" "ERROR"
                return
            }
            Start-Sleep -Seconds 5
        }
    } while ($pendientes.Count -eq 0)

    foreach ($fila in $pendientes) {
        Write-Log "Procesando usuario: $($fila.usuario)"
        $resultado = Crear-Usuario `
            -Name        $fila.usuario `
            -FullName    $fila.nombre_completo `
            -Description $fila.descripcion `
            -Password    $fila.password `
            -Privilegios $fila.privilegios

        Write-Log "Resultado para '$($fila.usuario)': $resultado"
        $fila.estado = $resultado
    }

    Write-Log "Guardando cambios en '$path'"
    # Usar UseQuotes AsNeeded para evitar comillas innecesarias (PS 7+)
    $datos |
      Export-Csv -Path $path `
                 -NoTypeInformation `
                 -Delimiter $delimiter `
                 -UseQuotes AsNeeded

    Write-Log "Tarea Leer-CSV completada"
}

function Crear-Usuario {
    param (
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)][string] $FullName,
        [Parameter(Mandatory)][string] $Description,
        [Parameter(Mandatory)][string] $Password,
        [Parameter(Mandatory)][string] $Privilegios
    )

    # 1) Verificar permisos
    if (-not ([Security.Principal.WindowsPrincipal] `
               [Security.Principal.WindowsIdentity]::GetCurrent()
              ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Log "Permisos insuficientes para crear '$Name'. Ejecuta como Administrador." "ERROR"
        return "error_permisos"
    }

    # 2) Validar complejidad de contraseña (igual que antes)…
    $errorMsg = $null
    if ($Password.Length -lt 8)                { $errorMsg = "Mínimo 8 caracteres" }
    elseif ($Password -notmatch "[A-Z]")       { $errorMsg = "Debe tener al menos una mayúscula" }
    elseif ($Password -notmatch "[a-z]")       { $errorMsg = "Debe tener al menos una minúscula" }
    elseif ($Password -notmatch "\d")          { $errorMsg = "Debe tener al menos un número" }
    elseif ($Password -notmatch "[^a-zA-Z0-9]"){ $errorMsg = "Debe tener al menos un carácter especial" }
    if ($errorMsg) {
        Write-Log "Usuario '$Name': $errorMsg" "ERROR"
        return "error_contraseña"
    }

    # 3) Crear usuario y verificar
    try {
        $securePass = ConvertTo-SecureString $Password -AsPlainText -Force

        New-LocalUser -Name "$Name" `
                      -FullName "$FullName" `
                      -Description "$Description" `
                      -Password $securePass `
                      -PasswordNeverExpires:$false `
                      -ErrorAction Stop

        # comprobación inmediata
        if (Get-LocalUser -Name $Name -ErrorAction SilentlyContinue) {
            Write-Log "Verificado: usuario '$Name' creado correctamente." "INFO"
        }
        else {
            Write-Log "¡Error!: usuario '$Name' NO fue encontrado tras New-LocalUser." "ERROR"
            return "error_verificacion"
        }

        # 4) Agregar al grupo y verificar
        Add-LocalGroupMember -Group $Privilegios -Member $Name -ErrorAction Stop

        if (Get-LocalGroupMember -Group $Privilegios -Member $Name -ErrorAction SilentlyContinue) {
            Write-Log "Verificado: '$Name' es miembro de '$Privilegios'." "INFO"
        }
        else {
            Write-Log "¡Atención!: '$Name' NO pertenece a '$Privilegios'." "WARN"
        }

        return "creado"
    }
    catch {
        Write-Log "Error creando '$Name': $($_.Exception.Message)" "ERROR"
        return "error_creación"
    }
}


# Ejecutar el proceso
Leer-CSV
