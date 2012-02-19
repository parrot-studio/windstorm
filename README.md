BF風言語解析器 - Windstorm
===============

Introduction
---------------
BrainF**k（BF）風のソースコード解析と実行をおこなうRubyのGemです。
定義を作成することで、自由にBF風の言語を構築することができます。
いわゆる「ネタ言語用解析器」です。

Ruby Version
---------------
- Ruby1.9.x以上
 - CRuby1.9.2/1.9.3でspecが通ることを確認しています
 - Ruby1.9.xに対応した処理系であれば動くと思われます（JRuby等）
 - Ruby1.8.xに対応する予定はありません（動くかもしれませんが、一切保証しません）

Source
---------------
https://github.com/parrot-studio/windstorm

Installation
---------------
    gem install windstorm

Usage
---------------
### 概要
基本的な実行原理はBFと同じです。
外部から自由に定義を与えることで、自由な解析器を作ることができます。

WindstormはParser/Machine/Executorの3クラスで構成されています。

- Parser   : 与えられた定義を元に、ソースコードを命令の配列に変換する
- Machine  : 与えられた命令の配列を元に、命令を実行して結果を返す
- Executor : ParserとMachineを連携させて一つの処理系を構成する

### 命令
WindstormではBFに存在する8命令を抽象化し、シンボルで定義しています。
（括弧内は対応するBFの命令語）

- :pinc(>) : ポインタをインクリメントする
- :pdec(<) : ポインタをデクリメントする
- :inc (+) : ポインタが指す値をインクリメントする
- :dec (-) : ポインタが指す値をデクリメントする
- :out (.) : ポインタが指す値を出力する
- :inc (,) : 入力から読み込んで、ポインタが指す値を更新する
- :jmp ([) : ポインタが指す値が0ならば、対応する :ret にジャンプする
- :ret (]) : ポインタが指す値が0でなければ、対応する :jmp にジャンプする

また、以下の2命令を追加しています。

- :clip  : ポインタが指す値を専用のclipバッファに保存する
 - 再度呼ばれた場合は、新しい値でclipバッファを上書きする
- :paste : ポインタが指す値をclipバッファの値で上書きする
 - 一度も :clip を呼ばれていない場合、0で上書きする

### 定義

10の命令について、対応する文字列をHash形式で指定します

    table = {
      :pinc => '>',
      :pdec => '<',
      :inc => ['+', 'a'], # 複数指定も可能
      :dec => ['-', 'あ'], # マルチバイトでもOK
      :out => ['.', '出力'] # 一文字でなくてもOK
      # 不要な命令は定義しなくても良い
    }
    exec = Executor.create_from_table(table)

Executorは外部ファイルからの読み込みに対応しています。
その場合は定義をYAML形式（UTF-8）で記述します。

    # table.yml
    :pinc:
    - '>'
    :pdec:
    - '<'
    :inc:
    - '+'
    - 'a'
    :dec:
    - '-'
    - あ
    :out:
    - '.'
    - 出力
    ########
    
    exec = Executor.create_from_file('table.yml')

### ソースコード仕様

- 文字コードはUTF-8で記述してください

- 定義されていない文字列は全て無視します
 - 定義に重複する文字列があった場合、どちらの命令に変換されるかは不定です
 - 解析には正規表現を用いていますので、それに依存した動作になります

- '#'か'//'で始まる行はコメントとして扱われます
 - 空白を含め、一文字でも'#'等の前にあるとコメントになりません
 - よって、文の途中に'#'等があっても、コメントとして解釈しません
 - なので、'#'等を定義に含めても、命令として解釈させることが可能です

### Executorによる解析と実行

    # 定義をYAMLファイルから読み込み
    exec = Executor.create_from_file('table.yml')
    
    # 命令に対応する文字列だけを抽出
    exec.filter('+!+?  出力します  >') #=> ['+', '+', '出力', '>']
    
    # 命令に変換した配列を取得
    exec.build('+!+?  出力します  >') #=> [:inc, :inc, :out, :pinc]

    # 命令を実行
    source = (['+'] * 33 + ['.']).join
    exec.execute(source) #=> '!'
    
    # デバッグモード（後述）で実行
    exec.debug_execute(source)
    
    # ファイルから読み込んで実行
    exec.filter_from_file('hello.bf')
    exec.build_from_file('hello.bf')
    exec.execute_from_file('hello.bf')
    exec.debug_execute_from_file('hello.bf')

