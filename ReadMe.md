![Concept image](assets/images/2019-10-05-12-18-14.png)

Detect the following string from source code and convert it to byte array,
and call specified script blck.

 - `//` comment  
 - `/* */` comment  
 - Character string enclosed in `'` or `"`  
 - Other than those above  

You can try `example.ps1 example.c` command after pulling this repository.  
This `example.ps1` script extracts only comments and output to `example_comment.c`.

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
   - `$progress[0]`  
     `System.IO.FileInfo` object of specified file  

   - `$progress[1]`  
      Delimited byte point

 `$typeFlags`
   - `$typeFlags[0]`  

|   2    |   1    |       0       |
| :----: | :----: | :-----------: |
| `"` 内 | `'` 内 | code 解析状態 |

   - `$typeFlags[1]`  

|     2      |    1    |        0         |
| :--------: | :-----: | :--------------: |
| `/* */` 内 | `//` 内 | comment 解析状態 |

## Functions

 - `Stringify`  


# Requirements

Powershell 2.0 or higher
