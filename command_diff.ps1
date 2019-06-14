##----------------------------------------------------------------------------##
## �����̎w��i�Q�̃t�@�C�����w��j
##----------------------------------------------------------------------------##
param($file1, $file2, $cmd)

##----------------------------------------------------------------------------##
## ���C������
##----------------------------------------------------------------------------##
function Main($readFile1, $readFile2, $targetCmd)
{
    $program_diff = load_ini_file ".\command_diff.ini"

    if ($program_diff -eq $NULL) {
        return
    }

    Write-Host "`$program_diff = "$program_diff

    if (-Not($readFile1) -And -Not($readFile2)) {
        $files = SelectFile_Multi "��r�������t�@�C����I�����Ă��������B�iCTRL+�łQ�����ɑI���j"
        if ($files -eq $NULL) {
            return
        }
        if ($files.Count -eq 2) {
            $readFile1 = $files[0]
            $readFile2 = $files[1]
        }
        elseif ($files.Count -eq 1) {
            $readFile1 = $files
        }
    }

    if (-Not($readFile1) -Or -Not(Test-Path $readFile1)) {
        $readFile1 = SelectFile "�P�߂̃t�@�C����I�����Ă��������B"

        if ($readFile1 -eq $NULL) {
            return
        }
    }
    if ($readFile1 -ne $NULL) {
        Write-Host "`$readFile1 = "$readFile1
#       Get-Content $readFile1
    }

    if (-Not($readFile2) -Or -Not(Test-Path $readFile2)) {
        $readFile2 = SelectFile "�Q�߂̃t�@�C����I�����Ă��������B"

        if ($readFile1 -eq $NULL) {
            return
        }
    }
    if ($readFile2 -ne $NULL) {
        Write-Host "`$readFile2 = "$readFile2
#       Get-Content $readFile2
    }

    if (-Not($targetCmd)) {
        $targetCmd = set_Cmd

        if ($targetCmd -eq "") {
            return
        }
    }

    Write-Host "`$targetCmd = "$targetCmd

    $prefix = $targetCmd -replace " ", "_"
    $prefix += "_"

    # $readFile1 �� "show ip route"�̎��s���ʕ������擾����
    $route1 = get_show_command $readFile1 $targetCmd
    $result_readFile1 = setResultFileName $readFile1 $prefix  ".txt"

    Write-Output $route1 | Out-File $result_readFile1 -Encoding default

    # $readFile2 �� "show ip route"�̎��s���ʕ������擾����
    $route2 = get_show_command $readFile2 $targetCmd
    $result_readFile2 = setResultFileName $readFile2 $prefix ".txt"

    Write-Output $route2 | Out-File $result_readFile2 -Encoding default

    $result_readFile1 = $result_readFile1 -replace "^\.\\", ""
    $result_readFile2 = $result_readFile2 -replace "^\.\\", ""

    # diff�R�}���h�N��
    & $program_diff $result_readFile1 $result_readFile2

}

##----------------------------------------------------------------------------##
## ini�t�@�C���̓ǂݍ���
##----------------------------------------------------------------------------##
function load_ini_file($fileName_INI)
{
    if (-Not(Test-Path $fileName_INI)) {
        Write-Host $fileName_INI" ������܂���B"
        return $NULL
    }

    $f = (Get-Content $fileName_INI) -as [string[]]

    foreach ($currentLine in $f) {
        if ($currentLine.Length -eq 0) {
            continue
        }

        $currentLine = $currentLine -replace "#.*$", ""
        $currentLine = $currentLine -replace "//.*$", ""
        $currentLine = $currentLine -replace " = ", "="
        $currentLine = $currentLine -replace " =", "="
        $currentLine = $currentLine -replace "= ", "="

        $pos = $currentLine.IndexOf("path_diff=")

        if ($pos -ge 0) {
            $cmd, $program_diff = $currentLine -split "="

            if ($program_diff -eq "") {
                return $NULL
            }

            $program_diff = $program_diff -replace "`"", ""

            if (-Not(Test-Path $program_diff)) {
                Write-Host $program_diff" ��������܂���B"
                return $NULL
            }

            return $program_diff
        }
    }

    Write-Host "path_diff �̃G���g����������܂���ł����B"
    return $NULL
}

##----------------------------------------------------------------------------##
## �t�@�C���I���_�C�A���O�̋N���i�P��t�@�C���j
##----------------------------------------------------------------------------##
function SelectFile($message)
{
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")

    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "log�t�@�C��(*.log;*.txt;*.*)|*.log;*.txt;*.*"
    $dialog.InitialDirectory = Get-Location
    $dialog.Title = $message

    # �_�C�A���O��\��
    if($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){
       return $dialog.FileName
    }
    else {
        return $NULL
    }
}

##----------------------------------------------------------------------------##
## �t�@�C���I���_�C�A���O�̋N���i�����t�@�C���I���j
##----------------------------------------------------------------------------##
function SelectFile_Multi($message)
{
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")

    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "log�t�@�C��(*.log;*.txt;*.*)|*.log;*.txt;*.*"
    $dialog.InitialDirectory = Get-Location
    $dialog.Title = $message
    # �����I���������������� Multiselect ��ݒ肷��
    $dialog.Multiselect = $true

    # �_�C�A���O��\��
    if($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){
        # �����I���������Ă��鎞�� $dialog.FileNames �𗘗p����
       return $dialog.FileNames
    }
    else {
        return $NULL
    }
}

