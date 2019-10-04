$ps1_path = ".\CommentLexer.ps1"

$to_lex_file = $Args[0]

$comment_only_file_path = [System.IO.Path]::GetFileNameWithoutExtension($to_lex_file) + "_comment" + [System.IO.Path]::GetExtension($to_lex_file)
$code_only_file_path = [System.IO.Path]::GetFileNameWithoutExtension($to_lex_file) + "_code" + [System.IO.Path]::GetExtension($to_lex_file)

$code_copy_path = [System.IO.Path]::GetFileNameWithoutExtension($to_lex_file) + "_copy" + [System.IO.Path]::GetExtension($to_lex_file)

try{
    $enc = [Text.Encoding]::GetEncoding($str_enc_name)
    $comment_only_file = New-Object System.IO.StreamWriter($comment_only_file_path, $false, $enc)
    $code_only_file  = New-Object System.IO.StreamWriter($code_only_file_path, $false, $enc)
    $code_copy_file  = New-Object System.IO.StreamWriter($code_copy_path, $false, $enc)
    
} catch {
    Write-Error ("[error] " + $_.Exception.Message)
    try{
        $comment_only_file.Close()
        $code_only_file.Close()
        $code_copy_file.Close()
    } catch {}
    return
}

$listener = {

    # Write-Host ("Progress:" + $progress[1] + " of " + $progress[0].Length + "[Bytes]")
    # Write-Host -NoNewline ("`rProgress:" + $progress[1] + " of " + $progress[0].Length + "[Bytes]")
    Write-Host -NoNewline ("`nProgress:" + $progress[1] + " of " + $progress[0].Length + "[Bytes]")

    $sb = Stringify
    $rep = $sb -replace "[^`r`n]", ''

    if ( ($typeFlags[1] -band (1) ) -eq 1 ){ # コード解析中の場合

        $code_only_file.Write($sb)
        $comment_only_file.Write($rep)

    } else { # コメント解析中の場合

        $code_only_file.Write($rep)
        $comment_only_file.Write($sb)
    }

    $code_copy_file.Write($sb)
}

# import CommentLexer.ps1
. ( (Split-Path -Parent $MyInvocation.MyCommand.Path) + $ps1_path)

# call
LexComment ($to_lex_file) ("shift-jis") ($listener)

Write-Host

# file close
$comment_only_file.Close()
$code_only_file.Close()
$code_copy_file.Close()