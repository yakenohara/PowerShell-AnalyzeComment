# <License>------------------------------------------------------------

#  Copyright (c) 2019 Shinnosuke Yakenohara

#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

# -----------------------------------------------------------</License>

set-variable -name TYP_CLEAR           -value 0x0 -option constant

set-variable -name TYP_CODE            -value 0x1 -option constant
set-variable -name TYP_CODE_QUOTE      -value 0x3 -option constant
set-variable -name TYP_CODE_DQUOTE     -value 0x5 -option constant

set-variable -name TYP_COMMENT         -value 0x1 -option constant
set-variable -name TYP_COMMENT_SINGLE  -value 0x3 -option constant
set-variable -name TYP_COMMENT_MULTI   -value 0x5 -option constant

function _func_lex($_file_path, $_str_encoding, $_scrpt_blc_line_listener, $_delimition_listener){

    # `System.IO.FileStream.ReadByte()` 用
    $_int32_genlst_chr_buf = New-Object 'System.Collections.Generic.List[int32]'

    # `System.IO.FileStream.ReadByte()` 後の改行コード解析中に使用する buffer
    $_int32_3Darr_line_buf = New-Object System.Collections.ArrayList

    # 字句解析中に使用する buffer
    $_int32_3Darr_lex_buf = New-Object System.Collections.ArrayList
    
    # `$_delimition_listener` がアクセスする 字句解析結果
    $delimitedBytes = New-Object System.Collections.ArrayList

    # `$_delimition_listener` 内で Stringify が call された時に使用する
    $enc = 0

    $progress = New-Object System.Collections.ArrayList
    # [0] for file info
    # [1] for read position
    
    # <引数チェック> ----------------------------------------------------------------

    if ( [string]::IsNullOrEmpty($_str_encoding) ){
        Write-Error "[error] Null or empty string cannot be specified as encoding"
        return
    }

    try{
        $enc = [Text.Encoding]::GetEncoding($_str_encoding)
    
    } catch { # 存在しないエンコードを指定した場合
        Write-Error ("[error] " + $_.Exception.Message)
        return
    }

    try{
        $_fs_reader = New-Object System.IO.FileStream($_file_path, 3) # 読み取り専用で開く
        $progress.Add( (New-Object System.IO.FileInfo($_file_path)) ) | Out-Null
        $progress.Add( 0 ) | Out-Null # read position
    
    } catch { # ファイルオープン失敗の場合
        Write-Error ("[error] " + $_.Exception.Message)
        return
    }

    # --------------------------------------------------------------- </引数チェック> 
    
    # ファイル内文字列判定用
    $_bytearr_crlf          = $enc.GetBytes("`r`n")
    $_bytearr_backslash     = $enc.GetBytes("\")
    $_bytearr_quote         = $enc.GetBytes("'")
    $_bytearr_doublequote   = $enc.GetBytes("`"")
    $_bytearr_doubleslath   = $enc.GetBytes("//")
    $_bytearr_slashaster    = $enc.GetBytes("/*")
    $_bytearr_asterslash    = $enc.GetBytes("*/")

    $_scrpt_blc_try_delimition_lister = {

        try{
            & $_delimition_listener # listener call
        } catch {
            Write-Error ("[error] " + $_.Exception.Message)
            $_fs_reader.Close() # ファイルクローズ
            return # _func_lex を終了
        }
    }

    function _func_read_line{
        
        function _func_add_line_buf($int_start_index, $int_last_idx){
    
            $int32arr_line = New-Object 'System.Collections.Generic.List[int32]'
            $int32arr_return = New-Object 'System.Collections.Generic.List[int32]'
    
            if ( $_int32_genlst_chr_buf.Count -gt ($int_start_index * (-1)) ){ # read() した 改行コード以外の文字列が存在する場合

                # 行 bytes の取得
                $int_lp_1st_idx = 0
                $int_lp_lat_idx = ($_int32_genlst_chr_buf.Count + $int_start_index - 1)
                for ($counter = $int_lp_1st_idx ; $counter -le $int_lp_lat_idx ; $counter++){
                    $int32arr_line.Add($_int32_genlst_chr_buf[$counter])
                }
            }

            # 改行コードの取得
            $int_lp_1st_idx = ($_int32_genlst_chr_buf.Count + $int_start_index)
            $int_lp_lat_idx = ($_int32_genlst_chr_buf.Count + $int_last_idx)
            for ($counter = $int_lp_1st_idx ; $counter -le $int_lp_lat_idx ; $counter++){
                $int32arr_return.Add($_int32_genlst_chr_buf[$counter])
            }
    
            $_int32_3Darr_line_buf.Add(@($int32arr_line, $int32arr_return)) | Out-Null
    
            if ($int_last_idx -lt (-1)){ # 最終 index が配列最後ではない場合
                
                # string buffer 削除前 backup
                $int32arr_tmp = New-Object 'System.Collections.Generic.List[int32]'
                $int_lp_1st_idx = ($_int32_genlst_chr_buf.Count + $int_last_idx + 1)
                $int_lp_lat_idx = ($_int32_genlst_chr_buf.Count - 1)
                for ($counter = $int_lp_1st_idx ; $counter -le $int_lp_lat_idx ; $counter++){
                    $int32arr_tmp.Add($_int32_genlst_chr_buf[$counter])
                }

                $_int32_genlst_chr_buf.Clear() # string buffer 削除

                # buckup した string buffer を格納
                foreach ($byte_elem_of_tmp in $int32arr_tmp){
                    $_int32_genlst_chr_buf.Add($byte_elem_of_tmp)
                }
                
            } else { # 最終 index が配列最後の場合
                $_int32_genlst_chr_buf.Clear()
            }
        }

        # 行末まで read() する loop
        while($true){
    
            $byte_char = $_fs_reader.ReadByte()
            
            if ($byte_char -eq (-1)){
        
                if ($_int32_genlst_chr_buf.Count -gt 0){ # 1 文字以上 read() している場合
        
                    if ( # CR 改行の場合
                        ( $_int32_genlst_chr_buf[$_int32_genlst_chr_buf.Count - 1] -eq $_bytearr_crlf[0] )
                    ){
                        _func_add_line_buf (-1) (-1) # 最後の 1文字 を改行コードに指定して buffering

                    } elseif ( # LF 改行の場合
                        ( $_int32_genlst_chr_buf[$_int32_genlst_chr_buf.Count - 1] -eq $_bytearr_crlf[1] )
                    ){            
                        _func_add_line_buf (-1) (-1) # 最後の 1文字 を改行コードに指定して buffering

                    }
                }
                
                $_int32_genlst_chr_buf.Add($byte_char)
        
                _func_add_line_buf (-1) (-1) # 最後の 1文字 を改行コードに指定して buffering

                break
            }
        
            $_int32_genlst_chr_buf.Add($byte_char)
            
            if ($_int32_genlst_chr_buf.Count -gt 1){ # 2 文字以上 read() している場合
                
                if ( # CRLF 改行の場合
                    ( $_int32_genlst_chr_buf[$_int32_genlst_chr_buf.Count - 2] -eq $_bytearr_crlf[0] ) -And
                    ( $_int32_genlst_chr_buf[$_int32_genlst_chr_buf.Count - 1] -eq $_bytearr_crlf[1] )
                ){
                    _func_add_line_buf (-2) (-1) # 最後の 2bytes を改行コードに指定して buffering
                    break
                }

                if ( # CR 改行の場合
                    ( $_int32_genlst_chr_buf[$_int32_genlst_chr_buf.Count - 2] -eq $_bytearr_crlf[0] )
                ){
                    _func_add_line_buf (-2) (-2) # 最後の 2bytes を改行コードに指定して buffering
                    break
                }

                $bool_lf_found = $false

                if ( # 2 byte の内 1 byte目が LF の場合
                    ( $_int32_genlst_chr_buf[$_int32_genlst_chr_buf.Count - 2] -eq $_bytearr_crlf[1] )
                ){
                    _func_add_line_buf (-2) (-2) # 最後の 2byte 目だけを改行コードに指定して buffering
                    $bool_lf_found = $true
                }
                if ( # 2 byte の内 2 byte目が LF の場合
                    ( $_int32_genlst_chr_buf[$_int32_genlst_chr_buf.Count - 1] -eq $_bytearr_crlf[1] )
                ){
                    _func_add_line_buf (-1) (-1) # 最後の 1byte を改行コードに指定して buffering
                    $bool_lf_found = $true
                }

                if ($bool_lf_found){ # 2 byte の内 いずれかに LF が存在した場合
                    break
                }
            }
        }
    }

    function _func_slice_lex_buf($l1_lst_idx, $l2_lst_idx, $l3_1st_idx_of_2nd){

        # Write-Host ('$l1_lst_idx:' + ([string]$l1_lst_idx) + ', $l2_lst_idx:' + ([string]$l2_lst_idx) + ', $l3_1st_idx_of_2nd:' + ([string]$l3_1st_idx_of_2nd))

        $l2 = 0

        $delimitedBytes.Clear()

        if ( # 区切りる必要がない場合
            ($l1_lst_idx -eq 0) -and
            ($l2_lst_idx -eq 0) -and
            ($l3_1st_idx_of_2nd -eq 0)
        ){
            Write-Output $false # '区切りませんでした' を返す
            return
        }

        # 行定義の直前までコピーする loop
        for ($l1 = 0 ; $l1 -lt $l1_lst_idx ; $l1++){

            $lstidx = $delimitedBytes.Add( (New-Object System.Collections.ArrayList) )

            $delimitedBytes[$lstidx].Add( (New-Object 'System.Collections.Generic.List[int32]') ) | Out-Null
            $delimitedBytes[$lstidx].Add( (New-Object 'System.Collections.Generic.List[int32]') ) | Out-Null

            for ($l2 = 0 ; $l2 -lt 2 ; $l2++){
                if( $_int32_3Darr_lex_buf[0][$l2].Count -gt 0){

                    for ($l3 = 0 ; $l3 -lt ($_int32_3Darr_lex_buf[0][$l2].Count) ; $l3++){
                        $delimitedBytes[$lstidx][$l2].Add( $_int32_3Darr_lex_buf[0][$l2][$l3] )
                    }
                }
            }
            $_int32_3Darr_lex_buf.RemoveAt(0)
        }

        # 行定義の最後をコピーする loop
        $lstidx = $delimitedBytes.Add( (New-Object System.Collections.ArrayList) )
        $delimitedBytes[$lstidx].Add( (New-Object 'System.Collections.Generic.List[int32]') ) | Out-Null
        $delimitedBytes[$lstidx].Add( (New-Object 'System.Collections.Generic.List[int32]') ) | Out-Null
        for ($l2 = 0 ; $l2 -lt $l2_lst_idx ; $l2++){
            if( $_int32_3Darr_lex_buf[0][$l2].Count -gt 0){
                for ($l3 = 0 ; $l3 -lt ($_int32_3Darr_lex_buf[0][$l2].Count) ; $l3++){
                    $delimitedBytes[$lstidx][$l2].Add( $_int32_3Darr_lex_buf[0][$l2][$l3] )
                }
            }
            $_int32_3Darr_lex_buf[0][$l2].Clear()
        }

        # 行定義のスライス対象要素を スライス
        $int32arr_1st_of_sliced = (New-Object 'System.Collections.Generic.List[int32]')
        $int32arr_2nd_of_sliced = (New-Object 'System.Collections.Generic.List[int32]')

        for ($xxx = 0 ; $xxx -lt $l3_1st_idx_of_2nd ; $xxx++ ){
            $int32arr_1st_of_sliced.Add($_int32_3Darr_lex_buf[0][$l2][$xxx])
        }

        for ($yyy = $l3_1st_idx_of_2nd ; $yyy -lt ($_int32_3Darr_lex_buf[0][$l2].Count) ; $yyy++ ){
            $int32arr_2nd_of_sliced.Add($_int32_3Darr_lex_buf[0][$l2][$yyy])
        }

        # スライスした 前半を コピー
        if ($int32arr_1st_of_sliced.Count -gt 0){
            $delimitedBytes[$lstidx][$l2] = $int32arr_1st_of_sliced
        }

        # スライスした 後半を buffer に貯め直し
        $_int32_3Darr_lex_buf[0][$l2_lst_idx] = $int32arr_2nd_of_sliced

        Write-Output $true # '区切りました' を返す
    }

    # EOF まで read() する loop
    while($true){

        if ( $_int32_3Darr_line_buf.Count -eq 0 ){
            _func_read_line
        }

        $_int32arr_lst_read_line = $_int32_3Darr_line_buf[0][0]
        $_int32arr_lst_read_nlc = $_int32_3Darr_line_buf[0][1]
        $_int32_3Darr_line_buf.RemoveAt(0)

        # buffering 行要素
        $_int_lex_buf_l1_lst_idx = $_int32_3Darr_lex_buf.Add( (New-Object System.Collections.ArrayList) )
        $_int32_3Darr_lex_buf[$_int_lex_buf_l1_lst_idx].Add( (New-Object 'System.Collections.Generic.List[int32]') )  | Out-Null # 行文字列用
        $_int32_3Darr_lex_buf[$_int_lex_buf_l1_lst_idx].Add( (New-Object 'System.Collections.Generic.List[int32]') )  | Out-Null # 改行 or EOF 格納用

        . $_scrpt_blc_line_listener # 行毎にコールするスクリプトブロック
    }
    
    $_fs_reader.Close() # ファイルクローズ
}

function LexLine($filePath, $encoding, $delimitionListener){

    # 行毎にコールするスクリプトブロック
    $_scrpt_blc_line_listener = {

        $endindx = 0
        $_int32_3Darr_lex_buf[$_int_lex_buf_l1_lst_idx][$endindx] = $_int32arr_lst_read_line
        $progress[1] += $_int32arr_lst_read_line.Count

        if($_int32arr_lst_read_nlc[0] -eq (-1)){ # EOF の場合            
            
            $_intarr_typ_flgs[0] = $true

            _func_slice_lex_buf ($_int_lex_buf_l1_lst_idx) ($endindx) ($_int32_3Darr_lex_buf[$_int_lex_buf_l1_lst_idx][$endindx].Count) | Out-Null
            . $_scrpt_blc_scrpt_blc_copy_flags
            . $_scrpt_blc_try_delimition_lister # `$delimitionListener` の実行

            break

        } else { # EOF ではない場合
            $_int32_3Darr_lex_buf[$_int_lex_buf_l1_lst_idx][++$endindx] = $_int32arr_lst_read_nlc # 改行コードを格納
            $progress[1] += $_int32arr_lst_read_nlc.Count
            _func_slice_lex_buf ($_int_lex_buf_l1_lst_idx) ($endindx) ($_int32_3Darr_lex_buf[$_int_lex_buf_l1_lst_idx][$endindx].Count) | Out-Null
            . $_scrpt_blc_scrpt_blc_copy_flags
            . $_scrpt_blc_try_delimition_lister # `$delimitionListener` の実行
        }
    }

    $_intarr_typ_flgs = New-Object System.Collections.ArrayList
    $_intarr_typ_flgs.Add($false) | Out-Null     # EOFかどうか -> [0]

    $_scrpt_blc_scrpt_blc_copy_flags = {
        $typeFlags = New-Object System.Collections.ArrayList
        $typeFlags.Add($_intarr_typ_flgs[0]) | Out-Null     # EOFかどうか -> [0]
    }
    
    _func_lex($filePath) ($encoding) ($_scrpt_blc_line_listener) ($delimitionListener)
}

function LexComment($filePath, $encoding, $delimitionListener){

    # <字句解析状態に応じた判定条件> ------------------------------------------------------------------------------------------------------------------------------------

    # なにもさせたくないときに指定する
    $_scrpt_blc_dummy = {
        #nothing to do
    }

    # < $_scrpt_blc_judger[0] 用 >  -----------------------------------------------------------------------------------------------------------------------------

    # `コード` -> ( `' 文字列` or `" 文字列` or `// コメント` or `/* */ コメント` )
    $_scrpt_blc_in_code = {

        if ( # `'` の場合
            ( $_int32_3Darr_lex_buf[$_lex_history[$_lst_his][0]][$_lex_history[$_lst_his][1]][$_lex_history[$_lst_his][2]] -eq $_bytearr_quote[0] )
        ){
            if ( # エスケープされた `'` の場合
                ( $_lst_his -gt 0 ) -And
                ( $_int32_3Darr_lex_buf[$_lex_history[$_lst_his - 1][0]][$_lex_history[$_lst_his - 1][1]][$_lex_history[$_lst_his - 1][2]] -eq $_bytearr_backslash[0] )
            ){
                # nothing to do
                
            } else { # エスケープされていない `'` の場合

                # last index of lexical analysis history の直前までをコード解析の区切りとする
                $_was_delimited = _func_slice_lex_buf ($_lex_history[$_lst_his][0]) ($_lex_history[$_lst_his][1]) ($_lex_history[$_lst_his][2])
                $_lex_history.Clear() # 字句解析履歴をクリア

                if ($_was_delimited){
                    . $_scrpt_blc_scrpt_blc_copy_flags
                    . $_scrpt_blc_try_delimition_lister # `$delimitionListener` の実行
                }
                
                $_intarr_typ_flgs[1] = $TYP_CODE_QUOTE
                $_intarr_typ_flgs[2] = $TYP_CLEAR

                $_scrpt_blc_judger[0] = $_scrpt_blc_in_single_quote
                $_scrpt_blc_judger[1] = $_scrpt_blc_dummy

                continue # `※2 ループ終了判定の直前` へ
            }
        }

        if ( # `"` の場合
            ( $_int32_3Darr_lex_buf[$_lex_history[$_lst_his][0]][$_lex_history[$_lst_his][1]][$_lex_history[$_lst_his][2]] -eq $_bytearr_doublequote[0] )
        ){
            if ( # エスケープされた `"` の場合
                ( $_lst_his -gt 0 ) -And
                ( $_int32_3Darr_lex_buf[$_lex_history[$_lst_his - 1][0]][$_lex_history[$_lst_his - 1][1]][$_lex_history[$_lst_his - 1][2]] -eq $_bytearr_backslash[0] )
            ){
                # nothing to do
                
            } else { # エスケープされていない `"` の場合

                # last index of lexical analysis history の直前までをコード解析の区切りとする
                $_was_delimited = _func_slice_lex_buf ($_lex_history[$_lst_his][0]) ($_lex_history[$_lst_his][1]) ($_lex_history[$_lst_his][2])
                $_lex_history.Clear() # 字句解析履歴をクリア
                
                if ($_was_delimited){
                    . $_scrpt_blc_scrpt_blc_copy_flags
                    . $_scrpt_blc_try_delimition_lister # `$delimitionListener` の実行
                }

                $_intarr_typ_flgs[1] = $TYP_CODE_DQUOTE
                $_intarr_typ_flgs[2] = $TYP_CLEAR

                $_scrpt_blc_judger[0] = $_scrpt_blc_in_double_quote
                $_scrpt_blc_judger[1] = $_scrpt_blc_dummy

                continue # `※2 ループ終了判定の直前` へ
            }
        }

        if ( # `//` の場合
            ( $_lst_his -gt 0 ) -And
            ( $_int32_3Darr_lex_buf[$_lex_history[$_lst_his-1][0]][$_lex_history[$_lst_his-1][1]][$_lex_history[$_lst_his-1][2]] -eq $_bytearr_doubleslath[0] ) -And
            ( $_int32_3Darr_lex_buf[$_lex_history[$_lst_his][0]][$_lex_history[$_lst_his][1]][$_lex_history[$_lst_his][2]] -eq $_bytearr_doubleslath[1] )
        ){
            
            # 2nd of last index of lexical analysis history の直前までをコード解析の区切りとする
            $_was_delimited = _func_slice_lex_buf ($_lex_history[$_lst_his-1][0]) ($_lex_history[$_lst_his-1][1]) ($_lex_history[$_lst_his-1][2])
            $_lex_history.Clear() # 字句解析履歴をクリア

            if ($_was_delimited){
                . $_scrpt_blc_scrpt_blc_copy_flags
                . $_scrpt_blc_try_delimition_lister # `$delimitionListener` の実行
            }

            $_intarr_typ_flgs[1] = $TYP_CLEAR
            $_intarr_typ_flgs[2] = $TYP_COMMENT_SINGLE

            $_scrpt_blc_judger[0] = $_scrpt_blc_dummy
            $_scrpt_blc_judger[1] = $_scrpt_blc_in_double_slash_comment

            continue # `※2 ループ終了判定の直前` へ
        }

        if ( # `/*` の場合
            ( $_lst_his -gt 0 ) -And
            ( $_int32_3Darr_lex_buf[$_lex_history[$_lst_his-1][0]][$_lex_history[$_lst_his-1][1]][$_lex_history[$_lst_his-1][2]] -eq $_bytearr_slashaster[0] ) -And
            ( $_int32_3Darr_lex_buf[$_lex_history[$_lst_his][0]][$_lex_history[$_lst_his][1]][$_lex_history[$_lst_his][2]] -eq $_bytearr_slashaster[1] )
        ){
            
            # 2nd of last index of lexical analysis history の直前までをコード解析の区切りとする
            $_was_delimited = _func_slice_lex_buf ($_lex_history[$_lst_his-1][0]) ($_lex_history[$_lst_his-1][1]) ($_lex_history[$_lst_his-1][2])
            $_lex_history.Clear() # 字句解析履歴をクリア

            if ($_was_delimited){
                . $_scrpt_blc_scrpt_blc_copy_flags
                . $_scrpt_blc_try_delimition_lister # `$delimitionListener` の実行
            }
            
            $_intarr_typ_flgs[1] = $TYP_CLEAR
            $_intarr_typ_flgs[2] = $TYP_COMMENT_MULTI

            $_scrpt_blc_judger[0] = $_scrpt_blc_in_slash_aster_comment
            $_scrpt_blc_judger[1] = $_scrpt_blc_dummy

            continue # `※2 ループ終了判定の直前` へ
        }
    }

    # `' 文字列` -> `コード`
    $_scrpt_blc_in_single_quote = {

        if ( # `'` の場合
            ( $_int32_3Darr_lex_buf[$_lex_history[$_lst_his][0]][$_lex_history[$_lst_his][1]][$_lex_history[$_lst_his][2]] -eq $_bytearr_quote[0] )
        ){
            if ( # エスケープされた `'` の場合
                ( $_lst_his -gt 0 ) -And
                ( $_int32_3Darr_lex_buf[$_lex_history[$_lst_his - 1][0]][$_lex_history[$_lst_his - 1][1]][$_lex_history[$_lst_his - 1][2]] -eq $_bytearr_backslash[0] )
            ){
                # nothing to do
                
            } else { # エスケープされていない `'` の場合

                # 字句解析した最後までをコード解析の区切りとする
                $_int_lex_buf_l1_lst_idx = $_int32_3Darr_lex_buf.Count -1
                $_was_delimited = _func_slice_lex_buf ($_int_lex_buf_l1_lst_idx) (0) ($_int32_3Darr_lex_buf[$_int_lex_buf_l1_lst_idx][0].Count)
                $_lex_history.Clear() # 字句解析履歴をクリア

                if ($_was_delimited){
                    . $_scrpt_blc_scrpt_blc_copy_flags
                    . $_scrpt_blc_try_delimition_lister # `$delimitionListener` の実行
                }

                $_intarr_typ_flgs[1] = $TYP_CODE
                $_intarr_typ_flgs[2] = $TYP_CLEAR

                $_scrpt_blc_judger[0] = $_scrpt_blc_in_code
                $_scrpt_blc_judger[1] = $_scrpt_blc_dummy

                continue # `※2 ループ終了判定の直前` へ
            }
        }
    }

    # `" 文字列` -> `コード`
    $_scrpt_blc_in_double_quote = {

        if ( # `"` の場合
            ( $_int32_3Darr_lex_buf[$_lex_history[$_lst_his][0]][$_lex_history[$_lst_his][1]][$_lex_history[$_lst_his][2]] -eq $_bytearr_doublequote[0] )
        ){
            if ( # エスケープされた `"` の場合
                ( $_lst_his -gt 0 ) -And
                ( $_int32_3Darr_lex_buf[$_lex_history[$_lst_his - 1][0]][$_lex_history[$_lst_his - 1][1]][$_lex_history[$_lst_his - 1][2]] -eq $_bytearr_backslash[0] )
            ){
                # nothing to do
                
            } else { # エスケープされていない `"` の場合

                # 字句解析した最後までをコード解析の区切りとする
                $_int_lex_buf_l1_lst_idx = $_int32_3Darr_lex_buf.Count -1
                $_was_delimited = _func_slice_lex_buf ($_int_lex_buf_l1_lst_idx) (0) ($_int32_3Darr_lex_buf[$_int_lex_buf_l1_lst_idx][0].Count)
                $_lex_history.Clear() # 字句解析履歴をクリア
                
                if ($_was_delimited){
                    . $_scrpt_blc_scrpt_blc_copy_flags
                    . $_scrpt_blc_try_delimition_lister # `$delimitionListener` の実行
                }

                $_intarr_typ_flgs[1] = $TYP_CODE
                $_intarr_typ_flgs[2] = $TYP_CLEAR

                $_scrpt_blc_judger[0] = $_scrpt_blc_in_code
                $_scrpt_blc_judger[1] = $_scrpt_blc_dummy

                continue # `※2 ループ終了判定の直前` へ
            }
        }
    }

    # `/* */ コメント` -> `コード`
    $_scrpt_blc_in_slash_aster_comment = {

        if ( # `*/` の場合
            ( $_lst_his -gt 0 ) -And
            ( $_int32_3Darr_lex_buf[$_lex_history[$_lst_his-1][0]][$_lex_history[$_lst_his-1][1]][$_lex_history[$_lst_his-1][2]] -eq $_bytearr_asterslash[0] ) -And
            ( $_int32_3Darr_lex_buf[$_lex_history[$_lst_his][0]][$_lex_history[$_lst_his][1]][$_lex_history[$_lst_his][2]] -eq $_bytearr_asterslash[1] )
        ){
            
            # 字句解析した最後までをコード解析の区切りとする
            $_int_lex_buf_l1_lst_idx = $_int32_3Darr_lex_buf.Count -1
            $_was_delimited = _func_slice_lex_buf ($_int_lex_buf_l1_lst_idx) (0) ($_int32_3Darr_lex_buf[$_int_lex_buf_l1_lst_idx][0].Count)
            $_lex_history.Clear() # 字句解析履歴をクリア

            if ($_was_delimited){
                . $_scrpt_blc_scrpt_blc_copy_flags
                . $_scrpt_blc_try_delimition_lister # `$delimitionListener` の実行
            }

            $_intarr_typ_flgs[1] = $TYP_CODE
            $_intarr_typ_flgs[2] = $TYP_CLEAR

            $_scrpt_blc_judger[0] = $_scrpt_blc_in_code
            $_scrpt_blc_judger[1] = $_scrpt_blc_dummy

            continue # `※2 ループ終了判定の直前` へ
        }
    }

    # ---------------------------------------------------------------------------------------------------------------------------- </ $_scrpt_blc_judger[0] 用 >  

    # < $_scrpt_blc_judger[1] 用 >  -----------------------------------------------------------------------------------------------------------------------------

    # `// コメント` -> `コード`
    $_scrpt_blc_in_double_slash_comment = {

        if ( ! $_bool_escaped_return[0] ) { # エスケープされた改行ではない場合

            $first_layer = $_int32_3Darr_lex_buf.Count -1
            $scond_layer = 0
            $third_layer = 0

            if($_int32arr_lst_read_nlc[0] -eq (-1)){ # EOF の場合

                $scond_layer = 0
                $_intarr_typ_flgs[0] = $true

            } else {  # 改行コードありの場合

                $scond_layer = 1

                # 改行コードを buffer に乗せるループ
                for ($int_char_index_of_line = 0 ; $int_char_index_of_line -lt $_int32arr_lst_read_nlc.Count ; $int_char_index_of_line++ ){
                    
                    $_int32_3Darr_lex_buf[$first_layer][$scond_layer].Add($_int32arr_lst_read_nlc[$int_char_index_of_line])
                    $progress[1]++
                    $int_added_index = $_int32_3Darr_lex_buf[$first_layer][$scond_layer].Count - 1
                    $_lex_history.Add( @($first_layer, $scond_layer, $int_added_index) ) | Out-Null

                }
            }

            $third_layer = $_int32_3Darr_lex_buf[$first_layer][$scond_layer].Count

            # 字句解析した最後までをコード解析の区切りとする
            $_was_delimited = _func_slice_lex_buf ($first_layer) ($scond_layer) ($third_layer)
            $_lex_history.Clear() # 字句解析履歴をクリア

            if ($_was_delimited){
                . $_scrpt_blc_scrpt_blc_copy_flags
                . $_scrpt_blc_try_delimition_lister # `$delimitionListener` の実行
            }

            $_intarr_typ_flgs[1] = $TYP_CODE
            $_intarr_typ_flgs[2] = $TYP_CLEAR

            if($_int32arr_lst_read_nlc[0] -eq (-1)){ # EOF の場合
                break # EOF まで read() する loop から break
            
            } else{
                $_scrpt_blc_judger[0] = $_scrpt_blc_in_code
                $_scrpt_blc_judger[1] = $_scrpt_blc_dummy
                continue # EOF まで read() する loop の先頭へ
            }
        }
    }

    # ---------------------------------------------------------------------------------------------------------------------------- </ $_scrpt_blc_judger[1] 用 >

    # ----------------------------------------------------------------------------------------------------------------------------------- </字句解析状態に応じた判定条件> 

    $_scrpt_blc_line_listener = {

        $_bool_escaped_return[0] = $false

        #   |      ※0 initialize        |                     ※1 ループ終了判定                  |  ※2 ループ終了判定の直前   |
        for ($int_char_index_of_line = 0 ; $int_char_index_of_line -lt $_int32arr_lst_read_line.Count ; $int_char_index_of_line++ ){

            $_int_lex_buf_l1_lst_idx = $_int32_3Darr_lex_buf.Count -1
            $_int32_3Darr_lex_buf[$_int_lex_buf_l1_lst_idx][0].Add($_int32arr_lst_read_line[$int_char_index_of_line])
            $progress[1]++
            $int_added_index = $_int32_3Darr_lex_buf[$_int_lex_buf_l1_lst_idx][0].Count - 1

            if( # 改行に対するエスケープの場合
                ( $int_char_index_of_line -eq ($_int32arr_lst_read_line.Count-1) ) -And              # <- 行の最後の byte の場合に TRUE
                ( $_int32arr_lst_read_line[$int_char_index_of_line] -eq $_bytearr_backslash[0] ) -And # <- `\` の場合に TRUE
                ( $_int32arr_lst_read_nlc[0] -ne (-1) )                                    # <- 改行コードの場合に TRUE
            ){
                $_bool_escaped_return[0] = $true
            
            } else { # 改行に対するエスケープではない場合

                $_bool_escaped_return[0] = $false

                $_lst_his = $_lex_history.Add( @($_int_lex_buf_l1_lst_idx, 0, $int_added_index) )

                & $_scrpt_blc_judger[0] # <字句解析状態に応じた判定条件> (行内用)

            }
        }

        & $_scrpt_blc_judger[1] # <字句解析状態に応じた判定条件> (行末用)

        if($_int32arr_lst_read_nlc[0] -eq (-1)){ # EOF の場合

            $_intarr_typ_flgs[0] = $true

            # 字句解析した最後までをコード解析の区切りとする
            $_int_lex_buf_l1_lst_idx = $_int32_3Darr_lex_buf.Count -1
            $_was_delimited = _func_slice_lex_buf ($_int_lex_buf_l1_lst_idx) (0) ($_int32_3Darr_lex_buf[$_int_lex_buf_l1_lst_idx][0].Count)
            $_lex_history.Clear() # 字句解析履歴をクリア

            if ($_was_delimited){
                . $_scrpt_blc_scrpt_blc_copy_flags
                . $_scrpt_blc_try_delimition_lister # `$delimitionListener` の実行
            }

            break
        }

        #   |      ※0 initialize        |                     ※1 ループ終了判定                           |  ※2 ループ終了判定の直前   |
        for ($int_char_index_of_line = 0 ; $int_char_index_of_line -lt $_int32arr_lst_read_nlc.Count ; $int_char_index_of_line++ ){

            $_int_lex_buf_l1_lst_idx = $_int32_3Darr_lex_buf.Count -1
            $_int32_3Darr_lex_buf[$_int_lex_buf_l1_lst_idx][1].Add($_int32arr_lst_read_nlc[$int_char_index_of_line])
            $progress[1]++
            $int_added_index = $_int32_3Darr_lex_buf[$_int_lex_buf_l1_lst_idx][1].Count - 1

            if ( ! $_bool_escaped_return[0] ) { # エスケープされた改行ではない場合
                $_lst_his = $_lex_history.Add( @($_int_lex_buf_l1_lst_idx, 1, $int_added_index) )
            }

        }
    }

    # `_int32_3Darr_lex_buf[?][?][?]` に対する 字句解析ログ
    $_lex_history = New-Object System.Collections.ArrayList

    # 字句解析状態を `コード中` に設定
    # ( ※note
    #    <字句解析状態に応じた判定条件> 内のスクリプトブロックから
    #    状態を変更する必要があるので、配列定義にして index [0] に対してアクセス
    #    状態を変更するようにする
    # )
    $_scrpt_blc_judger = New-Object System.Collections.ArrayList
    $_scrpt_blc_judger.Add($_scrpt_blc_in_code) | Out-Null  # (行内用)
    $_scrpt_blc_judger.Add($_scrpt_blc_dummy) | Out-Null    # (行末用)

    # エスケープされた改行かどうか
    # ( ※note
    #    <字句解析状態に応じた判定条件> 内のスクリプトブロックから
    #    状態を変更する必要があるので、配列定義にして index [0] に対してアクセス
    #    状態を変更するようにする
    # )
    $_bool_escaped_return = New-Object System.Collections.ArrayList
    $_bool_escaped_return.Add($false) | Out-Null

    $_intarr_typ_flgs = New-Object System.Collections.ArrayList
    $_intarr_typ_flgs.Add($false) | Out-Null     # EOFかどうか -> [0]
    $_intarr_typ_flgs.Add($TYP_CLEAR) | Out-Null # コード解析状態   -> [1]
    $_intarr_typ_flgs.Add($TYP_CLEAR) | Out-Null # コメント解析状態 -> [2]

    # コード解析中 状態に設定
    $_intarr_typ_flgs[0] = $false
    $_intarr_typ_flgs[1] = $TYP_CODE
    $_intarr_typ_flgs[2] = $TYP_CLEAR

    $_scrpt_blc_scrpt_blc_copy_flags = {
        $typeFlags = New-Object System.Collections.ArrayList
        $typeFlags.Add($_intarr_typ_flgs[0]) | Out-Null     # EOFかどうか -> [0]
        $typeFlags.Add($_intarr_typ_flgs[1]) | Out-Null     # コード解析状態   -> [1]
        $typeFlags.Add($_intarr_typ_flgs[2]) | Out-Null     # コメント解析状態 -> [2]
    }

    _func_lex($filePath) ($encoding) ($_scrpt_blc_line_listener) ($delimitionListener)
}

# 字句解析結果を文字列化して返す
function Stringify{

    $_to_ret_str = New-Object System.Text.StringBuilder

    for ($_l1 = 0 ; $_l1 -lt $delimitedBytes.Count ; $_l1++){
        for ($_l2 = 0 ; $_l2 -lt $delimitedBytes[$_l1].Count ; $_l2++){
            if ($delimitedBytes[$_l1][$_l2].Count -gt 0){
                $_tmpstr = $enc.GetString($delimitedBytes[$_l1][$_l2])
                $_to_ret_str.Append($_tmpstr) | Out-Null
            }
        }
    }

    Write-Output $_to_ret_str
}
