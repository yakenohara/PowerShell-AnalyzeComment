$ps1_path = ".\CommentLexer.ps1"

$to_lex_file = Convert-Path $Args[0]

$comment_only_file_path =
    (Split-Path -Parent $to_lex_file) + "\" +
    [System.IO.Path]::GetFileNameWithoutExtension($to_lex_file) + "_comment" + [System.IO.Path]::GetExtension($to_lex_file)

$code_only_file_path =
    (Split-Path -Parent $to_lex_file) + "\" +
    [System.IO.Path]::GetFileNameWithoutExtension($to_lex_file) + "_code" + [System.IO.Path]::GetExtension($to_lex_file)

try{
    $enc = [Text.Encoding]::GetEncoding($str_enc_name)
    $comment_only_file = New-Object System.IO.StreamWriter($comment_only_file_path, $false, $enc)
    $code_only_file  = New-Object System.IO.StreamWriter($code_only_file_path, $false, $enc)
    
} catch {
    Write-Error ("[error] " + $_.Exception.Message)
    try{
        $comment_only_file.Close()
        $code_only_file.Close()
    } catch {}
    return
}

$listener = {

    $percentage = ($progress[1] / $progress[0].Length) * 100
    Write-Host -NoNewline ("`r" + $percentage.ToString("0").PadLeft(3) + '% processing ' + $to_lex_file)

    $sb = Stringify
    $rep = $sb -replace "[^`r`n]", ''

    if ( ($typeFlags[1] -band (1) ) -eq 1 ){ # コード解析中の場合

        $code_only_file.Write($sb)
        $comment_only_file.Write($rep)

    } else { # コメント解析中の場合

        $code_only_file.Write($rep)
        $comment_only_file.Write($sb)
    }
}

# import CommentLexer.ps1
. ( (Split-Path -Parent $MyInvocation.MyCommand.Path) + $ps1_path)

# call
LexComment ($to_lex_file) ("shift-jis") ($listener)

Write-Host

# file close
$comment_only_file.Close()
$code_only_file.Close()
