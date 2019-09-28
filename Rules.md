# Rules

1. エスケープされた改行は 文字として扱わない  
  ***※どのプリプロセスルールよりも最優先されるルール。※***  

```
\
#\
def\
ine D\
DD \
2
\
c\
h\
a\
r\
 \
s\
t\
r\
[\
]\
 \
= \
"ab\\
\cd" ;
/\
/line \
comment
/\
*multi
line
comment*\
/

void main(){
    printf("<start>\n");
    printf("%d%s%d", DDD, str, DDD);
    printf("<end>\n");
    return 0;
}

```
↓ using `gcc -E -P -C` command ↓ ※ `/* */` コメント中に余計な文字が含まれている。( gcc のバグ? )
```
char str[] = "ab\\cd" ;
//line comment
/*multi
i
line
comment*/
void main(){
    printf("<start>\n");
    printf("%d%s%d", 2, str, 2);
    printf("<end>\n");
    return 0;
}

```
↓ using `gcc -E -P` command ↓
```
char str[] = "ab\\cd" ;
void main(){
    printf("<start>\n");
    printf("%d%s%d", 2, str, 2);
    printf("<end>\n");
    return 0;
}

```

1. コード中  

 - エスケープされていない `'` 検出で `' 文字列中` 状態にする  
 - エスケープされていない `"` 検出で `" 文字列中` 状態にする  
 - `//` 検出で検査状態を `// コメント中` 状態にする  
 - `/*` 検出で検査状態を `/* */ コメント中` 状態にする  
 
2. `'` 文字列中
   
 - (改行 or EOF or エスケープされていない `'` ) の検出で `コード中` 状態にする  
    ※ ここで 改行 or EOF が検出されるソースコードは、 gcc のプリプロセスで警告になる。さらに、 gcc のコンパイルでエラーになる。  
    ※ `'` で囲まれた文字列が2文字 以上ある場合は、gcc のプリプロセスは警告なしだけど、gcc のコンパイルで警告になる

3. `"` 文字列中
   
 - (改行 or EOF or エスケープされていない `"` ) の検出で `コード中` 状態にする  
    ※ ここで 改行 or EOF が検出されるソースコードは、 gcc のプリプロセスで警告になる。さらに、 gcc のコンパイルでエラーになる。  

4. `//` コメント中  
 
 - 改行 or EOF 検出で `コード中` 状態にする  
    ※ `/*` or `*/` は 検知 しない  

5. `/* */` コメント中  

 - `*/` 検出で `コード中` 状態にする  
    ※1 `//` は 検知 しない  
    ※2 EOF まで `*/` が登場しない場合は プリプロセスエラー  
