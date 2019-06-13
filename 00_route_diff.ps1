##----------------------------------------------------------------------------##
## �����̎w��i�Q�̃t�@�C�����w��j
##----------------------------------------------------------------------------##
param($arg1, $arg2)

# diff�c�[���̎w��
$program_diff = "D:\share\�c�[���Q\df141\DF.exe"
$show_cmd = "show ip route vrf"

##----------------------------------------------------------------------------##
## ���C������
##----------------------------------------------------------------------------##
function Main($file1, $file2)
{
    if (-Not($file1) -And -Not($file2)) {
        $files = SelectFile_Multi "��r�������t�@�C����I�����Ă��������B�iCTRL+�łQ�����ɑI���j"
        if ($files -eq $NULL) {
            return
        }
        if ($files.Count -eq 2) {
            $file1 = $files[0]
            $file2 = $files[1]
        }
        elseif ($files.Count -eq 1) {
            $file1 = $files
        }
    }

    if (-Not($file1)) {
        $file1 = SelectFile "�P�߂̃t�@�C����I�����Ă��������B"
    }
    if ($file1 -ne $NULL) {
        Write-Host "`$file1 = "$file1
#       Get-Content $file1
    }

    if (-Not($file2)) {
        $file2 = SelectFile "�Q�߂̃t�@�C����I�����Ă��������B"
    }
    if ($file2 -ne $NULL) {
        Write-Host "`$file2 = "$file2
#       Get-Content $file2
    }

    # $file1 �� "show ip route"�̎��s���ʕ������擾����
    $route1 = get_show_command $file1 $show_cmd
    $result_file1 = setResultFileName $file1 "route_"  ".txt"

    Write-Output $route1 | Out-File $result_file1 -Encoding default

    # $file2 �� "show ip route"�̎��s���ʕ������擾����
    $route2 = get_show_command $file2 $show_cmd
    $result_file2 = setResultFileName $file2 "route_" ".txt"

    Write-Output $route2 | Out-File $result_file2 -Encoding default

    # diff�R�}���h�N��
    & $program_diff $result_file1 $result_file2

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
## ���퐫���O���� $cmd �̎��s���ʕ������擾����
##----------------------------------------------------------------------------##
function get_show_command($file, $cmd)
{
    $f = (Get-Content $file) -as [string[]]
    $read_route = $FALSE
    $route_count = 0

    foreach ($currentLine in $f) {
        if ($currentLine.Length -eq 0) {
            continue
        }

        if ($read_route -eq $FALSE) {
            ##---------------------------------------------##
            ## �ΏۃR�}���h����������
            ##---------------------------------------------##
            $prompt = $currentLine.IndexOf("#")

            if ($prompt -eq -1) {
                continue
            }

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

            $read_route = $TRUE
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


            $prompt = $currentLine.IndexOf("#")

            if ($prompt -gt 0) {
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

Main $arg1 $arg2
