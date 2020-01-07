$ps1_path = "\..\..\CommentLexer.ps1"
$enc_name = "utf-8"

$to_lex_file = Convert-Path $Args[0]

$comment_only_file_path =
    (Split-Path -Parent $to_lex_file) + "\" +
    [System.IO.Path]::GetFileNameWithoutExtension($to_lex_file) + "_comment" + [System.IO.Path]::GetExtension($to_lex_file)

$code_only_file_path =
    (Split-Path -Parent $to_lex_file) + "\" +
    [System.IO.Path]::GetFileNameWithoutExtension($to_lex_file) + "_code" + [System.IO.Path]::GetExtension($to_lex_file)

try{
    $enc_obj = [Text.Encoding]::GetEncoding($enc_name)
    
    if ($enc_obj.CodePage -eq 65001){ # for utf-8 encoding with no BOM
        $comment_only_file = New-Object System.IO.StreamWriter($comment_only_file_path, $false)
        $code_only_file  = New-Object System.IO.StreamWriter($code_only_file_path, $false)
        
    } else {
        $comment_only_file = New-Object System.IO.StreamWriter($comment_only_file_path, $false, $enc_obj)
        $code_only_file  = New-Object System.IO.StreamWriter($code_only_file_path, $false, $enc_obj)
    }
    
} catch {
    Write-Error ("[error] " + $_.Exception.Message)
    try{
        $comment_only_file.Close()
        $code_only_file.Close()
    } catch {}
    return
}

$listener = {

    # 1. Show progress on prompt
    $percentage = ($progress[1] / $progress[0].Length) * 100
    Write-Host -NoNewline ("`r" + $percentage.ToString("0").PadLeft(3) + '% processing ' + $to_lex_file)

    # 2. Get string from $delimitedBytes that stores analized byte list.
    $sb = Stringify

    $rep = $sb -replace "[^`r`n]", '' # delete all strings without new line character

    # 3. Evaluate the type of detection
    if ( ($typeFlags[1] -band (1) ) -eq 1 ){ # Detection type represents `Code`

        $code_only_file.Write($sb)
        $comment_only_file.Write($rep)

    } else { # Detection type represents `Comments`

        $code_only_file.Write($rep)
        $comment_only_file.Write($sb)
    }
}

# import CommentLexer.ps1
. ( (Split-Path -Parent $MyInvocation.MyCommand.Path) + $ps1_path)

# call
LexComment ($to_lex_file) ($enc_name) ($listener)

Write-Host

# file close
$comment_only_file.Close()
$code_only_file.Close()
