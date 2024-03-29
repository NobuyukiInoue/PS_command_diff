##----------------------------------------------------------------------------##
## 引数の指定
## $file1 ... １つめのファイル
## $file2 ... ２つめのファイル
## $cmd   ... diffで比較したい抽出対象コマンド
## $match ... コマンド完全一致（TRUE)／コマンド部分一致（FALSE)の指定
##----------------------------------------------------------------------------##
param($file1, $file2, $cmd, $match)

##----------------------------------------------------------------------------##
## メイン処理
##----------------------------------------------------------------------------##
function Main($readFile1, $readFile2, $targetCmd, $match)
{
    $match_mode = $FALSE

    # 完全一致／部分一致の選択
    if ($match) {
        $upper_match = $match.ToUpper()
        if ($upper_match -eq "TRUE") {
            $match_mode = $TRUE
        }
    }

    # INIファイルの読み込みとdiffツールのセット
    $program_diff = load_ini_file ".\command_diff.ini"

    if ($NULL -eq $program_diff) {
        return
    }

    Write-Host "`$program_diff = "$program_diff

    if (-Not($readFile1) -And -Not($readFile2)) {
        $files = SelectFile_Multi "比較したいファイルを選択してください。（CTRL+で２つ同時に選択可）"
        if ($NULL -eq $files) {
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
        $readFile1 = SelectFile "１つめのファイルを選択してください。"

        if ($NULL -eq $readFile1) {
            return
        }
    }
    if ($NULL -ne $readFile1) {
        Write-Host "`$readFile1 = "$readFile1
#       Get-Content $readFile1
    }

    if (-Not($readFile2) -Or -Not(Test-Path $readFile2)) {
        $readFile2 = SelectFile "２つめのファイルを選択してください。"

        if ($NULL -eq $readFile1) {
            return
        }
    }
    if ($NULL -ne $readFile2) {
        Write-Host "`$readFile2 = "$readFile2
#       Get-Content $readFile2
    }

    if (-Not($targetCmd)) {
        # inputboxを表示して検索したいコマンドを受け取る
        $targetCmd = set_Cmd $match_mode

        if ($targetCmd -eq "") {
            return
        }
    }

    Write-Host "`$targetCmd = "$targetCmd

    # 出力するファイルの名前に付加する接頭文字列のセット
    $prefix = $targetCmd -replace " ", "_"
    $prefix += "_"

    # $readFile1 の[検索対象コマンド]の実行結果部分を取得する
    $route1 = get_show_command $readFile1 $targetCmd $match_mode
    $result_readFile1 = setResultFileName $readFile1 $prefix  ".txt"

    Write-Output $route1 | Out-File $result_readFile1 -Encoding default

    # $readFile2 の[検索対象コマンド]の実行結果部分を取得する
    $route2 = get_show_command $readFile2 $targetCmd $match_mode
    $result_readFile2 = setResultFileName $readFile2 $prefix ".txt"

    Write-Output $route2 | Out-File $result_readFile2 -Encoding default

    # 行頭の"./"を取り除く
    $result_readFile1 = $result_readFile1 -replace "^\.\\", ""
    $result_readFile2 = $result_readFile2 -replace "^\.\\", ""

    # diffコマンド起動
    & $program_diff $result_readFile1 $result_readFile2

}

##----------------------------------------------------------------------------##
## iniファイルの読み込み
##----------------------------------------------------------------------------##
function load_ini_file($fileName_INI)
{
    if (-Not(Test-Path $fileName_INI)) {
        Write-Host $fileName_INI" がありません。"
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
                Write-Host $program_diff" が見つかりません。"
                return $NULL
            }

            return $program_diff
        }
    }

    Write-Host "path_diff のエントリが見つかりませんでした。"
    return $NULL
}

##----------------------------------------------------------------------------##
## ファイル選択ダイアログの起動（単一ファイル）
##----------------------------------------------------------------------------##
function SelectFile($message)
{
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")

    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "logファイル(*.log;*.txt;*.*)|*.log;*.txt;*.*"
    $dialog.InitialDirectory = Get-Location
    $dialog.Title = $message

    # ダイアログを表示
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
       return $dialog.FileName
    }
    else {
        return $NULL
    }
}

