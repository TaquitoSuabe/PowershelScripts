[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

$sshDir = "$env:USERPROFILE\.ssh"

function Show-Menu {
    Clear-Host
    Write-Host "
   ██████  ██████  ██   ██     ███    ███  █████  ███    ██  █████   ██████  ███████ ██████  
  ██      ██       ██   ██     ████  ████ ██   ██ ████   ██ ██   ██ ██       ██      ██   ██ 
  ██████  ██████   ███████     ██ ████ ██ ███████ ██ ██  ██ ███████ ██   ███ █████   ██████  
       ██      ██  ██   ██     ██  ██  ██ ██   ██ ██  ██ ██ ██   ██ ██    ██ ██      ██   ██ 
  ██████  ██████   ██   ██     ██      ██ ██   ██ ██   ████ ██   ██  ██████  ███████ ██   ██ 
                                                                                             
    " -ForegroundColor Green
    Write-Host "   [ SISTEMA LISTO ] :: @TaquitoSuabe" -ForegroundColor DarkGray
    Write-Host "   =====================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "   [1] :: GENERAR NUEVO PAR DE CLAVES" -ForegroundColor White
    Write-Host "   [2] :: DESPLEGAR CLAVE AL SERVIDOR" -ForegroundColor White
    Write-Host "   [3] :: LISTAR PARES DE CLAVES" -ForegroundColor White
    Write-Host "   [4] :: ELIMINAR PAR DE CLAVES" -ForegroundColor White
    Write-Host "   [5] :: TERMINAR SESION" -ForegroundColor White
    Write-Host ""
    Write-Host "   SELECCIONA OPERACION >> " -NoNewline -ForegroundColor Green
}

function New-SSHKeyPair {
    Clear-Host
    Write-Host "`n   [+] INICIANDO SECUENCIA DE GENERACION DE CLAVES..." -ForegroundColor Green
    
    if (-not (Test-Path $sshDir)) {
        New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
        Write-Host "   [*] Directorio .ssh inicializado." -ForegroundColor DarkGray
    }
    
    Write-Host "   [?] INGRESA IDENTIFICADOR DE CLAVE (ej. server01): " -NoNewline -ForegroundColor White
    $keyName = Read-Host
    $KeyPath = "$sshDir\$keyName"
    
    if (Test-Path $KeyPath) {
        Write-Host "   [!] ADVERTENCIA: LA CLAVE YA EXISTE." -ForegroundColor Red
        Write-Host "   [?] SOBRESCRIBIR? (S/N): " -NoNewline -ForegroundColor White
        $respuesta = Read-Host
        if ($respuesta -ne 'Y' -and $respuesta -ne 'y' -and $respuesta -ne 'S' -and $respuesta -ne 's') {
            Write-Host "   [-] ABORTADO." -ForegroundColor Red
            return
        }
        Remove-Item $KeyPath -Force
        Remove-Item "$KeyPath.pub" -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host "   [?] ENCRIPTAR CON PASSWORD? (S/N): " -NoNewline -ForegroundColor White
    $conPass = Read-Host
    
    Write-Host "`n   [+] GENERANDO PAR RSA DE 4096-BITS..." -ForegroundColor Green
    
    if ($conPass -eq 'S' -or $conPass -eq 's' -or $conPass -eq 'Y' -or $conPass -eq 'y') {
        ssh-keygen -t rsa -b 4096 -f $KeyPath
    } else {
        ssh-keygen -t rsa -b 4096 -f $KeyPath -N ""
    }
    
    Write-Host "`n   --------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "   [+] CLAVE PUBLICA GENERADA:" -ForegroundColor Green
    Write-Host "   --------------------------------------------------" -ForegroundColor DarkGray
    if (Test-Path "$KeyPath.pub") { 
        Get-Content "$KeyPath.pub"
        Write-Host "`n   [+] GUARDADO EN: $KeyPath.pub" -ForegroundColor Green
    }
    
    Write-Host "`n   [EXITO] PAR DE CLAVES GENERADO." -ForegroundColor Green
    Write-Host "`n   [PRESIONA ENTER PARA CONTINUAR]" -NoNewline -ForegroundColor DarkGray
    Read-Host
}

function Send-SSHKeyToServer {
    Clear-Host
    Write-Host "`n   [+] INICIANDO PROTOCOLO DE DESPLIEGUE..." -ForegroundColor Green
    
    Write-Host "`n   [*] CLAVES DISPONIBLES:" -ForegroundColor DarkGray
    $keys = Get-ChildItem "$sshDir\*.pub" -ErrorAction SilentlyContinue
    
    if ($keys.Count -eq 0) {
        Write-Host "No hay claves publicas disponibles. Genera una primero." -ForegroundColor Red
        Read-Host "`n   [PRESIONA ENTER PARA CONTINUAR]"
        return
    }
    
    for ($i = 0; $i -lt $keys.Count; $i++) {
        Write-Host "   [$($i+1)] $($keys[$i].BaseName)" -ForegroundColor Cyan
    }
    
    Write-Host "`n   [?] SELECCIONA INDICE DE CLAVE: " -NoNewline -ForegroundColor White
    $seleccion = Read-Host
    
    if ($seleccion -lt 1 -or $seleccion -gt $keys.Count) {
        Write-Host "   [!] SELECCION INVALIDA." -ForegroundColor Red
        Read-Host "`n   [PRESIONA ENTER PARA CONTINUAR]"
        return
    }
    
    $keyToUpload = $keys[$seleccion - 1].FullName
    
    Write-Host "`n   --- PARAMETROS DEL OBJETIVO ---" -ForegroundColor DarkGray
    Write-Host "   [?] USUARIO: " -NoNewline -ForegroundColor White
    $usuario = Read-Host
    Write-Host "   [?] HOST/IP:  " -NoNewline -ForegroundColor White
    $servidor = Read-Host
    
    Write-Host "`n   [+] SUBIENDO CLAVE AL OBJETIVO..." -ForegroundColor Green
    
    $pubKeyContent = Get-Content $keyToUpload -Raw
    
    try {
        Write-Host "   [*] ESTABLECIENDO CONEXION A $usuario@$servidor..." -ForegroundColor Cyan
        
        $tempScript = "$env:TEMP\ssh_upload_$(Get-Random).sh"
        
        Write-Host "`n   [!] AUTENTICACION REQUERIDA. INGRESA PASSWORD SI SE SOLICITA." -ForegroundColor Yellow
        
        $cleanPubKey = $pubKeyContent.Trim().Replace("`r", "").Replace("`n", "")
        
        $sshCommand = "mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo '$cleanPubKey' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
        
        ssh "$usuario@$servidor" $sshCommand
        
        Write-Host "`n   [EXITO] CLAVE DESPLEGADA EXITOSAMENTE." -ForegroundColor Green
        Write-Host "   [INFO] PRUEBA CONEXION: ssh -i $($keys[$seleccion - 1].FullName.Replace('.pub','')) $usuario@$servidor" -ForegroundColor DarkGray
        
        $keyPathPrivate = $keys[$seleccion - 1].FullName.Replace('.pub','')
        
        Write-Host "`n   [?] CONFIGURAR ALIAS SSH? (S/N): " -NoNewline -ForegroundColor White
        $crearAlias = Read-Host
        $aliasName = ""
        
        if ($crearAlias -eq 'S' -or $crearAlias -eq 's' -or $crearAlias -eq 'Y' -or $crearAlias -eq 'y') {
            Write-Host "   [?] INGRESA NOMBRE DEL ALIAS (ej. target-01): " -NoNewline -ForegroundColor White
            $aliasName = Read-Host
            $configPath = "$sshDir/config"
            if (-not (Test-Path $configPath)) { New-Item -Path $configPath -ItemType File -Force | Out-Null }
            
            $configEntry = "`nHost $aliasName`n    HostName $servidor`n    User $usuario`n    IdentityFile $keyPathPrivate`n"
            
            Add-Content -Path $configPath -Value $configEntry -Encoding UTF8
            Write-Host "   [+] ALIAS '$aliasName' AGREGADO A CONFIG." -ForegroundColor Green
        }
        
        Write-Host "`n   [?] CREAR ACCESO DIRECTO EN ESCRITORIO? (S/N): " -NoNewline -ForegroundColor White
        $crearShortcut = Read-Host
        
        if ($crearShortcut -eq 'S' -or $crearShortcut -eq 's' -or $crearShortcut -eq 'Y' -or $crearShortcut -eq 'y') {
            $desktopDir = [Environment]::GetFolderPath("Desktop")
            
            if (Test-Path $desktopDir) {
                $shortcutName = if ($aliasName) { $aliasName } else { "$usuario-$servidor" }
                $shortcutPath = "$desktopDir\$shortcutName.lnk"
                
                $sshCmd = if ($aliasName) { "ssh -i `"$keyPathPrivate`" $aliasName" } else { "ssh -i `"$keyPathPrivate`" $usuario@$servidor" }
                
                try {
                    $WshShell = New-Object -ComObject WScript.Shell
                    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
                    $Shortcut.TargetPath = "cmd.exe"
                    $Shortcut.Arguments = "/c $sshCmd & pause"
                    $Shortcut.IconLocation = "cmd.exe"
                    $Shortcut.Description = "Conectar a $shortcutName via SSH"
                    $Shortcut.Save()
                    
                    Write-Host "   [+] ACCESO DIRECTO CREADO: $shortcutPath" -ForegroundColor Green
                } catch {
                    Write-Host "   [!] ERROR CREANDO ACCESO DIRECTO: $_" -ForegroundColor Red
                }
            } else {
                Write-Host "   [!] DIRECTORIO DESKTOP NO ENCONTRADO." -ForegroundColor Red
            }
        }
        
        Remove-Item $tempScript -ErrorAction SilentlyContinue
        
    } catch {
        Write-Host "`n   [!] FALLO EL DESPLIEGUE: $_" -ForegroundColor Red
        Write-Host "`n   [OVERRIDE MANUAL] EJECUTAR EN OBJETIVO:" -ForegroundColor Yellow
        Write-Host "   echo '$pubKeyContent' >> ~/.ssh/authorized_keys" -ForegroundColor White
    }
    
    Write-Host "`n   [PRESIONA ENTER PARA CONTINUAR]" -NoNewline -ForegroundColor DarkGray
    Read-Host
}

function Show-SSHKeys {
    Clear-Host
    Write-Host "`n   [+] ESCANEANDO PARES DE CLAVES..." -ForegroundColor Green
    
    $privateKeys = Get-ChildItem "$sshDir\*" -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq "" -and (Test-Path "$($_.FullName).pub") }
    
    if ($privateKeys.Count -eq 0) {
        Write-Host "   [!] NO SE ENCONTRARON ARTEFACTOS." -ForegroundColor Red
    } else {
        foreach ($key in $privateKeys) {
            Write-Host "`n   [*] IDENTIDAD: $($key.Name)" -ForegroundColor Cyan
            Write-Host "       Privada: $($key.FullName)" -ForegroundColor DarkGray
            Write-Host "       Publica: $($key.FullName).pub" -ForegroundColor DarkGray
            Write-Host "       Tamano:  $([math]::Round($key.Length/1KB, 2)) KB" -ForegroundColor DarkGray
            Write-Host "       Mod:     $($key.LastWriteTime)" -ForegroundColor DarkGray
            Write-Host "   --------------------------------------------------" -ForegroundColor DarkGray
        }
    }
    
    Write-Host "`n   [PRESIONA ENTER PARA CONTINUAR]" -NoNewline -ForegroundColor DarkGray
    Read-Host
}

function Remove-SSHKeyPair {
    Clear-Host
    Write-Host "`n   [!] INICIANDO SECUENCIA DE ELIMINACION..." -ForegroundColor Red
    
    $privateKeys = Get-ChildItem "$sshDir\*" -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq "" -and (Test-Path "$($_.FullName).pub") }
    
    if ($privateKeys.Count -eq 0) {
        Write-Host "   [!] NO SE ENCONTRARON OBJETIVOS." -ForegroundColor Red
        Read-Host "`n   [PRESIONA ENTER PARA CONTINUAR]"
        return
    }
    
    Write-Host "`n   [*] OBJETIVOS:" -ForegroundColor DarkGray
    for ($i = 0; $i -lt $privateKeys.Count; $i++) {
        Write-Host "   [$($i+1)] $($privateKeys[$i].Name)" -ForegroundColor Cyan
    }
    
    Write-Host "`n   [?] SELECCIONA INDICE DE OBJETIVO (0 PARA CANCELAR): " -NoNewline -ForegroundColor White
    $seleccion = Read-Host
    
    if ($seleccion -eq "0") {
        Write-Host "   [-] OPERACION CANCELADA." -ForegroundColor Yellow
        Read-Host "`n   [PRESIONA ENTER PARA CONTINUAR]"
        return
    }
    
    if ($seleccion -lt 1 -or $seleccion -gt $privateKeys.Count) {
        Write-Host "   [!] SELECCION INVALIDA." -ForegroundColor Red
        Read-Host "`n   [PRESIONA ENTER PARA CONTINUAR]"
        return
    }
    
    $keyToDelete = $privateKeys[$seleccion - 1]
    Write-Host "   [!] ADVERTENCIA: ELIMINANDO PERMANENTEMENTE '$($keyToDelete.Name)'" -ForegroundColor Red
    Write-Host "   [?] CONFIRMAR ELIMINACION? (S/N): " -NoNewline -ForegroundColor White
    $confirmacion = Read-Host
    
    if ($confirmacion -eq 'S' -or $confirmacion -eq 's' -or $confirmacion -eq 'Y' -or $confirmacion -eq 'y') {
        
        $configPath = "$sshDir/config"
        if (Test-Path $configPath) {
            $configContent = Get-Content $configPath -Raw
            $keyPathRegex = [regex]::Escape($keyToDelete.FullName)
            
            $lines = Get-Content $configPath
            $newLines = @()
            $skipBlock = $false
            $aliasRemoved = ""
            
            for ($j = 0; $j -lt $lines.Count; $j++) {
                $line = $lines[$j]
                
                if ($line -match "^\s*Host\s+(.+)") {
                    $currentHost = $matches[1]
                    $isTargetBlock = $false
                    for ($k = $j + 1; $k -lt $lines.Count; $k++) {
                        if ($lines[$k] -match "^\s*Host\s+") { break } 
                        if ($lines[$k] -match "IdentityFile.*$keyPathRegex") {
                            $isTargetBlock = $true
                            break
                        }
                    }
                    
                    if ($isTargetBlock) {
                        $skipBlock = $true
                        $aliasRemoved = $currentHost
                        Write-Host "   [+] ELIMINANDO ALIAS DE CONFIG: $aliasRemoved" -ForegroundColor Yellow
                    } else {
                        $skipBlock = $false
                    }
                }
                
                if (-not $skipBlock) {
                    $newLines += $line
                }
            }
            
            if ($aliasRemoved) {
                $newLines | Out-File -FilePath $configPath -Encoding UTF8
            }
        }
        
        $desktopDir = [Environment]::GetFolderPath("Desktop")
        if (Test-Path $desktopDir) {
            $shortcuts = Get-ChildItem "$desktopDir\*.lnk"
            $WshShell = New-Object -ComObject WScript.Shell
            
            foreach ($lnkFile in $shortcuts) {
                try {
                    $shortcut = $WshShell.CreateShortcut($lnkFile.FullName)
                    if ($shortcut.Arguments -match [regex]::Escape($keyToDelete.FullName)) {
                        Remove-Item $lnkFile.FullName -Force
                        Write-Host "   [+] ACCESO DIRECTO ELIMINADO: $($lnkFile.Name)" -ForegroundColor Yellow
                    }
                } catch {}
            }
        }

        Remove-Item $keyToDelete.FullName -Force
        Remove-Item "$($keyToDelete.FullName).pub" -Force -ErrorAction SilentlyContinue
        Write-Host "`n   [EXITO] OBJETIVO ELIMINADO (CLAVES, ALIAS Y ACCESOS DIRECTOS)." -ForegroundColor Green
    } else {
        Write-Host "   [-] OPERACION ABORTADA." -ForegroundColor Yellow
    }
    
    Write-Host "`n   [PRESIONA ENTER PARA CONTINUAR]" -NoNewline -ForegroundColor DarkGray
    Read-Host
}

do {
    Show-Menu
    $opcion = Read-Host
    
    switch ($opcion) {
        "1" { New-SSHKeyPair }
        "2" { Send-SSHKeyToServer }
        "3" { Show-SSHKeys }
        "4" { Remove-SSHKeyPair }
        "5" { 
            Write-Host "`n   [SISTEMA] TERMINANDO SESION..." -ForegroundColor Green
            exit 
        }
        default { 
            Write-Host "`n   [!] COMANDO INVALIDO." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($true)