##----------------------------------------------------------------------------##
## ���퐫���O���猟������R�}���h���Z�b�g����
##----------------------------------------------------------------------------##
function set_cmd()
{
    # �A�Z���u���̓ǂݍ���
    [void][System.Reflection.Assembly]::Load("Microsoft.VisualBasic, Version=8.0.0.0, Culture=Neutral, PublicKeyToken=b03f5f7f11d50a3a")

    # �C���v�b�g�{�b�N�X�̕\��
    $INPUT = [Microsoft.VisualBasic.Interaction]::InputBox("��r�������R�}���h����͂��Ă��������B", "��������R�}���h�̎w��")

    return $INPUT
}


##----------------------------------------------------------------------------##
## ���퐫���O���� $cmd �̎��s���ʕ������擾����
##----------------------------------------------------------------------------##
function get_show_command($file, $cmd)
{
    $f = (Get-Content $file) -as [string[]]
    $cmd_read = $FALSE
    $route_count = 0

    $prompt = @()
    $prompt += "#"
    $prompt += ">"

    foreach ($currentLine in $f) {
        if ($currentLine.Length -eq 0) {
            continue
        }

        if ($cmd_read -eq $FALSE) {
            ##---------------------------------------------##
            ## �ΏۃR�}���h����������
            ##---------------------------------------------##
            $show_cmd_start = $currentLine.IndexOf($cmd)

            if ($show_cmd_start -eq -1) {
                continue
            }

            # �R�}���h�ɑ��̃I�v�V�������܂܂�Ă����ꍇ�́A�ΏۊO�Ƃ���
            <#
            if (($currentLine.Length - $cmd.Length) -ne $show_cmd_start) {
                continue
            }
            #>

            ##---------------------------------------------##
            ## �v�����v�g�����o����
            ##---------------------------------------------##
            $current_prompt = ""
            $pos_min = 255
            foreach ($pt in $prompt) {
                $pos_prompt = $currentLine.IndexOf($pt)

                if ($pos_prompt -ge 0) {
                    if ($pos_prompt -lt $pos_min) {
                        $pos_min = $pos_prompt
                        $current_prompt = $currentLine.Substring(0, $pos_prompt + 1)
                    }
                }
            }

            if ($current_prompt -eq "") {
                continue
            }

            $cmd_read = $TRUE
            $ip_route += $currentLine + "`r`n"
            continue
        }
        else {
            ##---------------------------------------------##
            ## �ΏۃR�}���h�̊J�n�s�����������ꍇ
            ##---------------------------------------------##
            $workStr = $currentLine
            <#
            $workStr = $currentLine -replace ", *y*, ", ""
            $workStr = $workStr -replace ", *w*, ", ""
            $workStr = $workStr -replace ", *d*, ", ""
            $workStr = $workStr -replace ", *h*, ", ""
            #>
            $workStr = $workStr -replace "..:..:..", "__:__:__"
            $ip_route += $workStr + "`r`n"

            $route_count++

            if ($route_count -le 1) {
                continue
            }

            $pos_prompt = $currentLine.IndexOf($current_prompt)

            if ($pos_prompt -ge 0) {
                # ���̃v�����v�g�����������猟�����I����
                return $ip_route
            }
        }
    }

    return $NULL
}

##----------------------------------------------------------------------------##
## �t�@�C���̃p�X����f�B���N�g���̃p�X���擾����
##----------------------------------------------------------------------------##
function getDirPath($fileName)
{
    $pos = $fileName.LastIndexOf("\")

    if ($pos -ge 0) {
        return $fileName.Substring(0, $pos)
    }
    else {
        return $FALSE
    }

}

##----------------------------------------------------------------------------##
## �t�@�C���̃p�X����t�@�C�������擾����
##----------------------------------------------------------------------------##
function getFileName($fileName)
{
    $pos = $fileName.LastIndexOf("\")

    if ($pos -ge 0) {
        return $fileName.Substring($pos + 1)
    }
    else {
        return $FALSE
    }

}

##----------------------------------------------------------------------------##
## �g���q����菜�������O��Ԃ�
##----------------------------------------------------------------------------##
function removeExtensionName($fileName)
{
    $pos = $fileName.LastIndexOf(".")

    if ($pos -ge 0) {
        return $fileName.Substring(0, $pos)
    }
    else {
        return $FALSE
    }
}

##----------------------------------------------------------------------------##
## �o�̓t�@�C�������Z�b�g����
##----------------------------------------------------------------------------##
function setResultFileName($fileName, $pre_str, $post_str)
{
    $result_DirPath = getDirPath $fileName
    $result_FileName = getFileName $fileName
    $result_firstFileName = removeExtensionName $result_FileName

    return $result_DirPath + "\" + $pre_str + $result_firstFileName + $post_str
}

##----------------------------------------------------------------------------##
## Main�Ăяo��
##----------------------------------------------------------------------------##

Main $file1 $file2 $cmd
