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

$ps1_path = "\..\..\CommentLexer.ps1"
$enc_name = "utf-8"

# ----------------------------------------</User Settings>

$to_lex_file = Convert-Path $Args[0]
$comment_only_file_path = $Args[1]
$code_only_file_path = $Args[2]
$int_progress = $Args[3]
$int_progressAll = $Args[4]
$int_progressAll_len = $int_progressAll.ToString("0").Length

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
    Write-Host -NoNewline (
        "`r (" + 
        $int_progress.ToString("0").PadLeft($int_progressAll_len) + 
        "/" +
        $int_progressAll.ToString("0").PadLeft($int_progressAll_len) +
        ") " +
        $percentage.ToString("0").PadLeft(3) +
        '% processing ' +
        $to_lex_file
    )

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
