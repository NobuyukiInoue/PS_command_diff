##----------------------------------------------------------------------------##
## 引数の指定（２つのファイルを指定可）
##----------------------------------------------------------------------------##
param($arg1, $arg2)

# diffツールの指定
$program_diff = "D:\share\ツール群\df141\DF.exe"
$show_cmd = "show ip route vrf"

##----------------------------------------------------------------------------##
## メイン処理
##----------------------------------------------------------------------------##
function Main($file1, $file2)
{
    if (-Not($file1) -And -Not($file2)) {
        $files = SelectFile_Multi "比較したいファイルを選択してください。（CTRL+で２つ同時に選択可）"
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
        $file1 = SelectFile "１つめのファイルを選択してください。"
    }
    if ($file1 -ne $NULL) {
        Write-Host "`$file1 = "$file1
#       Get-Content $file1
    }

    if (-Not($file2)) {
        $file2 = SelectFile "２つめのファイルを選択してください。"
    }
    if ($file2 -ne $NULL) {
        Write-Host "`$file2 = "$file2
#       Get-Content $file2
    }

    # $file1 の "show ip route"の実行結果部分を取得する
    $route1 = get_show_command $file1 $show_cmd
    $result_file1 = setResultFileName $file1 "route_"  ".txt"

    Write-Output $route1 | Out-File $result_file1 -Encoding default

    # $file2 の "show ip route"の実行結果部分を取得する
    $route2 = get_show_command $file2 $show_cmd
    $result_file2 = setResultFileName $file2 "route_" ".txt"

    Write-Output $route2 | Out-File $result_file2 -Encoding default

    # diffコマンド起動
    & $program_diff $result_file1 $result_file2

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
    if($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){
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
    if($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){
        # 複数選択を許可している時は $dialog.FileNames を利用する
       return $dialog.FileNames
    }
    else {
        return $NULL
    }
}

##----------------------------------------------------------------------------##
## 正常性ログから $cmd の実行結果部分を取得する
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
            ## 対象コマンドを検索する
            ##---------------------------------------------##
            $prompt = $currentLine.IndexOf("#")

            if ($prompt -eq -1) {
                continue
            }

            $show_cmd_start = $currentLine.IndexOf($cmd)

            if ($show_cmd_start -eq -1) {
                continue
            }

            # コマンドに他のオプションが含まれていた場合は、対象外とする
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
            ## 対象コマンドの開始行が見つかった場合
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

Main $arg1 $arg2