Executorが中で使っているParser/Machineの詳細は、
それぞれのspecを参照してください。

### 実行オプション

Executor#executeにはオプションを与えることができます

    exec.execute(source, :debug => true, :size => 10)

- :debug, :loose, :flash : trueを与えると、各モードが有効になります
- :size : 値を格納するバッファのサイズを指定します

格納バッファサイズのデフォルトは100となっていますが、
実行時オプションで :size を指定することにより、
任意のサイズに変更することが可能です。（通常は変更不要）

格納バッファサイズはWindstorm処理系の仮想的な概念で、
本質的にはRuby処理系のArrayクラス仕様に依存します。
後述のlooseモードの説明も参照してください。

#### デバッグモード（:debug）

命令を一つ実行するたびに、デバッグ文を出力します。

    # 出力例
    "step:197 com:out index:43 point:0 buffer:[115, 0] clip:100 result:s"

- step   : 実行ステップ数
- com    : 実行したコマンド
- index  : comに対応する命令配列のindex
- point  : ポインタの値（bufferのindexに対応）
- buffer : 値の格納バッファ（配列）
- clip   : clipバッファに保存されている値
- result : :out で出力した結果

出力先はRuby処理系の$stdoutが指すIOオブジェクトです。
通常は実行しているコンソールになります。

#### strictモードとlooseモード（:loose）

Windstormでソースを実行する目的は、
最終的に「何らかの文字列の出力すること」です。

そのため、デフォルトでは以下の状況になるとエラーになります。

- ポインタが指す値が負になる
- ポインタが負になる
- ポインタがsizeの範囲を超える
- clipバッファに負の値が格納される

これを「strictモード」と呼びます。

ただ、Ruby処理系としてみた場合、
Arrayに格納される値は負でもかまわないし、
ポインタ（Machine#pointが指す整数）が範囲を超えても問題ありません。

そこで、Ruby処理系として都合が悪い状況になるまでエラーにしないという指定が可能です。
これを「looseモード」と呼びます

looseモードでは以下の場合でもエラーとみなしません。

- ポインタが範囲を超えたが、値を操作する前に正常範囲に戻った場合
- ポインタが指す値が負になったが、:out が呼ばれる前に0以上に戻った場合
- clipバッファに負の値が格納された場合

その場でエラーにしないというだけで、想定した処理がおこなわれるかは状況次第です。
特に理由がない限り、strictモードで実行してください。

#### flashモード(:flash)

Executor#executeは出力結果の文字列を返しますが、
本来のBFでは、:out を呼んだ時点で文字を出力します。
BFと同じく、即時出力をおこなうのが「flashモード」です。

通常の実行時にはさほど差がありませんが、
debugモードを有効にしていると、出力が混じるのでお勧めできません。

### WindstormのI/Oについて

このドキュメントで使っている「出力先」という言葉は、
厳密に言うとRuby処理系の_$stdout_が指すIOオブジェクトです。
通常はRubyを実行しているコンソールになります。

同じく、「入力元」はRuby処理系の_$stdin_が指すIOオブジェクトです。
通常はRubyを実行しているコンソールからの入力になります。

これらの入出力を変更する必要はありませんが、
必要であれば、StringIOなどのオブジェクトに差し替えることが可能です。
Machineに対するspecの記述も参考にしてください。

Note
---------------
- windstorm : 暴風 = 上州名物・空っ風

- Windstormを使ってネタプログラム言語を作成するツール、「Youma」もあります
 - https://github.com/parrot-studio/youma
 - ネタ言語のサンプルも含まれています
 - WindstormをWebアプリ等に組み込むのでなければ、Youmaを使ってください

License
---------------
The MIT License

see LICENSE file for detail

Author
---------------
ぱろっと(@parrot_studio / parrot.studio.dev at gmail.com)
