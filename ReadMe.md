Powershell で 1 byte 単位に字句解析する  

$int_typ_flgs[0]
-> code

0 based
|       2       |       1       |          0           |
| :-----------: | :-----------: | :------------------: |
| `"` 内 or not | `'` 内 or not | code 解析状態 or not |

$int_typ_flgs[1]
-> comment

|         2         |       1        |            0            |
| :---------------: | :------------: | :---------------------: |
| `/* */` 内 or not | `//` 内 or not | comment 解析状態 or not |
