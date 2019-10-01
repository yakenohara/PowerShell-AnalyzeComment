# <実行方法> ------------------------------------------------------------------------------------------

# ./<このスクリプトファイル>.ps1 " arg1, arg2, arg3, arg4

# ↓ フルパスで指定する ↓  
# arg1 <- "C:\\~~\\comment2\\0.c" (解析対象ファイル)
# arg2 <- ダミー。なんでもいい
# arg2 <- "C:\\~~\\comment2\\0.c" (解析対象ファイルをコピーするファイル。 1 byte も誤りなく コピーできているかどうかを確認するために指定する)
# arg4 <- "C:\\~~\\comment2\\0.c" (解析対象ファイルを解析後の出力するファイル。 )

# ----------------------------------------------------------------------------------------- </実行方法> 

$ps1_path = "\..\..\analyze_command.ps1"
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

    $sb = New-Object System.Text.StringBuilder

    for ($l1 = 0 ; $l1 -lt $int32_3darr_delimited_bytes.Count ; $l1++){
        for ($l2 = 0 ; $l2 -lt $int32_3darr_delimited_bytes[$l1].Count ; $l2++){
            if ($int32_3darr_delimited_bytes[$l1][$l2].Count -gt 0){
                $strstr = $enc_s.GetString($int32_3darr_delimited_bytes[$l1][$l2])
                $sb.Append($strstr) | Out-Null
            }

            if ($l2 -eq 1){
            
                $strstr = $enc_s.GetString($int32_3darr_delimited_bytes[$l1][$l2])

                if ( # CRLF の場合
                    ( $strstr -eq "`r`n")
                ){
                    $sw_for_lex.Write("CRLF`r`n")
                    Write-Host "CRLF"
                
                } elseif ( # CR の場合
                    ( $strstr -eq "`r")
                ){
                    $sw_for_lex.Write("CR`r`n")
                    Write-Host "CR"
                
                } elseif ( # LF の場合
                    ( $strstr -eq "`n")
                ){
                    $sw_for_lex.Write("LF`r`n")
                    Write-Host "LF"
                }
            }
        }
    }

    if($int_typ_flgs[0]){ # EOF の場合
        $sw_for_lex.Write("EOF`r`n")
        Write-Host "EOF"
    }

    $sw_for_copy.Write($sb)

    # if ( ($int_typ_flgs[1] -band (1) ) -eq 1 ){ # コード解析中の場合

    #     if ($int_typ_flgs[1] -eq $TYP_CODE_QUOTE){ # `'` 中の場合
    #         $sw_for_lex.Write("QUOTE_START")
    #         $sw_for_lex.Write($sb)
    #         if(!$int_typ_flgs[0]){
    #             $sw_for_lex.Write("QUOTE_END")
    #         }

    #     } elseif ($int_typ_flgs[1] -eq $TYP_CODE_DQUOTE) { # `"` 中の場合
    #         $sw_for_lex.Write("DOUBLE_QUOTE_START")
    #         $sw_for_lex.Write($sb)
    #         if(!$int_typ_flgs[0]){
    #             $sw_for_lex.Write("DOUBLE_QUOTE_END")
    #         }
    #     } else {
    #         $sw_for_lex.Write($sb)
    #     }

    # } else { # コメント解析中の場合

    #     if ($int_typ_flgs[2] -eq $TYP_COMMENT_SINGLE){ # `'` 中の場合
    #         $sw_for_lex.Write("DOUBLE_SLASH_START")
    #         $sw_for_lex.Write($sb)
    #         $sw_for_lex.Write("DOUBLE_SLASH_END")

    #     } elseif ($int_typ_flgs[2] -eq $TYP_COMMENT_MULTI) { # `"` 中の場合
    #         $sw_for_lex.Write("SLASHASTER_START")
    #         $sw_for_lex.Write($sb)
    #         if(!$int_typ_flgs[0]){
    #             $sw_for_lex.Write("SLASHASTER_END")
    #         }
    #     } else {
    #         $sw_for_lex.Write("UNKOWN")
    #         $sw_for_lex.Write($sb)
    #         if(!$int_typ_flgs[0]){
    #             $sw_for_lex.Write("UNKOWN_END")
    #         }
    #     }
    # }
}

# import analyze_command.ps1
. ( (Split-Path -Parent $MyInvocation.MyCommand.Path) + $ps1_path)

# call
func_read_file ($to_lex_file) ($str_enc_name) ($delimition_listener)

# file close
$sw_for_copy.Close()
$sw_for_lex.Close()
