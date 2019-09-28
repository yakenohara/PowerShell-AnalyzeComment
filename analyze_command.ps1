# <実行方法> ------------------------------------------------------------------------------------------

# ./<このスクリプトファイル>.ps1 " arg1, arg2, arg3, arg4

# ↓ フルパスで指定する ↓  
# arg1 <- "C:\\~~\\comment2\\0.c" (解析対象ファイル)
# arg2 <- ダミー。なんでもいい
# arg2 <- "C:\\~~\\comment2\\0.c" (解析対象ファイルをコピーするファイル。 1 byte も誤りなく コピーできているかどうかを確認するために指定する)
# arg4 <- "C:\\~~\\comment2\\0.c" (解析対象ファイルを解析後の出力するファイル。 )

# ----------------------------------------------------------------------------------------- </実行方法> 

$str_enc_name = "shift-jis"

$in = $Args[0]
$out = $Args[2]
$out2 = $Args[3]

$enc_s = [Text.Encoding]::GetEncoding($str_enc_name)


$reader = New-Object System.IO.FileStream($in, 3)

# 書き込み先ファイルオープン
# https://docs.microsoft.com/ja-jp/dotnet/api/system.io.streamwriter.-ctor?view=netframework-4.8#System_IO_StreamWriter__ctor_System_String_System_Boolean_System_Text_Encoding_
# utf-8 だと BOM が付加されてしまう
$writer = New-Object System.IO.StreamWriter($out, $false, $enc_s)
$writer2 = New-Object System.IO.StreamWriter($out2, $false, $enc_s)

