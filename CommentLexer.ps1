

# To see the list of supported code pages instantly,
# execute the following powershell script.
# ```
# &{
#     for($cnt = 0; $cnt -lt 65535; $cnt++){
#         try{
#             $enc = [Text.Encoding]::GetEncoding($cnt)
#             $web_name = $enc.WebName
#             $enc_name = $enc.EncodingName
#             Write-Host "$cnt, $web_name, $enc_name"
#         } catch {}
#     }
# }
# ```


set-variable -name TYP_CLEAR -value 0x0 -option constant

set-variable -name TYP_CODE -value 0x1 -option constant
set-variable -name TYP_CODE_QUOTE -value 0x3 -option constant
set-variable -name TYP_CODE_DQUOTE -value 0x5 -option constant

set-variable -name TYP_COMMENT -value 0x1 -option constant
set-variable -name TYP_COMMENT_SINGLE -value 0x3 -option constant
set-variable -name TYP_COMMENT_MULTI -value 0x5 -option constant

function _func_lex($filepath, $encoding, $_line_listener, $delimition_listener){

    $int32arr_string_buffer = New-Object 'System.Collections.Generic.List[int32]'
    $int32_3darr_line_buffer = New-Object System.Collections.ArrayList
    $int32_3darr_read_buffer = New-Object System.Collections.ArrayList
    

    $delimitedBytes = New-Object System.Collections.ArrayList
    # $int_typ_flgs = New-Object System.Collections.ArrayList
    # $int_typ_flgs.Add($false) | Out-Null     # EOFかどうか -> [0]
    
    # <引数チェック> ----------------------------------------------------------------

    if ( [string]::IsNullOrEmpty($encoding) ){
        Write-Error "[error] Null or empty string cannot be specified as encoding"
        return
    }

    try{
        $enc_s = [Text.Encoding]::GetEncoding($encoding)
    
    } catch { # 存在しないエンコードを指定した場合
        Write-Error ("[error] " + $_.Exception.Message)
        return
    }

    try{
        $reader = New-Object System.IO.FileStream($filepath, 3) # 読み取り専用で開く
    
    } catch { # ファイルオープン失敗の場合
        Write-Error ("[error] " + $_.Exception.Message)
        return
    }

    # --------------------------------------------------------------- </引数チェック> 
    
    
    $bytearr_crlf = $enc_s.GetBytes("`r`n")
    $bytearr_backslash = $enc_s.GetBytes("\")
    $bytearr_quote = $enc_s.GetBytes("'")
    $bytearr_doublequote = $enc_s.GetBytes("`"")
    $bytearr_doubleslath = $enc_s.GetBytes("//")
    $bytearr_slashaster = $enc_s.GetBytes("/*")
    $bytearr_asterslash = $enc_s.GetBytes("*/")

    $_try_delimition_lister = {
        try{
            & $script_delimition_listerner[0] # listener call
        } catch {
            Write-Error ("[error] " + $_.Exception.Message)
            $reader.Close() # ファイルクローズ
            return #todo ここで return しても while($true)から break しない
        }
    }

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

        $l2 = 0

        $delimitedBytes.Clear()

        # 行定義の直前までコピーする loop
        for ($l1 = 0 ; $l1 -lt $l1_to ; $l1++){

            $lstidx = $delimitedBytes.Add( (New-Object System.Collections.ArrayList) )

            $delimitedBytes[$lstidx].Add( (New-Object 'System.Collections.Generic.List[int32]') ) | Out-Null
            $delimitedBytes[$lstidx].Add( (New-Object 'System.Collections.Generic.List[int32]') ) | Out-Null

            for ($l2 = 0 ; $l2 -lt 2 ; $l2++){
                if( $int32_3darr_read_buffer[0][$l2].Count -gt 0){

                    for ($l3 = 0 ; $l3 -lt ($int32_3darr_read_buffer[0][$l2].Count) ; $l3++){
                        $delimitedBytes[$lstidx][$l2].Add( $int32_3darr_read_buffer[0][$l2][$l3] )
                    }
                }
            }
            $int32_3darr_read_buffer.RemoveAt(0)
        }

        # 行定義の最後をコピーする loop
        $lstidx = $delimitedBytes.Add( (New-Object System.Collections.ArrayList) )
        $delimitedBytes[$lstidx].Add( (New-Object 'System.Collections.Generic.List[int32]') ) | Out-Null
        $delimitedBytes[$lstidx].Add( (New-Object 'System.Collections.Generic.List[int32]') ) | Out-Null
        for ($l2 = 0 ; $l2 -lt $l2_to ; $l2++){
            if( $int32_3darr_read_buffer[0][$l2].Count -gt 0){
                for ($l3 = 0 ; $l3 -lt ($int32_3darr_read_buffer[0][$l2].Count) ; $l3++){
                    $delimitedBytes[$lstidx][$l2].Add( $int32_3darr_read_buffer[0][$l2][$l3] )
                }
            }
            $int32_3darr_read_buffer[0][$l2].Clear()
        }

        # 行定義のスライス対象要素を スライス
        $int32arr_1st_of_sliced = (New-Object 'System.Collections.Generic.List[int32]')
        $int32arr_2nd_of_sliced = (New-Object 'System.Collections.Generic.List[int32]')

        for ($xxx = 0 ; $xxx -lt $int_first_index_of_2nd ; $xxx++ ){
            $int32arr_1st_of_sliced.Add($int32_3darr_read_buffer[0][$l2][$xxx])
        }

        for ($yyy = $int_first_index_of_2nd ; $yyy -lt ($int32_3darr_read_buffer[0][$l2].Count) ; $yyy++ ){
            $int32arr_2nd_of_sliced.Add($int32_3darr_read_buffer[0][$l2][$yyy])
        }

        # スライスした 前半を コピー
        if ($int32arr_1st_of_sliced.Count -gt 0){
            $delimitedBytes[$lstidx][$l2] = $int32arr_1st_of_sliced
        }

        # スライスした 後半を buffer に貯め直し
        $int32_3darr_read_buffer[0][$l2_to] = $int32arr_2nd_of_sliced


        
    }

    $script_delimition_listerner = New-Object System.Collections.ArrayList
    $script_delimition_listerner.Add($delimition_listener) | Out-Null

    $int_typ_flgs[0] = $false
    
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

        . $_line_listener
    }
    
    $reader.Close() # ファイルクローズ
}