##----------------------------------------------------------------------------##
## ファイル選択ダイアログの起動（複数ファイル選択可）
##----------------------------------------------------------------------------##
function SelectFile_Multi($message)
{
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")

    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "logファイル(*.log;*.txt;*.*)|*.log;*.txt;*.*"
    $dialog.InitialDirectory = Get-Location
    $dialog.Title = $message
    # 複数選択を許可したい時は Multiselect を設定する
    $dialog.Multiselect = $true

    # ダイアログを表示
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        # 複数選択を許可している時は $dialog.FileNames を利用する
       return $dialog.FileNames
    }
    else {
        return $NULL
    }
}

##----------------------------------------------------------------------------##
## 正常性ログから検索するコマンドをセットする
##----------------------------------------------------------------------------##
function set_cmd($match_mode)
{
    # アセンブリの読み込み
    [void][System.Reflection.Assembly]::Load("Microsoft.VisualBasic, Version=8.0.0.0, Culture=Neutral, PublicKeyToken=b03f5f7f11d50a3a")

    # インプットボックスの表示
    if ($match_mode) {
        $INPUT = [Microsoft.VisualBasic.Interaction]::InputBox("比較したいコマンドを入力してください(完全一致)", "検索するコマンドの指定")
    }
    else {
        $INPUT = [Microsoft.VisualBasic.Interaction]::InputBox("比較したいコマンドを入力してください(部分一致)", "検索するコマンドの指定")
    }

    return $INPUT
}


##----------------------------------------------------------------------------##
## 正常性ログから $cmd の実行結果部分を取得する
##----------------------------------------------------------------------------##
function get_show_command($file, $cmd, $match_mode)
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
            ## 対象コマンドを検索する
            ##---------------------------------------------##
            $show_cmd_start = $currentLine.IndexOf($cmd)

            if ($show_cmd_start -eq -1) {
                continue
            }

            if ($match_mode) {
                # コマンドに他のオプションが含まれていた場合は、対象外とする
                if (($currentLine.Length - $cmd.Length) -ne $show_cmd_start) {
                    continue
                }
            }

            ##---------------------------------------------##
            ## プロンプトを検出する
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
            ## 対象コマンドの開始行が見つかった場合
            ##---------------------------------------------##
            $workStr = $currentLine

            $workStr = $workStr -replace ", ...d..h, ", ", __:__:__, "
            $workStr = $workStr -replace ", ...d.h, ", ", __:__:__, "
            $workStr = $workStr -replace ", ..d..h, ", ", __:__:__, "
            $workStr = $workStr -replace ", ..d.h, ", ", __:__:__, "
            $workStr = $workStr -replace ", .d..h, ", ", __:__:__, "
            $workStr = $workStr -replace ", .d.h, ", ", __:__:__, "
            $workStr = $workStr -replace "..:..:..", ", __:__:__, "
            $ip_route += $workStr + "`r`n"

            $route_count++

            if ($route_count -le 1) {
                continue
            }

            $pos_prompt = $currentLine.IndexOf($current_prompt)

            if ($pos_prompt -ge 0) {
                # 次のプロンプトが見つかったら検索を終える
                return $ip_route
            }
        }
    }

    return $NULL
}

##----------------------------------------------------------------------------##
## ファイルのパスからディレクトリのパスを取得する
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
## ファイルのパスからファイル名を取得する
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
## 拡張子を取り除いた名前を返す
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
## 出力ファイル名をセットする
##----------------------------------------------------------------------------##
function setResultFileName($fileName, $pre_str, $post_str)
{
    $result_DirPath = getDirPath $fileName
    $result_FileName = getFileName $fileName
    $result_firstFileName = removeExtensionName $result_FileName

    return $result_DirPath + "\" + $pre_str + $result_firstFileName + $post_str
}

##----------------------------------------------------------------------------##
## Main呼び出し
##----------------------------------------------------------------------------##

Main $file1 $file2 $cmd $match
