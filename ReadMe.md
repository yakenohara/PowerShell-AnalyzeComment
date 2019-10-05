Powershell で 1 byte 単位に字句解析する  

You can try `example.ps1 example.c` command after pulling this repository.

# Installation

Place `CommentLexer.ps1` anywhere you like.

# Example

# Functions

 - `LexComment`  
 - `LexLine`  


## Properties

 - constant values

| name               | value |
| :----------------- | ----: |
| TYP_CLEAR          |   0x0 |
| TYP_CODE           |   0x1 |
| TYP_CODE_QUOTE     |   0x3 |
| TYP_CODE_DQUOTE    |   0x5 |
| TYP_COMMENT        |   0x1 |
| TYP_COMMENT_SINGLE |   0x3 |
| TYP_COMMENT_MULTI  |   0x5 |

 - `$progress`  
   - [0]  
   - [1]  

 `$typeFlags`
   - [0]  

|       2       |       1       |          0           |
| :-----------: | :-----------: | :------------------: |
| `"` 内 or not | `'` 内 or not | code 解析状態 or not |

   - [1]  

|         2         |       1        |            0            |
| :---------------: | :------------: | :---------------------: |
| `/* */` 内 or not | `//` 内 or not | comment 解析状態 or not |

## Functions

 - `Stringify`  


# Requirements

Powershell 2.0 or higher