function LexLine($filepath, $encoding, $delimition_listener){

    

    $_listener = {

        # $int_last_index_of_read_buffer_l1 = $int32_3darr_read_buffer.Count-1

        $endindx = 0
        $int32_3darr_read_buffer[$int_last_index_of_read_buffer_l1][$endindx] = $int32arr_line_read

        if($int32arr_return_or_eof_read[0] -eq (-1)){ # EOF の場合            
            $int_typ_flgs[0] = $true
            func_slice_read_buffer ($int_last_index_of_read_buffer_l1) ($endindx) ($int32_3darr_read_buffer[$int_last_index_of_read_buffer_l1][$endindx].Count)
            . $_try_delimition_lister
            break

        } else { # EOF ではない場合
            $int32_3darr_read_buffer[$int_last_index_of_read_buffer_l1][++$endindx] = $int32arr_return_or_eof_read # 改行コードを格納
            func_slice_read_buffer ($int_last_index_of_read_buffer_l1) ($endindx) ($int32_3darr_read_buffer[$int_last_index_of_read_buffer_l1][$endindx].Count)
            . $_try_delimition_lister
        }
    }

    $int_typ_flgs = New-Object System.Collections.ArrayList
    $int_typ_flgs.Add($false) | Out-Null     # EOFかどうか -> [0]

    # $script__listerner = New-Object System.Collections.ArrayList
    # $script__listerner.Add($_listener) | Out-Null

    _func_lex($filepath) ($encoding) ($_listener) ($delimition_listener)
}

