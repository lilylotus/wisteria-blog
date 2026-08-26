# git常用操作

## git提交本地代码到远程

### 场景一：本地是全新项目，还没有 git 仓库

```bash
# 1. 初始化本地仓库
git init

# 2. 添加所有文件到暂存区
git add .

# 3. 提交
git commit -m "init: 初始化项目"

# 4. 添加远程仓库地址
git remote add origin git@github.com:lilylotus/spring-boot-template.git

# 5. 创建并切换到 3.5.x 分支
git checkout -b 3.5.x

# 6. 推送到远程，并建立跟踪关系
git push -u origin 3.5.x
```

------

### 场景二：本地已有 git 仓库，只是还没关联这个远程

```bash
# 1. 添加远程仓库（如果还没添加过）
git remote add origin git@github.com:lilylotus/spring-boot-template.git

# 或者如果 origin 已经指向别的地址，需要先修改
git remote set-url origin git@github.com:lilylotus/spring-boot-template.git

# 2. 确认当前所在分支/切换到目标分支
git checkout -b 3.5.x   # 如果本地还没有这个分支，基于当前分支新建
# 或
git checkout 3.5.x       # 如果本地已经有这个分支

# 3. 提交本地改动（如果还没提交）
git add .
git commit -m "your commit message"

# 4. 推送到远程 3.5.x 分支
git push -u origin 3.5.x
```

------

### 场景三：远程已经存在 `3.5.x` 分支，需要先拉取再推送

```bash
# 1. 添加远程（如果还没添加）
git remote add origin git@github.com:lilylotus/spring-boot-template.git

# 2. 拉取远程分支信息
git fetch origin

# 3. 基于远程分支创建本地分支并关联
git checkout -b 3.5.x origin/3.5.x

# 4. 如果需要把本地新改动合并进去，正常提交后推送
git add .
git commit -m "your commit message"
git push origin 3.5.x
```

### 补充：查看当前状态确认操作正确

```bash
# 查看当前分支
git branch

# 查看远程仓库配置
git remote -v

# 查看推送前的改动状态
git status
```

### 本地仓库推送到GitHub网页初始化

Git 认为 `master` 和 `3.5.x` 是**两条完全独立起源的提交历史**（没有共同的祖先提交），这是 Git 出于安全考虑设计的默认保护行为，防止误合并两个不相关的仓库历史。

这通常发生在：`3.5.x` 分支是 GitHub 创建仓库时通过网页初始化生成的（比如勾选了自动生成 README），而你本地 `master` 是完全独立开发出来的，两者从一开始就没有共同起点。

既然远程 `3.5.x` 只有一个初始化提交，没有需要保留的东西，不需要 merge，直接强推覆盖更干净（推荐）

```bash
git checkout master
git push origin master:3.5.x --force
```

或者按之前建议，本地重建 `3.5.x` 分支再推：

```bash
git checkout master
git branch -D 3.5.x
git checkout -b 3.5.x
git push origin 3.5.x --force
```

强推后本地和远程历史完全一致，不存在"合并"这个概念了，问题从根源上就没了。

