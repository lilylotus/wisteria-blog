---
title: "AI agent LangChain开发教程"
subtitle: "AI agent LangChain"
description: "AI agent LangChain开发教程"
date: 2026-08-11T20:00:00+08:00
lastmod: 2026-08-11T20:00:00+08:00
draft: false

authors: ["yzx"]
tags: ["AI", "LangChain"]
categories: ["AI"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_2681.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# AI Agent LangChain开发

## 简介/序言

常见术语

- AI（Artificial Intelligence）人工智能
- LLM （Large Language Module）大语言模型

AI 演进概括

```
规则驱动(专家系统)  [第一阶段：符号主义/专家系统时代（1950s~1980s）: 早期AI依赖人工编写规则，本质是"if-then"逻辑推理，不具备学习能力]
    ↓ 
数据驱动(机器学习：判别式)  [第二阶段：机器学习时代（1980s~2000s）: 从"人写规则"转向"让机器从数据中自己学规律"]
    ↓ 
深度学习(神经网络自动提特征) [第三阶段：深度学习爆发（2006~2017）: 关键转折点：算力(GPU)+大数据+深度神经网络架构三者同时成熟]
    ↓ 
Transformer架构(能高效处理超大规模数据和长序列) [第四阶段：Transformer架构革命（2017年至今，生成式AI的技术基石）]
    ↓ 
大规模预训练+涌现能力(模型规模突破临界点，能力质变) [第五阶段：生成式AI的爆发期（2022年至今）] 
    ↓ 
生成式AI产品化(RLHF对齐人类偏好，ChatGPT让能力真正触达大众)
    ↓
多模态+Agent化(不再局限于文本对话，开始自主执行复杂任务)
```

**核心分水岭其实就两个**：一是**2017年Transformer架构**，从技术上让"处理超大规模数据、理解长距离上下文"成为可能；二是**2022年ChatGPT**，从产品上让"大模型能力"第一次大规模触达普通用户，这才是"生成式AI"这个说法真正被大众广泛认知和使用的起点。

## 环境准备

### python安装

[python 下载链接](https://www.python.org/downloads/) / [python v3.13.4 windows 版本下载链接](https://www.python.org/ftp/python/3.13.14/python-3.13.14-amd64.exe)

### uv安装

[python极快的包管理工具 uv github 链接](https://github.com/astral-sh/uv)，由 Rust 编写，[uv 官网](https://astral-sh.github.io/uv/)。

uv 安装脚本

```bash
# With pip.
pip install uv

# 版本查看
uv self version
```

uv 初始化项目和项目管理

```bash
# 初始化项目
# uv init <project_name>
uv init example

# 添加依赖
# uv add <package_name>
uv add dotenv

# 同步解析依赖
uv sync
```

uv 管理 python 版本

```bash
# uv install <python_version>
uv install 3.13.4
# uv use <python_version>
uv use 3.13.4
```

## 大模型API

### 阿里百炼大模型

[阿里百炼模型-兼容 OpenAI Chat API官方说明文档链接](https://bailian.console.aliyun.com/cn-beijing/?tab=api#/api/?type=model&url=3016807)

[阿里云百炼-免费模型链接](https://bailian.console.aliyun.com/cn-beijing?spm=5176.29619931.J__Z58Z6CX7MY__Ll8p1ZOR.1.7dd7521cmX1pAh&tab=costing-balance#/costing-balance/free-quota)

### DeepSeek大模型

[DeepSeek API开放平台链接](https://platform.deepseek.com/) 、[DeepSeek API官方文档链接](https://api-docs.deepseek.com/zh-cn/)


## LangChain使用

[LangChain 官方链接](https://www.langchain.com/) 、[LangChain 构建概览文档链接](https://docs.langchain.com/build-overview/) 、[LangChain Python 使用文档链接](https://docs.langchain.com/oss/python/langchain/overview)

### LangChain 安装

常用插件安装

```bash
# dotenv 环境变量使用
uv add dotenv

# jupter notebook
uv add notebook
```

在项目中安装 LangChain 包

```bash
uv add langchain
# Requires Python 3.10+
```

在项目中安装 LangChain 大模型包

```bash
uv add langchain-openai
# Requires Python 3.10+
```

### 初始化模型

[LangChain 常见模型 API KEY](https://docs.langchain.com/oss/python/langchain/quickstart#set-up-api-keys)

.env 环境变量配置文件

```env
# openai 官方 API KEY
OPENAI_API_KEY=your_openai_api_key
OPENAI_BASE_URL=your_openai_url
```

LangChain 初始化模型主要有两种方式：**各厂商专属的模型类**（更常用、更明确），和 **`init_chat_model` 统一入口**（LangChain较新版本提供，方便切换不同厂商模型）。

#### 方式一：厂商专属类（最常用，推荐）

先安装对应厂商集成包

```bash
uv add langchain-anthropic langchain-openai
```

**初始化 Claude（Anthropic）：**

```python
from langchain_anthropic import ChatAnthropic

llm = ChatAnthropic(
    model="claude-sonnet-4-5",
    api_key="your-api-key",   # 建议用环境变量ANTHROPIC_API_KEY，不要硬编码
    temperature=0.7,
    max_tokens=4096,
)

response = llm.invoke("你好，介绍一下你自己")
print(response.content)
```

**初始化 OpenAI：**

```python
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(
    model="gpt-4o",
    api_key="your-api-key",
    temperature=0.7,
)
```

**初始化本地部署的模型（配合你之前问的 Ollama）：**

```python
from langchain_ollama import ChatOllama

llm = ChatOllama(
    model="qwen2.5:14b",
    base_url="http://localhost:11434",
)
```

#### 方式二：`init_chat_model` 统一入口（更灵活，切换模型不用改导入语句）

**这种方式的好处**是如果你的应用需要支持"运行时动态切换模型提供商"（比如根据配置文件决定用哪家的模型），代码结构更统一，不需要为每个厂商写不同的import和实例化逻辑。

使用 `init_chat_model` 使用阿里百炼模型（适配 OpenAI ）

```python
from langchain.chat_models import init_chat_model
from dotenv import load_dotenv
import os

load_dotenv()

llm = init_chat_model(model="qwen3.8-max",
                      model_provider='openai',
                      api_key=os.getenv("OPENAI_API_KEY"),
                      base_url='https://ws-x9csk76pzp72llns.cn-beijing.maas.aliyuncs.com/compatible-mode/v1',
                      temperature=0)

response = llm.invoke("你好，介绍一下你自己")
print(response.model_dump_json(indent=2))
```

执行调用方式2：

```python
from langchain.chat_models import init_chat_model
from dotenv import load_dotenv
import os

# 加载 .env 环境变量配置文件
load_dotenv()

llm = init_chat_model(model = "qwen3.8-max",
                      model_provider = 'openai',
                      api_key = os.getenv("OPENAI_API_KEY"),
                      base_url = os.getenv("OPENAI_BASE_URL"),
                      temperature = 0.7)

messages = [
    {"role": "system", "content": "你是一个乐于助人的助手"},
    {"role": "user", "content": "你是谁？"}
]

response = llm.invoke(messages)
print(response.model_dump_json(indent = 2))
```

几个关键点说明

**1. 为什么是 `model_provider="openai"` 而不是别的**

阿里云百炼提供了 OpenAI 兼容模式的接口地址：`https://dashscope.aliyuncs.com/compatible-mode/v1`，请求/响应格式跟 OpenAI API 完全一致，所以 LangChain 底层可以直接复用 `ChatOpenAI` 这套现成的处理逻辑去对接，不需要单独写百炼专属的适配代码。 [Alibaba Cloud](https://help.aliyun.com/zh/model-studio/use-bailian-in-langchain)

**2. `model` 名称不支持自动推断provider**

像 `qwen-plus` 这种模型名，LangChain 无法自动推断出该用哪个provider，必须显式传 `model_provider="openai"`，否则会直接报错，这跟调用 `gpt-4o`（LangChain能自动识别是openai系）不一样。



### 使用自定义tools

LangChain 的工具调用是**框架统一封装的能力**，跟你用哪个厂商的模型无关——只要模型本身支持function calling（阿里百炼的 `qwen-plus`/`qwen-max` 都支持），绑定tools的写法和调用 OpenAI/Claude 完全一样。给你完整示例。

#### 手写模型调用自定义tools

**完整代码：自定义tools + 百炼模型**

```python
from langchain.chat_models import init_chat_model
from langchain_core.tools import tool
from langchain_core.messages import HumanMessage
from dotenv import load_dotenv
import os

# 加载 .env 环境变量配置文件
load_dotenv()

# ---------- 步骤1: 用 @tool 装饰器定义自定义工具 ----------
@tool
def get_weather(city: str) -> str:
    """查询指定城市的实时天气情况"""
    # 这里是示例，实际应该调用真实的天气API
    weather_data = {
        "北京": "晴，25℃",
        "上海": "多云，28℃",
        "深圳": "雷阵雨，30℃",
    }
    return weather_data.get(city, f"暂无{city}的天气数据")


@tool
def calculate(expression: str) -> str:
    """计算数学表达式，输入合法的Python数学表达式字符串，比如 '3 + 5 * 2'"""
    try:
        result = eval(expression, {"__builtins__": {}}, {})
        return str(result)
    except Exception as e:
        return f"计算出错: {str(e)}"


@tool
def query_server_status(server_ip: str) -> str:
    """查询指定服务器的运行状态"""
    # 实际场景可以接你之前部署的Prometheus查询接口
    return f"服务器 {server_ip} 状态: 运行正常，CPU使用率 45%"


# ---------- 步骤2: 初始化百炼模型 ----------
model = init_chat_model(
    model = "qwen3.8-max",
    model_provider = 'openai',
    api_key = os.getenv("OPENAI_API_KEY"),
    base_url = os.getenv("OPENAI_BASE_URL"),
    temperature=0,   # 工具调用场景建议设为0，减少模型自由发挥导致参数不准确
)

# ---------- 步骤3: 绑定工具到模型 ----------
tools = [get_weather, calculate, query_server_status]
model_with_tools = model.bind_tools(tools)

# ---------- 步骤4: 调用，模型会自主判断要不要调用工具、调用哪个 ----------
response = model_with_tools.invoke("北京今天天气怎么样？")
print(response.tool_calls)
```

**完整的"多轮"工具调用流程（模型决定调用→执行→把结果喂回去→模型总结回答）**

上面只是第一步（模型判断该调用哪个工具），实际要拿到最终自然语言回答，还需要**手动执行工具、把结果传回模型**这一整套流程：

```python
from langchain_core.messages import HumanMessage, ToolMessage

# 工具名到函数的映射，方便根据模型返回的tool_call去执行对应函数
tool_map = {t.name: t for t in tools}

messages = [HumanMessage(content="帮我查一下北京天气，另外算一下 15 * 8 等于多少")]

# 第一次调用：模型判断要调用哪些工具
ai_msg = model_with_tools.invoke(messages)
messages.append(ai_msg)

print("模型决定调用的工具:", ai_msg.tool_calls)

# 执行每一个工具调用，把结果封装成ToolMessage放回消息列表
for tool_call in ai_msg.tool_calls:
    selected_tool = tool_map[tool_call["name"]]
    tool_result = selected_tool.invoke(tool_call["args"])
    messages.append(ToolMessage(content=str(tool_result), tool_call_id=tool_call["id"]))

# 第二次调用：把工具执行结果喂给模型，让它生成最终的自然语言回答
final_response = model_with_tools.invoke(messages)
print(final_response.model_dump_json(indent = 2))
```

> 最后结果：北京当前天气为晴，气温25℃；15 × 8 = 120。



#### LangGraph 的预置Agent

更省心的写法：用 LangGraph 的预置Agent（不用自己手写上面那套循环）

如果工具调用逻辑比较复杂（比如可能需要连续调用多个工具、多轮迭代），推荐直接用 LangGraph 封装好的 `create_react_agent`，不用自己维护消息循环：

```bash
uv add langchain langchain-openai
```

```python
from langgraph.runtime import Runtime
from langchain.agents import create_agent
from langchain.chat_models import init_chat_model
from langchain.agents.middleware import before_model, after_model
from langchain_core.tools import tool
from dotenv import load_dotenv
from typing import Any
import os

# 加载 .env 环境变量文件
load_dotenv()

@tool
def get_weather(city: str) -> str:
    """查询指定城市的实时天气情况"""
    weather_data = {
        "北京": "晴，25℃",
        "上海": "多云，28℃",
        "深圳": "雷阵雨，30℃",
    }
    return weather_data.get(city, f"暂无{city}的天气数据")


@tool
def calculate(expression: str) -> str:
    """计算数学表达式"""
    try:
        return str(eval(expression, {"__builtins__": {}}, {}))
    except Exception as e:
        return f"计算出错: {str(e)}"

@before_model
def log_before(state, runtime: Runtime) -> dict[str, Any] | None:
    print(f"即将调用模型，当前消息数: {len(state['messages'])}")
    return None   # 返回None表示不修改state；也可以返回dict来更新state

@after_model
def log_after(state, runtime: Runtime) -> dict[str, Any] | None:
    print(f"模型调用完成")
    return None

# 初始化百炼模型
# temperature 工具调用场景建议设为0，减少模型自由发挥导致参数不准确
model = init_chat_model(
    model="qwen3.8-max",
    model_provider='openai',
    api_key=os.getenv("OPENAI_API_KEY"),
    base_url=os.getenv("OPENAI_BASE_URL"),
    temperature=0
)

# 用新版 create_agent 创建agent
agent = create_agent(model,
                     tools=[get_weather, calculate],
                     middleware=[log_before, log_after])

# result = agent.invoke({"messages": [("user", "北京天气怎么样？顺便算一下15*8")]})
result = agent.invoke({"messages": [{"role": "user", "content": "北京天气怎么样？顺便算一下15*8"}]})
print(result["messages"][-1].content)
```

这种写法内部已经把"模型判断→执行工具→结果喂回→继续判断→...→最终回答"这整套循环封装好了，能自动处理"需要连续调用多个工具才能回答"的复杂场景，代码量少很多，是目前更推荐的写法（前面你问的AI Agent概念，这就是一个最小可用实现）。



##### 关于 `@tool` 装饰器的几个写法要点

**1. 函数的 docstring 非常关键**——模型是靠这个描述来判断"什么情况下该调用这个工具"的，写清楚、写准确直接影响工具调用的准确率：

```python
@tool
def get_weather(city: str) -> str:
    """查询指定城市的实时天气情况。city参数需要是中文城市名，比如'北京'、'上海'。"""
```

**2. 类型注解也很重要**——`city: str` 这种类型标注会被转换成JSON Schema传给模型，帮助模型生成正确格式的参数。

**3. 复杂参数用 Pydantic 定义**（比如多个参数、参数需要校验）：

```python
from pydantic import BaseModel, Field

class QueryServerInput(BaseModel):
    server_ip: str = Field(description="服务器的IP地址，格式如 10.4.100.123")
    metric: str = Field(description="要查询的指标类型，可选 cpu/memory/disk")

@tool(args_schema=QueryServerInput)
def query_server_metric(server_ip: str, metric: str) -> str:
    """查询指定服务器的某项监控指标"""
    return f"{server_ip} 的 {metric} 使用率: 45%"
```



```python
# pip install -qU langchain "langchain[openai]"
from langchain.agents import create_agent

def get_weather(city: str) -> str:
    """Get weather for a given city."""
    return f"It's always sunny in {city}!"

agent = create_agent(
    model="openai:gpt-5.5",
    tools=[get_weather],
    system_prompt="You are a helpful assistant",
)

result = agent.invoke(
    {"messages": [{"role": "user", "content": "What's the weather in San Francisco?"}]}
)
print(result["messages"][-1].content_blocks)
```