function LexComment($filepath, $encoding, $delimition_listener){

    # <字句解析状態に応じた判定条件> ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    # なにもさせたくないときに指定する
    $script_block_dummy = {
        #nothing to do
    }

    # < $script_block_judger[0] 用 >  -------------------------------------------------------------------------------------------

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
                $int_2darr_lex_history.Clear() # 字句解析履歴をクリア
                . $_try_delimition_lister
                
                $int_typ_flgs[1] = $TYP_CODE_QUOTE
                $int_typ_flgs[2] = $TYP_CLEAR

                $script_block_judger[0] = $script_block_in_single_quote
                $script_block_judger[1] = $script_block_dummy

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
                $int_2darr_lex_history.Clear() # 字句解析履歴をクリア
                . $_try_delimition_lister

                $int_typ_flgs[1] = $TYP_CODE_DQUOTE
                $int_typ_flgs[2] = $TYP_CLEAR

                $script_block_judger[0] = $script_block_in_double_quote
                $script_block_judger[1] = $script_block_dummy

                continue # `※2 ループ終了判定の直前` へ
            }
        }

        if ( # `//` の場合
            ( $int_last_idx_of_lex_history -gt 0 ) -And
            ( $int32_3darr_read_buffer[$int_2darr_lex_history[$int_last_idx_of_lex_history-1][0]][$int_2darr_lex_history[$int_last_idx_of_lex_history-1][1]][$int_2darr_lex_history[$int_last_idx_of_lex_history-1][2]] -eq $bytearr_doubleslath[0] ) -And
            ( $int32_3darr_read_buffer[$int_2darr_lex_history[$int_last_idx_of_lex_history][0]][$int_2darr_lex_history[$int_last_idx_of_lex_history][1]][$int_2darr_lex_history[$int_last_idx_of_lex_history][2]] -eq $bytearr_doubleslath[1] )
        ){
            
            # 2nd of last index of lexical analysis history の直前までをコード解析の区切りとする
            func_slice_read_buffer ($int_2darr_lex_history[$int_last_idx_of_lex_history-1][0]) ($int_2darr_lex_history[$int_last_idx_of_lex_history-1][1]) ($int_2darr_lex_history[$int_last_idx_of_lex_history-1][2])
            $int_2darr_lex_history.Clear() # 字句解析履歴をクリア
            . $_try_delimition_lister

            $int_typ_flgs[1] = $TYP_CLEAR
            $int_typ_flgs[2] = $TYP_COMMENT_SINGLE

            $script_block_judger[0] = $script_block_dummy
            $script_block_judger[1] = $script_block_in_double_slash_comment

            continue # `※2 ループ終了判定の直前` へ
        }

        if ( # `/*` の場合
            ( $int_last_idx_of_lex_history -gt 0 ) -And
            ( $int32_3darr_read_buffer[$int_2darr_lex_history[$int_last_idx_of_lex_history-1][0]][$int_2darr_lex_history[$int_last_idx_of_lex_history-1][1]][$int_2darr_lex_history[$int_last_idx_of_lex_history-1][2]] -eq $bytearr_slashaster[0] ) -And
            ( $int32_3darr_read_buffer[$int_2darr_lex_history[$int_last_idx_of_lex_history][0]][$int_2darr_lex_history[$int_last_idx_of_lex_history][1]][$int_2darr_lex_history[$int_last_idx_of_lex_history][2]] -eq $bytearr_slashaster[1] )
        ){
            
            # 2nd of last index of lexical analysis history の直前までをコード解析の区切りとする
            func_slice_read_buffer ($int_2darr_lex_history[$int_last_idx_of_lex_history-1][0]) ($int_2darr_lex_history[$int_last_idx_of_lex_history-1][1]) ($int_2darr_lex_history[$int_last_idx_of_lex_history-1][2])
            $int_2darr_lex_history.Clear() # 字句解析履歴をクリア
            . $_try_delimition_lister
            
            $int_typ_flgs[1] = $TYP_CLEAR
            $int_typ_flgs[2] = $TYP_COMMENT_MULTI

            $script_block_judger[0] = $script_block_in_slash_aster_comment
            $script_block_judger[1] = $script_block_dummy

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
                $int_2darr_lex_history.Clear() # 字句解析履歴をクリア
                . $_try_delimition_lister

                $int_typ_flgs[1] = $TYP_CODE
                $int_typ_flgs[2] = $TYP_CLEAR

                $script_block_judger[0] = $script_block_in_code
                $script_block_judger[1] = $script_block_dummy

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
                $int_2darr_lex_history.Clear() # 字句解析履歴をクリア
                . $_try_delimition_lister

                $int_typ_flgs[1] = $TYP_CODE
                $int_typ_flgs[2] = $TYP_CLEAR

                $script_block_judger[0] = $script_block_in_code
                $script_block_judger[1] = $script_block_dummy

                continue # `※2 ループ終了判定の直前` へ
            }
        }
    }

    # `/* */ コメント` -> `コード`
    $script_block_in_slash_aster_comment = {

        if ( # `*/` の場合
            ( $int_last_idx_of_lex_history -gt 0 ) -And
            ( $int32_3darr_read_buffer[$int_2darr_lex_history[$int_last_idx_of_lex_history-1][0]][$int_2darr_lex_history[$int_last_idx_of_lex_history-1][1]][$int_2darr_lex_history[$int_last_idx_of_lex_history-1][2]] -eq $bytearr_asterslash[0] ) -And
            ( $int32_3darr_read_buffer[$int_2darr_lex_history[$int_last_idx_of_lex_history][0]][$int_2darr_lex_history[$int_last_idx_of_lex_history][1]][$int_2darr_lex_history[$int_last_idx_of_lex_history][2]] -eq $bytearr_asterslash[1] )
        ){
            
            # 字句解析した最後までをコード解析の区切りとする
            $int_last_index_of_read_buffer_l1 = $int32_3darr_read_buffer.Count -1
            func_slice_read_buffer ($int_last_index_of_read_buffer_l1) (0) ($int32_3darr_read_buffer[$int_last_index_of_read_buffer_l1][0].Count)
            $int_2darr_lex_history.Clear() # 字句解析履歴をクリア
            . $_try_delimition_lister

            $int_typ_flgs[1] = $TYP_CODE
            $int_typ_flgs[2] = $TYP_CLEAR

            $script_block_judger[0] = $script_block_in_code
            $script_block_judger[1] = $script_block_dummy

            continue # `※2 ループ終了判定の直前` へ
        }
    }

    # ------------------------------------------------------------------------------------------ </ $script_block_judger[0] 用 >  

    # < $script_block_judger[1] 用 >  -------------------------------------------------------------------------------------------

    # `// コメント` -> `コード`
    $script_block_in_double_slash_comment = {

        if ( ! $bool_escaped_return[0] ) { # エスケープされた改行ではない場合

            $first_layer = $int32_3darr_read_buffer.Count -1
            $scond_layer = 0
            $third_layer = 0

            if($int32arr_return_or_eof_read[0] -eq (-1)){ # EOF の場合

                $scond_layer = 0
                $int_typ_flgs[0] = $true

            } else {  # 改行コードありの場合

                $scond_layer = 1

                # 改行コードを buffer に乗せるループ
                for ($int_char_index_of_line = 0 ; $int_char_index_of_line -lt $int32arr_return_or_eof_read.Count ; $int_char_index_of_line++ ){
                    
                    $int32_3darr_read_buffer[$first_layer][$scond_layer].Add($int32arr_return_or_eof_read[$int_char_index_of_line])
                    $int_added_index = $int32_3darr_read_buffer[$first_layer][$scond_layer].Count - 1
                    $int_2darr_lex_history.Add( @($first_layer, $scond_layer, $int_added_index) ) | Out-Null

                }
            }

            $third_layer = $int32_3darr_read_buffer[$first_layer][$scond_layer].Count

            # 字句解析した最後までをコード解析の区切りとする
            func_slice_read_buffer ($first_layer) ($scond_layer) ($third_layer)
            $int_2darr_lex_history.Clear() # 字句解析履歴をクリア
            . $_try_delimition_lister

            $int_typ_flgs[1] = $TYP_CODE
            $int_typ_flgs[2] = $TYP_CLEAR

            if($int32arr_return_or_eof_read[0] -eq (-1)){ # EOF の場合
                break # EOF まで read() する loop から break
            
            } else{
                $script_block_judger[0] = $script_block_in_code
                $script_block_judger[1] = $script_block_dummy
                continue # EOF まで read() する loop の先頭へ
            }
        }
    }

    # ------------------------------------------------------------------------------------------ </ $script_block_judger[1] 用 > 

    # -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- </字句解析状態に応じた判定条件> 

    $_listener = {

        $bool_escaped_return[0] = $false

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
                $bool_escaped_return[0] = $true
            
            } else { # 改行に対するエスケープではない場合

                $bool_escaped_return[0] = $false

                $int_last_idx_of_lex_history = $int_2darr_lex_history.Add( @($int_last_index_of_read_buffer_l1, 0, $int_added_index) )

                & $script_block_judger[0] # <字句解析状態に応じた判定条件> (行内用)

            }
        }

        & $script_block_judger[1] # <字句解析状態に応じた判定条件> (行末用)

        if($int32arr_return_or_eof_read[0] -eq (-1)){ # EOF の場合

            $int_typ_flgs[0] = $true

            # 字句解析した最後までをコード解析の区切りとする
            $int_last_index_of_read_buffer_l1 = $int32_3darr_read_buffer.Count -1
            func_slice_read_buffer ($int_last_index_of_read_buffer_l1) (0) ($int32_3darr_read_buffer[$int_last_index_of_read_buffer_l1][0].Count)
            $int_2darr_lex_history.Clear() # 字句解析履歴をクリア
            . $_try_delimition_lister

            break
        }

        #   |      ※0 initialize        |                     ※1 ループ終了判定                           |  ※2 ループ終了判定の直前   |
        for ($int_char_index_of_line = 0 ; $int_char_index_of_line -lt $int32arr_return_or_eof_read.Count ; $int_char_index_of_line++ ){

            $int_last_index_of_read_buffer_l1 = $int32_3darr_read_buffer.Count -1
            $int32_3darr_read_buffer[$int_last_index_of_read_buffer_l1][1].Add($int32arr_return_or_eof_read[$int_char_index_of_line])
            $int_added_index = $int32_3darr_read_buffer[$int_last_index_of_read_buffer_l1][1].Count - 1

            if ( ! $bool_escaped_return[0] ) { # エスケープされた改行ではない場合
                $int_last_idx_of_lex_history = $int_2darr_lex_history.Add( @($int_last_index_of_read_buffer_l1, 1, $int_added_index) )
            }

        }
    }

    $int_2darr_lex_history = New-Object System.Collections.ArrayList

    # 字句解析状態を `コード中` に設定
    # ( ※note
    #    <字句解析状態に応じた判定条件> 内のスクリプトブロックから
    #    状態を変更する必要があるので、配列定義にして index [0] に対してアクセス
    #    状態を変更するようにする
    # )
    $script_block_judger = New-Object System.Collections.ArrayList
    $script_block_judger.Add($script_block_in_code) | Out-Null  # (行内用)
    $script_block_judger.Add($script_block_dummy) | Out-Null    # (行末用)

    # ( ※note
    #    <字句解析状態に応じた判定条件> 内のスクリプトブロックから
    #    状態を変更する必要があるので、配列定義にして index [0] に対してアクセス
    #    状態を変更するようにする
    # )
    $bool_escaped_return = New-Object System.Collections.ArrayList
    $bool_escaped_return.Add($false) | Out-Null

    $int_typ_flgs = New-Object System.Collections.ArrayList
    $int_typ_flgs.Add($false) | Out-Null     # EOFかどうか -> [0]
    $int_typ_flgs.Add($TYP_CLEAR) | Out-Null # コード解析状態   -> [1]
    $int_typ_flgs.Add($TYP_CLEAR) | Out-Null # コメント解析状態 -> [2]

    # コード解析中 状態に設定
    $int_typ_flgs[0] = $false
    $int_typ_flgs[1] = $TYP_CODE
    $int_typ_flgs[2] = $TYP_CLEAR

    # $script__listerner = New-Object System.Collections.ArrayList
    # $script__listerner.Add($_listener) | Out-Null

    _func_lex($filepath) ($encoding) ($_listener) ($delimition_listener)
}


function Stringify{

    $_to_ret_str = New-Object System.Text.StringBuilder

    for ($_l1 = 0 ; $_l1 -lt $delimitedBytes.Count ; $_l1++){
        for ($_l2 = 0 ; $_l2 -lt $delimitedBytes[$_l1].Count ; $_l2++){
            if ($delimitedBytes[$_l1][$_l2].Count -gt 0){
                $_tmpstr = $enc_s.GetString($delimitedBytes[$_l1][$_l2])
                $_to_ret_str.Append($_tmpstr) | Out-Null
            }
        }
    }

    Write-Output $_to_ret_str
}
