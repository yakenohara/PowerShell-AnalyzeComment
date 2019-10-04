# <実行方法> ------------------------------------------------------------------------------------------

# ./<このスクリプトファイル>.ps1 " arg1, arg2, arg3, arg4

# ↓ フルパスで指定する ↓  
# arg1 <- "C:\\~~\\comment2\\0.c" (解析対象ファイル)
# arg2 <- ダミー。なんでもいい
# arg2 <- "C:\\~~\\comment2\\0.c" (解析対象ファイルをコピーするファイル。 1 byte も誤りなく コピーできているかどうかを確認するために指定する)
# arg4 <- "C:\\~~\\comment2\\0.c" (解析対象ファイルを解析後の出力するファイル。 )

# ----------------------------------------------------------------------------------------- </実行方法> 

$ps1_path = "\..\..\CommentLexer.ps1"
$str_enc_name = "shift-jis"

$to_lex_file = $Args[0]

try{
    $enc_s = [Text.Encoding]::GetEncoding($str_enc_name)
    $sw_for_copy = New-Object System.IO.StreamWriter($Args[2], $false, $enc_s)
    $sw_for_lex  = New-Object System.IO.StreamWriter($Args[3], $false, $enc_s)

} catch {
    Write-Error ("[error] " + $_.Exception.Message)
    try{
        $sw_for_copy.Close()
        $sw_for_lex.Close()
    } catch {}
    return
}

$delimition_listener = {

    $sb = Stringify

    $sw_for_copy.Write($sb)

    if ( ($typeFlags[1] -band (1) ) -eq 1 ){ # コード解析中の場合

        if ($typeFlags[1] -eq $TYP_CODE_QUOTE){ # `'` 中の場合
            $sw_for_lex.Write("QUOTE_START")
            $sw_for_lex.Write($sb)
            if(!$typeFlags[0]){
                $sw_for_lex.Write("QUOTE_END")
            }

        } elseif ($typeFlags[1] -eq $TYP_CODE_DQUOTE) { # `"` 中の場合
            $sw_for_lex.Write("DOUBLE_QUOTE_START")
            $sw_for_lex.Write($sb)
            if(!$typeFlags[0]){
                $sw_for_lex.Write("DOUBLE_QUOTE_END")
            }
        } else {
            $sw_for_lex.Write($sb)
        }

    } else { # コメント解析中の場合

        if ($typeFlags[2] -eq $TYP_COMMENT_SINGLE){ # `'` 中の場合
            $sw_for_lex.Write("DOUBLE_SLASH_START")
            $sw_for_lex.Write($sb)
            $sw_for_lex.Write("DOUBLE_SLASH_END")

        } elseif ($typeFlags[2] -eq $TYP_COMMENT_MULTI) { # `"` 中の場合
            $sw_for_lex.Write("SLASHASTER_START")
            $sw_for_lex.Write($sb)
            if(!$typeFlags[0]){
                $sw_for_lex.Write("SLASHASTER_END")
            }
        } else {
            $sw_for_lex.Write("UNKOWN")
            $sw_for_lex.Write($sb)
            if(!$typeFlags[0]){
                $sw_for_lex.Write("UNKOWN_END")
            }
        }
    }
}

# import analyze_command.ps1
. ( (Split-Path -Parent $MyInvocation.MyCommand.Path) + $ps1_path)

# call
LexComment ($to_lex_file) ($str_enc_name) ($delimition_listener)

# file close
$sw_for_copy.Close()
$sw_for_lex.Close()
