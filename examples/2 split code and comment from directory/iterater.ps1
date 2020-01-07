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

# <User Settings>-----------------------------------------

$strarr_extentions = @(
    "`.c",
    "`.cpp",
    "`.h"
)
# ----------------------------------------</User Settings>

$ps1_path = ".\splitter.ps1"
$ps1_abs_path = ( (Split-Path -Parent $MyInvocation.MyCommand.Path) + $ps1_path)

$to_lex_dir = Convert-Path $Args[0]
$comment_only_dir = Convert-Path $Args[1]
$code_only_dir = Convert-Path $Args[2]

#処理対象リスト作成
$list = New-Object System.Collections.Generic.List[System.String]

if (Test-Path $to_lex_dir -PathType Container){ #ディレクトリの場合
    Get-ChildItem  -Recurse -Force -Path $to_lex_dir | ForEach-Object {
        $list.Add($_.FullName)
    }
}else{
    #todo 終了
}

#パラメータ数チェック
if($list.count -eq 0){ #処理対象が指定されていない
    Write-Host "Argument not specified"
    $errOfTotal = 1
    
}else{ #処理対象が1つ以上ある

    $int_counter = 0
    $int_progAll = $list.count
    $int_dgts = $int_progAll.ToString("0").Length

    foreach ($path in $list) {
        
        if (Test-Path $path -PathType leaf) { #ファイルの場合

            $str_ext = [System.IO.Path]::GetExtension($path);

            $bool_in_list = $FALSE # 処理対象拡張子リストに存在するかどうか
            foreach ($str_extention in $strarr_extentions){
                if ( $str_ext -eq $str_extention ){ # 処理対象拡張子リストに存在する場合
                    $bool_in_list = $TRUE
                    break
                }
            }

            $comment_only_file_path = $path.Replace($to_lex_dir, $comment_only_dir)
            $code_only_file_path = $path.Replace($to_lex_dir, $code_only_dir)

            if ($bool_in_list) { # ソースコードの場合
                
                & $ps1_abs_path $path $comment_only_file_path $code_only_file_path ($int_counter+1) ($list.count)
                
            }else{ # ソースコードではない場合
                
                #only copy
                Write-Host (
                    ' (' +
                    ($int_counter+1).ToString("0").PadLeft($int_dgts) +
                    '/' +
                    $int_progAll.ToString("0").PadLeft($int_dgts) +
                    ') ' +
                    '100% processing ' +
                    $path
                )
                Copy-Item $path $comment_only_file_path
                Copy-Item $path $code_only_file_path
                
            }
        
        } else { # ディレクトリの場合
            Write-Host (
                ' (' +
                ($int_counter+1).ToString("0").PadLeft($int_dgts) +
                '/' +
                $int_progAll.ToString("0").PadLeft($int_dgts) +
                ') ' +
                'processing dir  ' + $path
            )
        }

        $int_counter++

    }
}