function func_read_file{

    $int32arr_string_buffer = New-Object 'System.Collections.Generic.List[int32]'
    $int32_3darr_line_buffer = New-Object System.Collections.ArrayList
    $int32_3darr_read_buffer = New-Object System.Collections.ArrayList
    $int_2darr_lex_history = New-Object System.Collections.ArrayList
    
    $bytearr_crlf = $enc_s.GetBytes("`r`n")
    $bytearr_backslash = $enc_s.GetBytes("\")
    $bytearr_quote = $enc_s.GetBytes("'")
    $bytearr_doublequote = $enc_s.GetBytes("`"")
    $bytearr_doubleslath = $enc_s.GetBytes("//")
    $bytearr_slashaster = $enc_s.GetBytes("/*")
    $bytearr_asterslash = $enc_s.GetBytes("*/")

    # <字句解析状態に応じた判定条件> ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    # `コード` -> ( `' 文字列` or `" 文字列` or `// コメント` or `/* */ コメント` )
    $script_block_in_code = {

        if ( # `'` の場合
            ( $int32_3darr_read_buffer[$int_2darr_lex_history[$int_last_idx_of_lex_history][0]][$int_2darr_lex_history[$int_last_idx_of_lex_history][1]][$int_2darr_lex_history[$int_last_idx_of_lex_history][2]] -eq $bytearr_quote[0] )
        ){
            if ( # エスケープされた `'` の場合
                ( $int_last_idx_of_lex_history -gt 0 ) -And
                ( $int32_3darr_read_buffer[$int_2darr_lex_history[$int_last_idx_of_lex_history - 1][0]][$int_2darr_lex_history[$int_last_idx_of_lex_history - 1][1]][$int_2darr_lex_history[$int_last_idx_of_lex_history - 1][2]] -eq $bytearr_backslash[0] )
            ){
                # nothing to do
                
            } else { # エスケープされていない `'` の場合

                # last index of lexical analysis history の直前までをコード解析の区切りとする
                func_slice_read_buffer ($int_2darr_lex_history[$int_last_idx_of_lex_history][0]) ($int_2darr_lex_history[$int_last_idx_of_lex_history][1]) ($int_2darr_lex_history[$int_last_idx_of_lex_history][2])
                $writer2.Write("(')")

                $script_block_judger[0] = $script_block_in_single_quote

                continue # `※2 ループ終了判定の直前` へ
            }
        }

        if ( # `"` の場合
            ( $int32_3darr_read_buffer[$int_2darr_lex_history[$int_last_idx_of_lex_history][0]][$int_2darr_lex_history[$int_last_idx_of_lex_history][1]][$int_2darr_lex_history[$int_last_idx_of_lex_history][2]] -eq $bytearr_doublequote[0] )
        ){
            if ( # エスケープされた `"` の場合
                ( $int_last_idx_of_lex_history -gt 0 ) -And
                ( $int32_3darr_read_buffer[$int_2darr_lex_history[$int_last_idx_of_lex_history - 1][0]][$int_2darr_lex_history[$int_last_idx_of_lex_history - 1][1]][$int_2darr_lex_history[$int_last_idx_of_lex_history - 1][2]] -eq $bytearr_backslash[0] )
            ){
                # nothing to do
                
            } else { # エスケープされていない `"` の場合

                # last index of lexical analysis history の直前までをコード解析の区切りとする
                func_slice_read_buffer ($int_2darr_lex_history[$int_last_idx_of_lex_history][0]) ($int_2darr_lex_history[$int_last_idx_of_lex_history][1]) ($int_2darr_lex_history[$int_last_idx_of_lex_history][2])
                $writer2.Write("(`")")

                $script_block_judger[0] = $script_block_in_double_quote

                continue # `※2 ループ終了判定の直前` へ
            }
        }

        if ( # `//` の場合
            ( $int_last_idx_of_lex_history -gt 1 ) -And
            ( $int32_3darr_read_buffer[$int_2darr_lex_history[$int_last_idx_of_lex_history-1][0]][$int_2darr_lex_history[$int_last_idx_of_lex_history-1][1]][$int_2darr_lex_history[$int_last_idx_of_lex_history-1][2]] -eq $bytearr_doubleslath[0] ) -And
            ( $int32_3darr_read_buffer[$int_2darr_lex_history[$int_last_idx_of_lex_history][0]][$int_2darr_lex_history[$int_last_idx_of_lex_history][1]][$int_2darr_lex_history[$int_last_idx_of_lex_history][2]] -eq $bytearr_doubleslath[1] )
        ){
            
            # 2nd of last index of lexical analysis history の直前までをコード解析の区切りとする
            func_slice_read_buffer ($int_2darr_lex_history[$int_last_idx_of_lex_history-1][0]) ($int_2darr_lex_history[$int_last_idx_of_lex_history-1][1]) ($int_2darr_lex_history[$int_last_idx_of_lex_history-1][2])
            $writer2.Write("(//)")

            $script_block_judger[0] = $script_block_in_double_slash_comment

            continue # `※2 ループ終了判定の直前` へ
        }

        if ( # `/*` の場合
            ( $int_last_idx_of_lex_history -gt 1 ) -And
            ( $int32_3darr_read_buffer[$int_2darr_lex_history[$int_last_idx_of_lex_history-1][0]][$int_2darr_lex_history[$int_last_idx_of_lex_history-1][1]][$int_2darr_lex_history[$int_last_idx_of_lex_history-1][2]] -eq $bytearr_slashaster[0] ) -And
            ( $int32_3darr_read_buffer[$int_2darr_lex_history[$int_last_idx_of_lex_history][0]][$int_2darr_lex_history[$int_last_idx_of_lex_history][1]][$int_2darr_lex_history[$int_last_idx_of_lex_history][2]] -eq $bytearr_slashaster[1] )
        ){
            
            # 2nd of last index of lexical analysis history の直前までをコード解析の区切りとする
            func_slice_read_buffer ($int_2darr_lex_history[$int_last_idx_of_lex_history-1][0]) ($int_2darr_lex_history[$int_last_idx_of_lex_history-1][1]) ($int_2darr_lex_history[$int_last_idx_of_lex_history-1][2])
            $writer2.Write("(/*)")

            $script_block_judger[0] = $script_block_in_slash_aster_comment

            continue # `※2 ループ終了判定の直前` へ
        }
    }

    # `' 文字列` -> `コード`
    $script_block_in_single_quote = {

        if ( # `'` の場合
            ( $int32_3darr_read_buffer[$int_2darr_lex_history[$int_last_idx_of_lex_history][0]][$int_2darr_lex_history[$int_last_idx_of_lex_history][1]][$int_2darr_lex_history[$int_last_idx_of_lex_history][2]] -eq $bytearr_quote[0] )
        ){
            if ( # エスケープされた `'` の場合
                ( $int_last_idx_of_lex_history -gt 0 ) -And
                ( $int32_3darr_read_buffer[$int_2darr_lex_history[$int_last_idx_of_lex_history - 1][0]][$int_2darr_lex_history[$int_last_idx_of_lex_history - 1][1]][$int_2darr_lex_history[$int_last_idx_of_lex_history - 1][2]] -eq $bytearr_backslash[0] )
            ){
                # nothing to do
                
            } else { # エスケープされていない `'` の場合

                # 字句解析した最後までをコード解析の区切りとする
                $int_last_index_of_read_buffer_l1 = $int32_3darr_read_buffer.Count -1
                func_slice_read_buffer ($int_last_index_of_read_buffer_l1) (0) ($int32_3darr_read_buffer[$int_last_index_of_read_buffer_l1][0].Count)
                $writer2.Write("('ended)")

                $script_block_judger[0] = $script_block_in_code

                continue # `※2 ループ終了判定の直前` へ
            }
        }
    }

    # `" 文字列` -> `コード`
    $script_block_in_double_quote = {

        if ( # `"` の場合
            ( $int32_3darr_read_buffer[$int_2darr_lex_history[$int_last_idx_of_lex_history][0]][$int_2darr_lex_history[$int_last_idx_of_lex_history][1]][$int_2darr_lex_history[$int_last_idx_of_lex_history][2]] -eq $bytearr_doublequote[0] )
        ){
            if ( # エスケープされた `"` の場合
                ( $int_last_idx_of_lex_history -gt 0 ) -And
                ( $int32_3darr_read_buffer[$int_2darr_lex_history[$int_last_idx_of_lex_history - 1][0]][$int_2darr_lex_history[$int_last_idx_of_lex_history - 1][1]][$int_2darr_lex_history[$int_last_idx_of_lex_history - 1][2]] -eq $bytearr_backslash[0] )
            ){
                # nothing to do
                
            } else { # エスケープされていない `"` の場合

                # 字句解析した最後までをコード解析の区切りとする
                $int_last_index_of_read_buffer_l1 = $int32_3darr_read_buffer.Count -1
                func_slice_read_buffer ($int_last_index_of_read_buffer_l1) (0) ($int32_3darr_read_buffer[$int_last_index_of_read_buffer_l1][0].Count)
                $writer2.Write("(`"ended)")

                $script_block_judger[0] = $script_block_in_code

                continue # `※2 ループ終了判定の直前` へ
            }
        }
    }

    # `// コメント` -> `コード`
    $script_block_in_double_slash_comment = {

        if ( # <- 行の最後の byte の場合
            ( $int_char_index_of_line -eq ($int32arr_line_read.Count-1) )
        ){
            # 字句解析した最後までをコード解析の区切りとする
            $int_last_index_of_read_buffer_l1 = $int32_3darr_read_buffer.Count -1
            func_slice_read_buffer ($int_last_index_of_read_buffer_l1) (0) ($int32_3darr_read_buffer[$int_last_index_of_read_buffer_l1][0].Count)
            $writer2.Write("(`//ended)")

            $script_block_judger[0] = $script_block_in_code

            continue # `※2 ループ終了判定の直前` へ

        }
    }

    # `/* */ コメント` -> `コード`
    $script_block_in_slash_aster_comment = {

        if ( # `*/` の場合
            ( $int_last_idx_of_lex_history -gt 1 ) -And
            ( $int32_3darr_read_buffer[$int_2darr_lex_history[$int_last_idx_of_lex_history-1][0]][$int_2darr_lex_history[$int_last_idx_of_lex_history-1][1]][$int_2darr_lex_history[$int_last_idx_of_lex_history-1][2]] -eq $bytearr_asterslash[0] ) -And
            ( $int32_3darr_read_buffer[$int_2darr_lex_history[$int_last_idx_of_lex_history][0]][$int_2darr_lex_history[$int_last_idx_of_lex_history][1]][$int_2darr_lex_history[$int_last_idx_of_lex_history][2]] -eq $bytearr_asterslash[1] )
        ){
            
            # 字句解析した最後までをコード解析の区切りとする
            $int_last_index_of_read_buffer_l1 = $int32_3darr_read_buffer.Count -1
            func_slice_read_buffer ($int_last_index_of_read_buffer_l1) (0) ($int32_3darr_read_buffer[$int_last_index_of_read_buffer_l1][0].Count)
            $writer2.Write("(`*/ended)")

            $script_block_judger[0] = $script_block_in_code

            continue # `※2 ループ終了判定の直前` へ
        }
    }

    # -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- </字句解析状態に応じた判定条件> 

    function func_read_line{
        
        function func_add_to_line_buffer($int_start_index, $int_last_idx){
    
            $int32arr_line = New-Object 'System.Collections.Generic.List[int32]'
            $int32arr_return = New-Object 'System.Collections.Generic.List[int32]'
    
            if ( $int32arr_string_buffer.Count -gt ($int_start_index * (-1)) ){ # read() した 改行コード以外の文字列が存在する場合

                # 行 bytes の取得
                $int_lp_1st_idx = 0
                $int_lp_lat_idx = ($int32arr_string_buffer.Count + $int_start_index - 1)
                for ($counter = $int_lp_1st_idx ; $counter -le $int_lp_lat_idx ; $counter++){
                    $int32arr_line.Add($int32arr_string_buffer[$counter])
                }
            }

            # 改行コードの取得
            $int_lp_1st_idx = ($int32arr_string_buffer.Count + $int_start_index)
            $int_lp_lat_idx = ($int32arr_string_buffer.Count + $int_last_idx)
            for ($counter = $int_lp_1st_idx ; $counter -le $int_lp_lat_idx ; $counter++){
                $int32arr_return.Add($int32arr_string_buffer[$counter])
            }
    
            $int32_3darr_line_buffer.Add(@($int32arr_line, $int32arr_return)) | Out-Null
    
            if ($int_last_idx -lt (-1)){ # 最終 index が配列最後ではない場合
                
                # string buffer 削除前 backup
                $int32arr_tmp = New-Object 'System.Collections.Generic.List[int32]'
                $int_lp_1st_idx = ($int32arr_string_buffer.Count + $int_last_idx + 1)
                $int_lp_lat_idx = ($int32arr_string_buffer.Count - 1)
                for ($counter = $int_lp_1st_idx ; $counter -le $int_lp_lat_idx ; $counter++){
                    $int32arr_tmp.Add($int32arr_string_buffer[$counter])
                }

                $int32arr_string_buffer.Clear() # string buffer 削除

                # buckup した string buffer を格納
                foreach ($byte_elem_of_tmp in $int32arr_tmp){
                    $int32arr_string_buffer.Add($byte_elem_of_tmp)
                }
                
            } else { # 最終 index が配列最後の場合
                $int32arr_string_buffer.Clear()
            }
        }

        # 行末まで read() する loop
        while($true){
    
            $byte_char = $reader.ReadByte()
        
            if ($byte_char -eq (-1)){
        
                if ($int32arr_string_buffer.Count -gt 0){ # 1 文字以上 read() している場合
        
                    if ( # CR 改行の場合
                        ( $int32arr_string_buffer[$int32arr_string_buffer.Count - 1] -eq $bytearr_crlf[0] )
                    ){
                        func_add_to_line_buffer (-1) (-1) # 最後の 1文字 を改行コードに指定して buffering

                    } elseif ( # LF 改行の場合
                        ( $int32arr_string_buffer[$int32arr_string_buffer.Count - 1] -eq $bytearr_crlf[1] )
                    ){            
                        func_add_to_line_buffer (-1) (-1) # 最後の 1文字 を改行コードに指定して buffering

                    }
                }
                
                $int32arr_string_buffer.Add($byte_char)
        
                func_add_to_line_buffer (-1) (-1) # 最後の 1文字 を改行コードに指定して buffering

                break
            }
        
            $int32arr_string_buffer.Add($byte_char)
            
            if ($int32arr_string_buffer.Count -gt 1){ # 2 文字以上 read() している場合
                
                if ( # CRLF 改行の場合
                    ( $int32arr_string_buffer[$int32arr_string_buffer.Count - 2] -eq $bytearr_crlf[0] ) -And
                    ( $int32arr_string_buffer[$int32arr_string_buffer.Count - 1] -eq $bytearr_crlf[1] )
                ){
                    func_add_to_line_buffer (-2) (-1) # 最後の 2bytes を改行コードに指定して buffering
                    break
                }

                if ( # CR 改行の場合
                    ( $int32arr_string_buffer[$int32arr_string_buffer.Count - 2] -eq $bytearr_crlf[0] )
                ){
                    func_add_to_line_buffer (-2) (-2) # 最後の 2bytes を改行コードに指定して buffering
                    break
                }

                $bool_lf_found = $false

                if ( # 2 byte の内 1 byte目が LF の場合
                    ( $int32arr_string_buffer[$int32arr_string_buffer.Count - 2] -eq $bytearr_crlf[1] )
                ){
                    func_add_to_line_buffer (-2) (-2) # 最後の 2byte 目だけを改行コードに指定して buffering
                    $bool_lf_found = $true
                }
                if ( # 2 byte の内 2 byte目が LF の場合
                    ( $int32arr_string_buffer[$int32arr_string_buffer.Count - 1] -eq $bytearr_crlf[1] )
                ){
                    func_add_to_line_buffer (-1) (-1) # 最後の 1byte を改行コードに指定して buffering
                    $bool_lf_found = $true
                }

                if ($bool_lf_found){ # 2 byte の内 いずれかに LF が存在した場合
                    break
                }
            }
        }
    }

    function func_slice_read_buffer($l1_to, $l2_to, $int_first_index_of_2nd){

        for ($l1 = 0 ; $l1 -lt $l1_to ; $l1++){

            for ($l2 = 0 ; $l2 -lt 2 ; $l2++){
                if( $int32_3darr_read_buffer[0][$l2].Count -gt 0){
                    $writer.Write($enc_s.GetString( $int32_3darr_read_buffer[0][$l2] ))
                    $writer2.Write($enc_s.GetString( $int32_3darr_read_buffer[0][$l2] ))
                }
            }
            $int32_3darr_read_buffer.RemoveAt(0)
        }

        for ($l2 = 0 ; $l2 -lt $l2_to ; $l2++){
            if( $int32_3darr_read_buffer[0][$l2].Count -gt 0){
                $writer.Write($enc_s.GetString( $int32_3darr_read_buffer[0][$l2] ))
                $writer2.Write($enc_s.GetString( $int32_3darr_read_buffer[0][$l2] ))
            }
        }

        $int32arr_1st_of_sliced = (New-Object 'System.Collections.Generic.List[int32]')
        $int32arr_2nd_of_sliced = (New-Object 'System.Collections.Generic.List[int32]')

        for ($xxx = 0 ; $xxx -lt $int_first_index_of_2nd ; $xxx++ ){
            $int32arr_1st_of_sliced.Add($int32_3darr_read_buffer[0][$l2][$xxx])
        }

        for ($yyy = $int_first_index_of_2nd ; $yyy -lt ($int32_3darr_read_buffer[0][$l2].Count) ; $yyy++ ){
            $int32arr_2nd_of_sliced.Add($int32_3darr_read_buffer[0][$l2][$yyy])
        }

        if ($int32arr_1st_of_sliced.Count -gt 0){
            $writer.Write($enc_s.GetString( $int32arr_1st_of_sliced ))
            $writer2.Write($enc_s.GetString( $int32arr_1st_of_sliced ))
        }

        $int32_3darr_read_buffer[0][$l2_to] = $int32arr_2nd_of_sliced

        $int_2darr_lex_history.Clear()
    }

    # 字句解析状態を `コード中` に設定
    # ( ※note
    #    <字句解析状態に応じた判定条件> 内のスクリプトブロックから
    #    状態を変更する必要があるので、配列定義にして index [0] に対してアクセス
    #    状態を変更するようにする
    # )
    $script_block_judger = New-Object System.Collections.ArrayList
    $script_block_judger.Add($script_block_in_code) | Out-Null

    # EOF まで read() する loop
    while($true){

        if ( $int32_3darr_line_buffer.Count -eq 0 ){
            func_read_line
        }

        $int32arr_line_read = $int32_3darr_line_buffer[0][0]
        $int32arr_return_or_eof_read = $int32_3darr_line_buffer[0][1]
        $int32_3darr_line_buffer.RemoveAt(0)

        # buffering 行要素
        $int_last_index_of_read_buffer_l1 = $int32_3darr_read_buffer.Add( (New-Object System.Collections.ArrayList) )
        $int32_3darr_read_buffer[$int_last_index_of_read_buffer_l1].Add( (New-Object 'System.Collections.Generic.List[int32]') )  | Out-Null # 行文字列用
        $int32_3darr_read_buffer[$int_last_index_of_read_buffer_l1].Add( (New-Object 'System.Collections.Generic.List[int32]') )  | Out-Null # 改行 or EOF 格納用
        
        $bool_escaped_return = $false

        #   |      ※0 initialize        |                     ※1 ループ終了判定                  |  ※2 ループ終了判定の直前   |
        for ($int_char_index_of_line = 0 ; $int_char_index_of_line -lt $int32arr_line_read.Count ; $int_char_index_of_line++ ){

            $int_last_index_of_read_buffer_l1 = $int32_3darr_read_buffer.Count -1
            $int32_3darr_read_buffer[$int_last_index_of_read_buffer_l1][0].Add($int32arr_line_read[$int_char_index_of_line])
            $int_added_index = $int32_3darr_read_buffer[$int_last_index_of_read_buffer_l1][0].Count - 1

            if( # 改行に対するエスケープの場合
                ( $int_char_index_of_line -eq ($int32arr_line_read.Count-1) ) -And              # <- 行の最後の byte の場合に TRUE
                ( $int32arr_line_read[$int_char_index_of_line] -eq $bytearr_backslash[0] ) -And # <- `\` の場合に TRUE
                ( $int32arr_return_or_eof_read[0] -ne (-1) )                                    # <- 改行コードの場合に TRUE
            ){
                $bool_escaped_return = $true
            
            } else { # 改行に対するエスケープではない場合

                $bool_escaped_return = $false

                $int_last_idx_of_lex_history = $int_2darr_lex_history.Add( @($int_last_index_of_read_buffer_l1, 0, $int_added_index) )

                & $script_block_judger[0] # <字句解析状態に応じた判定条件>

            }
        }

        if($int32arr_return_or_eof_read[0] -eq (-1)){ # EOF の場合

            # 字句解析した最後までをコード解析の区切りとする
            $int_last_index_of_read_buffer_l1 = $int32_3darr_read_buffer.Count -1
            func_slice_read_buffer ($int_last_index_of_read_buffer_l1) (0) ($int32_3darr_read_buffer[$int_last_index_of_read_buffer_l1][0].Count)

            break
        }

        #   |      ※0 initialize        |                     ※1 ループ終了判定                           |  ※2 ループ終了判定の直前   |
        for ($int_char_index_of_line = 0 ; $int_char_index_of_line -lt $int32arr_return_or_eof_read.Count ; $int_char_index_of_line++ ){

            $int_last_index_of_read_buffer_l1 = $int32_3darr_read_buffer.Count -1
            $int32_3darr_read_buffer[$int_last_index_of_read_buffer_l1][1].Add($int32arr_return_or_eof_read[$int_char_index_of_line])
            $int_added_index = $int32_3darr_read_buffer[$int_last_index_of_read_buffer_l1][1].Count - 1

            if ( ! $bool_escaped_return ) { # エスケープされた改行ではない場合
                $int_last_idx_of_lex_history = $int_2darr_lex_history.Add( @($int_last_index_of_read_buffer_l1, 1, $int_added_index) )
            }

        }
    }
}

func_read_file

# ファイルクローズ
$reader.Close()
$writer.Close()
$writer2.Close()
