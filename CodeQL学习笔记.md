[TOC]

# `CodeQL`学习笔记

## 引言

​		`codeql`是一个语义分析引擎，根据目标项目，通过语法树生成数据库，用类似`sql`的`ql`查询语句对数据库进行查询，基于一定漏洞模式，辅助安全研究人员对开源框架的漏洞进行审计，数据流追踪和污点分析，支持对`c/c++`，`java`，`jvascript`，`python`，`go`等等主流语言的开源项目进行审计。

​		学习过程主要根据`Githab security lab`发布在`github`上的教程。

## 环境配置

### 1.下载安装`vscode`

​		微软官网安装

### 2.下载`codeql`分析程序:

​		https://github.com/github/codeql-cli-binaries/releases/latest/download/codeql.zip

### 3.下载相关库文件

```bash
git clone https://github.com/Semmle/ql
```

### 4.安装好对应的插件

下载最新版的`VScode`，安装`CodeQL`扩展程序：https://marketplace.visualstudio.com/items?itemName=GitHub.vscode-codeql

### 5.将`vscode-codeql-starter`克隆到本地

```bash
git clone --recursive https://github.com/github/vscode-codeql-starter/
```

### 6.下载`codeql-uboot`项目

​		这个是我仓库中的项目。

```bash
git clone https://github.com/Riv4ille/codeql-uboot.git
```

### 7.`vscode`修改插件配置

#### 		1.修改`cli`

​			修改`cli`目录为`codeql`分析程序可执行文件的路径。

#### 		2.创建工作区

​			打开`vscode`，打开`open workspace`，将`vscode-codeql-starter`目录下`vscode-codeql-starter.code-workspace`这个文件添加到`workspace`中。

​			然后通过`Add Folder to workspace`将`codeql-uboot`添加到`workspace`中。

​			然后选择对应的分析好的`uboot`数据库：

```url
https://link.zhihu.com/?target=https%3A//downloads.lgtm.com/snapshots/cpp/uboot/u-boot_u-boot_cpp-srcVersion_d0d07ba86afc8074d79e436b1ba4478fa0f0c1b5-dist_odasa-2019-07-25-linux64.zip
```

​			至此，环境配置的工作已经完成。

## 初识`codeql`

### `step3`:第一次查询

​		`codeql`是一款语义分析引擎，通过`cql`查询语言遵循一定的漏洞模式，辅助安全人员进行代码审计和漏洞挖掘，也可以很好的进行污点分析。

​		入门的第一个例子，是对`uboot`数据库中的`strlen`函数调用进行查询：

```cql
import cpp

from Function f
where f.getName()="strlen"
select f,"a function named strlen"
```

​		查询之后，就可以看到所有定义和声明`strlen`函数的地方。

![image-20210324014725500](C:\Users\wolf\AppData\Roaming\Typora\typora-user-images\image-20210324014725500.png)

​		点击之后就会跳转到相应调用的地方。

​		课程中需要通过`pull request`将修改代码提交到`github`上去。

```bash
git branch
//查看所有分支
git fetch
//获取所有分支
git checkout main
git pull
git checkout -b step-3
git add .
git commit -a -m "First Query"
git push -u origin step-3
```

​		或者在`github`的`desktop`上创建分支提交也完全`ok`。

### `step4`:剖析查询

```CQL
import cpp

from Function f
where f.getName() = "memcpy"
select f, "a function named memcpy"
```

​		本部分参照第一个实例代码完成了对`memcpy`函数定义和声明的查询。

#### Imports

​		`import cpp`导入了一个`c/c++`的查询库，让我们可以使用其中的功能。

#### Classes

​		`from Function f`

​		`Function`表示一个类，是所有函数的集合，这个过程是将`Function`类实例化的过程。

#### predicate

​		`f.getName()`

​		`getName()`就是`predicate`，表示对集合的约束条件。

### `step5`:使用不同的类和谓词

​		这一步，首先讨论了整型变量在网络传输过程中的转换。整型变量在网络传输过程中，总会先转换成字节序的形式，程序一般都使用宏定义对整型进行转换。

​		常见的宏比如：`ntohl`，`ntohll`，`ntohs`。需要完成的任务，是对集合进行约束，找出数据库中定义了类型转换宏的地方。

​		要编写一个更加紧凑的查询，一次性输出对三个类型转换宏的查询，根据提示，可以用逻辑运算符`or`来连接三个宏。

```CQL
import cpp

from Macro mc
where mc.getName()="ntohl" or mc.getName()="ntohs" or mc.getName()="ntohll"
select mc,"a macro of network ordering conversion"
```

​		还可以使用数组和`in`来查询：

```CQL
import cpp

from Macro mc
where mc.getName() in ["ntohl","ntohs","ntohll"]
select mc,"a macro of network ordering conversion"
```

​		或者也可以使用正则表达式，但是由于忘得差不多了，就不写了。

### `step6`：关联两个变量（1）

​		在使用IDA进行静态分析和审计的过程中，有获取指令的对应函数：`print_insn_mnem`，如果提取到的指令是`call`或者`jmp`，我们就可以对动态调用进行回溯。

