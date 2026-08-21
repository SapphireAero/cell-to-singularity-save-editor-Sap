# 《细胞到奇点》(Cell to Singularity) 存档分析与修改工具箱

一个专为 Steam 版《从细胞到奇点：进化永无止境》（*Cell to Singularity: Evolution Never Ends*）设计的安全存档解析、查看、导出与修改工具。

---

## 目录
- [1. 存档机制与底层原理解析](#1-存档机制与底层原理解析)
- [2. 游戏核心变量映射表](#2-游戏核心变量映射表)
- [3. 快速上手指南](#3-快速上手指南)
  - [方式一：使用一键交互式菜单 (推荐)](#方式一使用一键交互式菜单-推荐)
  - [方式二：使用命令行 (CLI)](#方式二使用命令行-cli)
- [4. 项目结构与源码编译](#4-项目结构与源码编译)
- [5. 常见问题与安全建议](#5-常见问题与安全建议)

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

| 键名 | 描述 |
| :--- | :--- |
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
  [3] 修改熵 (Entropy)
  [4] 修改想法 (Ideas)
  [5] 修改中生代突变剂 (Mutagen / 恐龙化石)
  [6] 修改超越篇星尘/暗物质 (Stardust / Dark Matter)
  [7] 导出完整存档为 JSON 格式
  [8] 创建当前存档的安全备份
  [9] 重新编译 SaveEditor 源码
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

# 3. 将熵修改为 1e12 (一万亿)
SaveEditor.exe set-entropy 1000000000000

# 4. 将想法修改为 1e12
SaveEditor.exe set-ideas 1000000000000

# 5. 将中生代突变剂修改为 50,000
SaveEditor.exe set-mutagen 50000

# 6. 将整个二进制存档导出为人类可读的 JSON 文件
SaveEditor.exe export "my_save.json"

# 7. 手动创建一个时间戳备份
SaveEditor.exe backup
```

---

## 4. 项目结构与源码编译

### 4.1 项目结构
```text
cell-to-singularity-save-tool/
├── src/
│   └── SaveEditor.cs       # 核心 C# 源码（包含解析、修改、导出与备份逻辑）
├── bin/
│   └── SaveEditor.exe      # 编译后可执行文件
├── build.bat               # Windows 自带 csc.exe 一键编译脚本
├── menu.bat                # 交互式控制台菜单脚本
├── .gitignore              # Git 忽略配置
└── README.md               # 项目与原理说明文档
```

### 4.2 自行编译
本项目利用 Windows 自带的 .NET Framework C# 编译器（`csc.exe`），无需安装 Visual Studio：

1. 双击运行 **`build.bat`**。
2. 脚本会自动关联 Steam 游戏安装目录中的 `Assembly-CSharp.dll` 等依赖库，并在 `bin\` 目录生成最新的 `SaveEditor.exe`。

---

## 5. 常见问题与安全建议

1. **修改前必须关闭游戏**：
   游戏在运行时会将数据常驻内存并在退出时自动覆盖写盘。如果在游戏运行时修改，游戏退出时会覆盖你的修改。因此**请在完全退出游戏后再执行修改**。
2. **自动备份机制**：
   本工具在执行任何修改操作前，均会**自动在存档目录生成带有当前时间戳的完整备份文件**（如 `savedGames_backup_YYYYMMDD_HHMMSS.gd`）。
3. **Steam 云存档同步**：
   本工具修改时会同步更新 `savedGames.gd` 和 `savedGames2.gd`。启动游戏后若提示云存档冲突，请选择**“使用本地文件（Local File）”**即可。
