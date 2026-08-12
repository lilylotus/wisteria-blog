---
title: "python日常学习记录"
subtitle: "python日常学习"
description: "python学习记录|python学习练习记录"
date: 2026-08-11T20:00:00+08:00
lastmod: 2026-08-11T20:00:00+08:00
draft: false

authors: ["yzx"]
tags: ["python"]
categories: ["python"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_2629.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# python日常学习

## 语法学习

### 格式化字符串

`print(f"格式化字符串") `

`f""` 是 Python 的 **f-string（格式化字符串字面量）**，用来在字符串里直接嵌入变量，不用再用 `+` 拼接或者 `.format()` 方法，是 Python 3.6+ 引入的语法糖，写法简洁很多。

#### 基础用法

```python
name = "张三"
age = 25

# 传统写法1: 字符串拼接
print("我叫" + name + "，今年" + str(age) + "岁")

# 传统写法2: .format()方法
print("我叫{}，今年{}岁".format(name, age))

# f-string写法(推荐，最简洁)
print(f"我叫{name}，今年{age}岁")
```

三种写法输出结果完全一样：`我叫张三，今年25岁`

#### 核心语法：花括号 `{}` 里直接写变量或表达式

```python
x = 10
y = 20

print(f"x+y = {x + y}")             # 支持直接写表达式，不只是变量名
print(f"结果: {x if x > y else y}")  # 甚至支持三元表达式
print(f"函数调用: {len('hello')}")    # 支持函数调用
```

#### 真正发挥作用的场景

```python
@before_model
def log_before(state, runtime):
    print(f"即将调用模型，当前消息数: {len(state['messages'])}")
```

这里的 `{len(state['messages'])}` 才是f-string真正有意义的用法，直接把 `len(state['messages'])` 这个函数调用的结果嵌入到字符串里，不用写成：

```python
print("即将调用模型，当前消息数: " + str(len(state['messages'])))
```

#### 常用的格式化控制 (冒号后面加格式说明符)

```python
price = 19.9999
print(f"价格: {price:.2f}")        # 保留2位小数 -> 价格: 20.00

count = 5
print(f"数量: {count:03d}")        # 补零到3位 -> 数量: 005

ratio = 0.856
print(f"占比: {ratio:.1%}")        # 百分比格式 -> 占比: 85.6%

num = 1234567
print(f"数字: {num:,}")            # 千分位分隔符 -> 数字: 1,234,567
```

总结一句：`f""` 就是"格式化字符串"的标记，花括号里能放变量、表达式、函数调用，Python 运行时会自动把这些替换成实际的值。`print(f"模型调用完成")` 单纯 `print("模型调用完成")` 就够了。

### 字典推导式(dict comprehension)

`tool_map = {t.name: t for t in tools}`

这是 Python 的**字典推导式(dict comprehension)**，作用是把一个列表快速转换成一个字典。拆解一下。

#### 先看等价的传统写法（更容易理解）

```python
tool_map = {}
for t in tools:
    tool_map[t.name] = t
```

这段 `for` 循环和你那一行代码**效果完全一样**——遍历 `tools` 列表里的每一个元素 `t`，把 `t.name`（工具的名字）作为字典的**key**，把 `t` 这个对象本身作为字典的**value**。

#### 字典推导式的语法结构

```python
{key表达式: value表达式  for 变量 in 可迭代对象}
```

对应到你这行代码：

```python
tool_map = {t.name: t for t in tools}
#           ^^^^^^  ^   ^   ^^^^^
#           key    value  循环变量  被遍历的对象

# 示例
dict_list = [{"name": "luck", "age": 18}, {"name": "happy", "age": 20}]
dict_map = {t['name']: t for t in dict_list}
print(dict_list) # [{'name': 'luck', 'age': 18}, {'name': 'happy', 'age': 20}]
print(dict_map)  # {'luck': {'name': 'luck', 'age': 18}, 'happy': {'name': 'happy', 'age': 20}}
```

#### 类似语法的其他变体（顺带了解）

```python
# 列表推导式(最常见)
squares = [x**2 for x in range(5)]
# [0, 1, 4, 9, 16]

# 集合推导式
unique_lens = {len(w) for w in ["apple", "banana", "kiwi"]}
# {5, 6, 4}

# 字典推导式(你问的这种)
name_len = {w: len(w) for w in ["apple", "banana", "kiwi"]}
# {"apple": 5, "banana": 6, "kiwi": 4}

# 还可以加条件过滤(if放在最后)
long_names = {w: len(w) for w in ["apple", "banana", "kiwi"] if len(w) > 4}
# {"apple": 5, "banana": 6}
```

### 字典取值

#### 基础语法

```python
字典变量[key]
```

方括号里放 key，就能取出对应的 value。

#### 对应示例

```python
user_map = {"name": "luck", "age": 18}
print(user_map['name'])   # 输出: luck
```

`user_map` 这个字典里有两组键值对：

```
key: "name"  → value: "luck"
key: "age"   → value: 18
```

`user_map['name']` 就是"去字典里查key为`'name'`对应的value"，查到的结果是 `'luck'`，所以打印出来就是 `luck`。

### 列表索引

`[-1]` 是 Python 列表的**负数索引**语法，表示"从末尾往前数"，是Python的一个内置特性，不是什么特殊技巧。

#### 正数索引 vs 负数索引对照

```python
messages = ["消息1", "消息2", "消息3", "消息4"]

# 正数索引：从0开始，从左往右数
messages[0]   # "消息1"  (第1个)
messages[1]   # "消息2"  (第2个)
messages[3]   # "消息4"  (第4个，也是最后一个)

# 负数索引：从-1开始，从右往左数
messages[-1]  # "消息4"  (倒数第1个，也就是最后一个)
messages[-2]  # "消息3"  (倒数第2个)
messages[-4]  # "消息1"  (倒数第4个，也是第一个)
```

图示对照更直观

```
索引:    0      1      2      3
        ["消息1", "消息2", "消息3", "消息4"]
索引:   -4     -3     -2     -1
```

同一个位置，从左边数是正数索引，从右边数就是负数索引，两套编号指向同一批元素。