​		在`codeql`中，如果能够快速定位危险函数的调用，对数据执行流程进行回溯，无疑会极大地方便审计。

​		看文档有些痛苦，我决定直接先从实例入手用起来：

​		https://github.com/github/codeql/tree/main/cpp/ql/examples/snippets

​		教程中提示要定义两个类，对应到这个查询语句中，一个是`FunctionCall`表示函数调用的集合，一个是`Function`表示函数定义和声明的集合。

![image-20210325045114853](C:\Users\wolf\AppData\Roaming\Typora\typora-user-images\image-20210325045114853.png)

​		查询之后，右侧就会显示出所有`memcpy`函数调用的地方。

### `step7`：关联两个变量（2）

​		遇上一个类似，这次是找到宏调用。

```cql
import cpp

from MacroAccess Ma
where
    Ma.getMacro().getName() in ["ntohl","ntohs","ntohll"]

select Ma
```

![image-20210325050847479](C:\Users\wolf\AppData\Roaming\Typora\typora-user-images\image-20210325050847479.png)

### `step8`：宏的顶层表达式（这段很晦涩，意思是展开宏

​		这一段我确实没太理解意思。应该就是获取宏的展开：

```CQL
import cpp

from MacroInvocation MI
where MI.getMacro().getName().regexpMatch("ntoh(s|l|ll)")
select MI.getExpr()
```

### `step9`：写出你自己的类

​		将特定的查询封装成类，提高查询逻辑的可读性，更易重用，更易于完善。

​		`codeql`的思想是将代码数据化，语言设计上有一些面向对象的思想在里面。面向对象编程中，定义在类中的函数被称作成员函数，在`cql`查询语言中，这种被称作特征谓词，但特征谓词表示的是一种逻辑属性，起到对类进行约束的作用，而不像函数一样要实现某种特定功能。

​		要写好个性化的丰富的查询语句，就要对谓词，类和特征谓词的概念掌握清楚。

​		关于谓词，类和特征谓词，这里有一篇文章写得不错：

​		https://www.4hou.com/posts/J7k9

​		教程中这里讲到`exists`关键字的使用，`exists`在查询语句中声明临时变量：

```cql
from Person t, string c
where t.getHairColor() = c
select t
```

```cql
from Person t
where exists(string c | t.getHairColor() = c)
select t
```

​		上面两个语句是等价的，官方推荐使用`exists`关键字来书写类似语句。

```cql
import cpp

class NetworkByteSwap extends Expr{
// 表明NetworkByteSwap是Expr的子类
    NetworkByteSwap(){
// 特征谓词类似于构造函数，但是它表示的是一种逻辑属性，缩小集合范围
        exists(MacroInvocation mi|
            mi.getMacroName() in ["ntohs","ntohl","nothll"] and
            this=mi.getExpr()
// this表示当前类中的元素集合
        )
    }
}

from NetworkByteSwap n
select n
```

## `step10`：数据流和污点跟踪分析

​		我对污点分析其实有一些直观的感受，在我理解来说，污点分析就是对不可信的数据进行标记，追踪污染数据在处理过程中是否会产生漏洞。

​		关于污点分析：https://www.k0rz3n.com/2019/03/01/%E7%AE%80%E5%8D%95%E7%90%86%E8%A7%A3%E6%B1%A1%E7%82%B9%E5%88%86%E6%9E%90%E6%8A%80%E6%9C%AF/#1-%E6%98%BE%E7%A4%BA%E6%B5%81%E5%88%86%E6%9E%90

> ​		摘录一些关键概念：污点分析可以抽象成一个三元组``的形式,其中,source 即污点源,代表直接引入不受信任的数据或者机密数据到系统中;sink即污点汇聚点,代表直接产生安全敏感操作(违反数据完整性)或者泄露隐私数据到外界(违反数据保密性);sanitizer即无害处理,代表通过数据加密或者移除危害操作等手段使数据传播不再对软件系统的信息安全产生危害.污点分析就是分析程序中由污点源引入的数据是否能够不经无害处理,而直接传播到污点汇聚点.如果不能,说明系统是信息流安全的;否则,说明系统产生了隐私数据泄露或危险数据操作等安全问题.
>
> ![image-20210327001954891](C:\Users\wolf\AppData\Roaming\Typora\typora-user-images\image-20210327001954891.png)

​		

## 实战操练：`U-Boot NFS RCE Vulnerabilities (CVE-2019-14192)`

​		在做`CTF`和接触漏洞挖掘的过程中，最直观的感受是：`CTF`难度侧重于漏洞利用技巧的难度和巧妙性；而真实世界的漏洞挖掘难度在于目标系统的复杂性。

​		前面课程实验引导的其实非常好，网络传输过程中，用户可以控制一些输入的整型，网络传输过程中，整型转换通过`ntohs`，`ntohl`，`ntohll`三个类型转换宏实现，可以追溯这三个宏调用的地方。这部分内容可以被标记为污染变量，通过追溯这些变量，查看有没有危险函数以污染变量为参数（即达到污点汇聚点），这样分析可以得到关键数据执行流程。

​		