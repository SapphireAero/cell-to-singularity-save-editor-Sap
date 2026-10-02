# 《细胞到奇点》(Cell to Singularity) 存档分析与修改工具箱

一个专为 Steam 版《从细胞到奇点：进化永无止境》（*Cell to Singularity: Evolution Never Ends*）设计的安全存档解析、查看、导出与修改工具。

> [!WARNING]
> **免责声明**：本项目是**非官方的第三方工具**，与 **Computer Lunch** 及《细胞到奇点》的开发／发行方**没有任何关联**，未获其授权、认可或赞助。游戏名称、商标及相关素材归其各自所有者所有。
>
> 本工具仅供**个人学习与单机存档管理**使用。修改存档**可能违反游戏的用户协议（EULA/ToS）**，并可能导致存档损坏、成就失效或云存档冲突。**请自行承担全部风险**，操作前务必备份存档。
>
> 本项目基于 [hysltway/cell-to-singularity-save-editor](https://github.com/hysltway/cell-to-singularity-save-editor) 修改而来。**原项目未声明开源许可证**，因此本仓库也不附加以自身名义发布的 LICENSE 文件。详见 [6. 免责声明与来源](#6-免责声明与来源)。

---

## 目录
- [1. 存档机制与底层原理解析](#1-存档机制与底层原理解析)
- [2. 游戏核心变量映射表](#2-游戏核心变量映射表)
- [3. 快速上手指南](#3-快速上手指南)
  - [方式一：使用一键交互式菜单 (推荐)](#方式一使用一键交互式菜单-推荐)
  - [方式二：使用命令行 (CLI)](#方式二使用命令行-cli)
- [4. 项目结构与源码编译](#4-项目结构与源码编译)
  - [4.1 项目结构](#41-项目结构)
  - [4.2 自行编译](#42-自行编译)
- [5. 常见问题与安全建议](#5-常见问题与安全建议)
- [6. 免责声明与来源](#6-免责声明与来源)

---

## 1. 存档机制与底层原理解析

### 1.1 存档文件存储位置
游戏的存档保存在 Windows 用户数据目录中：
```text
C:\Users\<你的用户名>\AppData\LocalLow\Computer Lunch\Cell to Singularity\
```
*   `savedGames.gd`：主存档文件（主要读取与写入目标）。
*   `savedGames2.gd`：备用校验存档文件（游戏启动时若主存档损坏则读取此文件）。
*   `savedGamesBackup_1.gd` / `savedGamesDeepBackup.gd`：游戏自动生成的历史备份快照。
*   `steam_autocloud.vdf`：Steam 云存档自动同步配置文件。

### 1.2 序列化格式与为什么普通文本编辑器会乱码
*   游戏采用 Unity C# 原生 **`System.Runtime.Serialization.Formatters.Binary.BinaryFormatter`** 进行二进制对象序列化。
*   文件开头包含 .NET 程序集元数据（如 `Assembly-CSharp`、`SaveFile`、`ItemSaveData` 等），数值部分采用 IEEE 浮点数、大数结构（`BreakInfinity.BigDouble`）和二进制数据流存储。
*   **直接用记事本或普通十六进制编辑器打字修改会破坏字节对齐与校验，导致坏档**。本工具通过引用游戏原生动态链接库，在内存中反序列化为真实的 `SaveFile` C# 对象完成安全修改，再重新打包序列化，确保 100% 格式合法。

---

## 2. 游戏核心变量映射表

游戏通过 `SaveFile` 对象的两个核心字典管理数据：

### 2.1 `customVars` 字典（实时货币与运行时数值）
游戏中的实时货币余额由 `customVars` 中的 `bank_*` 字段维护：

| 变量名 | 中文名称 / 对应游戏资源 | 描述 |
| :--- | :--- | :--- |
| `bank` | **熵 (Entropy)** | 主模拟主货币 |
| `bank_b` | **想法 (Ideas)** | 主模拟科技文明货币 |
| `bank_c` | **达尔文素 (Darwinium)** | **粉色立方体高级代币**（用于开晶洞、加速等） |
| `bank_d` | **突变剂 (Mutagen)** | 中生代山谷（恐龙）货币/化石 |
| `bank_e` | **星尘 / 暗物质** | 超越篇（宇宙）货币 |
| `bank_f` | **星座碎片** | 星座系统货币 |
| `bank_g` / `bank_h` | **限时活动代币** | 各类探索活动专属代币 |

### 2.2 `metaVars` 字典（大数对象与统计字段）
每个项为 `ItemSaveData` 类型（封装 `BreakInfinity.BigDouble`）：

| 键名 | 中文名称 / 描述 |
| :--- | :--- |
| **`stat_doober`** | **罗吉特 (Logits / Doobers)**（探索活动奖励货币，用于罗吉特控制台商店兑换特殊项目） |
| `stat_doobers_unlocked` | 罗吉特控制台商店解锁状态 (1: 已解锁) |
| `stat_currency` | 达尔文素历史累计获得统计 |
| `stat_entropy` | 熵历史累计统计 |
| `stat_science` | 想法历史累计统计 |
| `stat_dino_currency` | 突变剂历史累计统计 |
| `idle_darwin` / `timers[DarwinDrip]` | 立方体合成器（Darwinium Synthesizer）计时与产出 |
| `store_darwin_uprgade_stack_*` | 现实引擎中关于达尔文素容量与速度的升级节点 |

---

## 3. 快速上手指南

### 方式一：使用一键交互式菜单 (推荐)

双击运行根目录下的 **`menu.bat`**：

```text
=================================================================
       《细胞到奇点》(Cell to Singularity) 存档修改与管理工具箱
=================================================================

  [1] 查看当前存档状态（各货币、资源与统计概况）
  [2] 修改粉色达尔文素 (Darwinium)
  [3] 修改罗吉特 (Logits / Doobers)
  [4] 修改熵 (Entropy)
  [5] 修改想法 (Ideas)
  [6] 修改中生代突变剂 (Mutagen / 恐龙化石)
  [7] 修改超越篇星尘/暗物质 (Stardust / Dark Matter)
  [8] 导出完整存档为 JSON 格式
  [9] 创建当前存档的安全备份
  [10] 重新编译 SaveEditor 源码
  [0] 退出
```

输入数字即可一键执行对应操作，无需手动记忆命令。

---

### 方式二：使用命令行 (CLI)

打开命令行进入 `bin\` 目录，直接执行 `SaveEditor.exe`：

```bash
# 1. 查看当前存档的所有货币和统计概览
SaveEditor.exe status

# 2. 将粉色达尔文素设置为 100,000
SaveEditor.exe set-darwin 100000

# 3. 将罗吉特 (Logits) 设置为 100,000
SaveEditor.exe set-logit 100000

# 4. 将熵修改为 1e12 (一万亿)
SaveEditor.exe set-entropy 1000000000000

# 5. 将想法修改为 1e12
SaveEditor.exe set-ideas 1000000000000

# 6. 将中生代突变剂修改为 50,000
SaveEditor.exe set-mutagen 50000

# 7. 将整个二进制存档导出为人类可读的 JSON 文件
SaveEditor.exe export "my_save.json"

# 8. 手动创建一个时间戳备份
SaveEditor.exe backup

# 9. 显示自动定位到的游戏依赖库目录（排查环境问题用）
SaveEditor.exe where
```

---

## 4. 项目结构与源码编译

### 4.1 项目结构
```text
cell-to-singularity-save-tool/
├── src/
│   └── SaveEditor.cs       # 核心 C# 源码（包含解析、修改、导出与备份逻辑）
├── bin/                    # 编译输出目录（未提交，克隆后需自行编译生成）
│   └── SaveEditor.exe      #   编译后生成的可执行文件
├── build.bat               # Windows 自带 csc.exe 一键编译脚本
├── menu.bat                # 交互式控制台菜单脚本
├── .gitattributes          # 换行符策略（强制 .bat 为 CRLF，否则脚本会运行异常）
├── .gitignore              # Git 忽略配置
└── README.md               # 项目与原理说明文档
```

> 本仓库**没有 LICENSE 文件**，这是有意为之——原项目未声明许可证，详见 [6.2 来源与许可](#62-来源与许可)。

### 4.2 自行编译

**环境要求**：Windows + .NET Framework 4.x（Windows 10/11 已内置，无需额外安装）。

本项目利用系统自带的 C# 编译器（`csc.exe`），**无需安装 Visual Studio**。由于需要引用游戏自身的 `Assembly-CSharp.dll` 等程序集，**编译前必须已安装《细胞到奇点》**，并且必须在**已退出游戏**的状态下操作。

1. 运行 **`build.bat`**（双击，或在任意目录下用完整路径调用均可，脚本会自动切到自身所在目录）。
2. 脚本定位游戏的 `CellToSingularity_Data\Managed` 目录，引用其中的依赖库，并在 `bin\` 下生成 `SaveEditor.exe`。

#### 依赖库路径的查找顺序

找不到依赖库时会逐级回退：

| 顺序 | 方式 | 说明 |
| :-- | :-- | :-- |
| 1 | 环境变量 `CTS_MANAGED` | 显式覆盖，优先级最高。如 `set CTS_MANAGED=D:\Games\Steam\steamapps\common\Cell to Singularity\CellToSingularity_Data\Managed` |
| 2 | 自动扫描 | 遍历 `C:`～`K:` 盘上的 6 种常见 Steam 安装布局（`\SteamLibrary`、`\Steam`、`\Program Files (x86)\Steam`、`\Games\Steam` 等） |
| 3 | 交互式输入 | 以上都失败时，脚本会提示你手动粘贴路径 |

第 3 步可接受下列任意一种形式，程序会自动解析到 `Managed` 目录：

```text
游戏根目录      ...\steamapps\common\Cell to Singularity
Data 目录       ...\CellToSingularity_Data
Managed 目录    ...\CellToSingularity_Data\Managed
steamapps 目录  ...\steamapps
Steam 库根目录  ...\SteamLibrary
dll 完整路径    ...\Managed\Assembly-CSharp.dll
```

`SaveEditor.exe` **运行时使用完全相同的规则**定位依赖库，因此不需要任何额外配置。想确认最终解析结果，可执行 `SaveEditor.exe where`。

---

## 5. 常见问题与安全建议

1. **修改前必须关闭游戏**：
   游戏在运行时会将数据常驻内存并在退出时自动覆盖写盘。如果在游戏运行时修改，游戏退出时会覆盖你的修改。因此**请在完全退出游戏后再执行修改**。
2. **自动备份机制**：
   本工具在执行任何修改操作前，均会**自动在存档目录生成带有当前时间戳的完整备份文件**（如 `savedGames_backup_YYYYMMDD_HHMMSS.gd`）。
3. **Steam 云存档同步**：
   本工具修改时会同步更新 `savedGames.gd` 和 `savedGames2.gd`。启动游戏后若提示云存档冲突，请选择**“使用本地文件（Local File）”**即可。
4. **反序列化安全（建议阅读）**：
   本工具通过 `BinaryFormatter` 直接反序列化存档文件。该反序列化器存在已知的安全隐患（构造恶意数据理论上可导致代码执行），微软已将其标记为过时。本工具完全离线运行、只读取你自己机器上的存档，因此正常使用风险很低，但仍建议：**只打开你自己信任的存档文件**，不要用本工具去解析来源不明的 `.gd` 文件。
5. **控制台代码页**：
   `menu.bat` 与 `SaveEditor.exe` 会在启动时把控制台切到 UTF-8 以正确显示中文，并在退出时**还原为进入前的值**，不会把你的 cmd 窗口永久留在 UTF-8 状态。注意：若用窗口右上角 × 直接关闭，或按 Ctrl+C 中断批处理，则来不及还原——此时手动执行一次 `chcp 936` 即可恢复。
6. **Git 换行符（贡献者必读）**：
   仓库内的 `.bat` 文件**必须是 CRLF**。cmd.exe 的 `goto` / `call :label` 在 LF-only 的批处理上会定位错行，导致脚本报出大量语法错误、中文乱码甚至菜单无限刷屏。项目已通过 `.gitattributes` 中的 `*.bat text eol=crlf` 强制约束，**请勿移除该规则**，也请不要用会把换行符改成 LF 的工具直接编辑这些脚本。

---

## 6. 免责声明与来源

### 6.1 免责声明

- 本项目为**非官方的第三方工具**，与 **Computer Lunch** 及《细胞到奇点》的开发、发行方**没有任何关联**，未获得其授权、认可或赞助。
- 游戏名称、商标、美术资源等一切相关权利，归其各自所有者所有。
- 本工具**仅供个人学习与单机存档管理**使用。修改存档**可能违反游戏的用户协议（EULA/ToS）**，并可能导致存档损坏、成就失效或云存档冲突。
- 本工具**不包含也不分发**游戏的任何程序集或资源文件；编译与运行过程中仅引用用户本机已安装的游戏文件，用户需自行合法拥有该游戏。
- 软件按 **“原样”（AS IS）** 提供，不附带任何明示或暗示的担保。**使用本工具所产生的一切后果，由使用者自行承担。**
- 请在操作前务必备份存档，并确保游戏已完全退出。
- 若本项目的内容侵犯了您的权益，请通过 Issue 联系，我们会及时处理。

### 6.2 来源与许可

本项目的**原始代码**来自 [hysltway/cell-to-singularity-save-editor](https://github.com/hysltway/cell-to-singularity-save-editor)，本仓库在此之上修复了若干 Windows 环境下的缺陷（详见下方"本仓库的改动"）。

截至本仓库建立时，**原项目未声明任何开源许可证**（GitHub 仓库信息中 `license` 字段为 `null`，且不存在 LICENSE 文件）。按著作权法，未声明许可的作品默认适用「保留所有权利」，因此：

- 原项目代码的**著作权归原作者 `hysltway` 所有**。本仓库不对其主张任何权利，也不以本仓库名义发放许可证。
- 本仓库**有意不附带 LICENSE 文件**——这不是遗漏。
- 本仓库以 GitHub 允许的 fork 形式存在，保留对上游的引用与署名。
- 本仓库中新增的独立内容（如 `.gitattributes`）以及各项缺陷修复，同样不做单独的授权声明。

**使用前请自行确认授权状态。** 如需使用本项目，建议先查阅原仓库说明，或直接联系原作者取得许可。

如果你是原作者，或认为本仓库的署名与授权处理方式不妥，欢迎通过 Issue 联系，我们会立即调整。

#### 本仓库的改动（相对上游）

| 类别 | 内容 |
| :-- | :-- |
| 🐞 修复 | `menu.bat` 原为 LF 换行，导致 cmd.exe 的 `goto`/`call :label` 定位错行，产生 2000+ 条解析错误与中文乱码 |
| 🐞 修复 | `build.bat` / `SaveEditor.cs` 硬编码游戏依赖库路径，换机器即编译/运行失败 |
| ✨ 新增 | 依赖库路径三级查找：`CTS_MANAGED` 环境变量 → 自动扫描 → 交互式输入 |
| ✨ 新增 | `where` 命令，用于显示解析到的依赖库目录 |
| ✨ 新增 | `.gitattributes`，强制 `*.bat` 为 CRLF，防止换行符问题在克隆/下载后复现 |
| 🔧 优化 | 导出的 JSON 不再写入 UTF-8 BOM |
| 🔧 优化 | `build.bat` 显式指定 `/codepage:65001`，不再依赖编译器的隐式探测 |
| 🔧 优化 | `menu.bat` / `SaveEditor.exe` 退出时还原控制台代码页；`build.bat` 锚定脚本自身目录 |

再次强调：**修改游戏存档有风险，请先备份。**
