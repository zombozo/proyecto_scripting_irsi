




function crear_usuario() {
    parm(
        [string] $Name,
        [string] $FullName,
        [string] $Description,
        [string] $Password
    )

    New-LocalUser   -Name "" `
                    -FullName "" `
                    -Description "" `
                    -Password $Password `
                    -PasswordNeverExpires:$false

    Add-LocalGroupMember -Group "Administrators" -Member $Name
}

crear_usuario "olivares" "Gerson Olivares" "Este es mi usuario" "olivares"