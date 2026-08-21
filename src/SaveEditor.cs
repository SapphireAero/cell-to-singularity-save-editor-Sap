using System;
using System.IO;
using System.Reflection;
using System.Collections.Generic;
using System.Runtime.Serialization.Formatters.Binary;
using BreakInfinity;

namespace CellToSingularitySaveTool {
    class Program {
        // 默认游戏安装目录下的 Managed 依赖路径
        public static string ManagedDir = @"D:\Software\Gaming\Steam\steamapps\common\Cell to Singularity\CellToSingularity_Data\Managed";
        
        static void Main(string[] args) {
            Console.OutputEncoding = System.Text.Encoding.UTF8;

            // 注册程序集动态解析（加载 Unity 与游戏自带的 DLL）
            AppDomain.CurrentDomain.AssemblyResolve += (sender, resolveArgs) => {
                string dllName = resolveArgs.Name.Split(',')[0] + ".dll";
                string path = Path.Combine(ManagedDir, dllName);
                if (File.Exists(path)) return Assembly.LoadFrom(path);
                return null;
            };

            try {
                Run(args);
            } catch (Exception ex) {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("\n[错误] 运行异常: " + ex.Message);
                Console.WriteLine(ex.StackTrace);
                Console.ResetColor();
            }
        }

        static void Run(string[] args) {
            string userProfile = Environment.GetEnvironmentVariable("USERPROFILE");
            string saveDir = Path.Combine(userProfile, @"AppData\LocalLow\Computer Lunch\Cell to Singularity");
            string savePath = Path.Combine(saveDir, "savedGames.gd");
            string save2Path = Path.Combine(saveDir, "savedGames2.gd");

            if (args.Length == 0) {
                PrintHelp();
                return;
            }

            string cmd = args[0].ToLowerInvariant();

            if (cmd == "help" || cmd == "-h" || cmd == "--help") {
                PrintHelp();
                return;
            }

            if (!File.Exists(savePath)) {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine("[错误] 未找到存档文件: " + savePath);
                Console.ResetColor();
                return;
            }

            switch (cmd) {
                case "status":
                case "info":
                    ShowStatus(savePath);
                    break;

                case "export":
                    string exportFile = args.Length > 1 ? args[1] : "save_export.json";
                    ExportToJson(savePath, exportFile);
                    break;

                case "backup":
                    CreateBackup(saveDir, savePath);
                    break;

                case "set-darwin":
                    double darwinVal = 0;
                    if (args.Length < 2 || !double.TryParse(args[1], out darwinVal)) {
                        Console.WriteLine("用法: SaveEditor.exe set-darwin <数量>");
                        return;
                    }
                    ModifyCurrency(saveDir, savePath, save2Path, "bank_c", "stat_currency", darwinVal, "达尔文素 (粉色立方体)");
                    break;

                case "set-entropy":
                    double entropyVal = 0;
                    if (args.Length < 2 || !double.TryParse(args[1], out entropyVal)) {
                        Console.WriteLine("用法: SaveEditor.exe set-entropy <数量>");
                        return;
                    }
                    ModifyCurrency(saveDir, savePath, save2Path, "bank", "stat_entropy", entropyVal, "熵 (Entropy)");
                    break;

                case "set-ideas":
                    double ideasVal = 0;
                    if (args.Length < 2 || !double.TryParse(args[1], out ideasVal)) {
                        Console.WriteLine("用法: SaveEditor.exe set-ideas <数量>");
                        return;
                    }
                    ModifyCurrency(saveDir, savePath, save2Path, "bank_b", "stat_science", ideasVal, "想法 (Ideas)");
                    break;

                case "set-mutagen":
                    double mutaVal = 0;
                    if (args.Length < 2 || !double.TryParse(args[1], out mutaVal)) {
                        Console.WriteLine("用法: SaveEditor.exe set-mutagen <数量>");
                        return;
                    }
                    ModifyCurrency(saveDir, savePath, save2Path, "bank_d", "stat_dino_currency", mutaVal, "突变剂 (Mutagen/恐龙化石)");
                    break;

                case "set-stardust":
                    double starVal = 0;
                    if (args.Length < 2 || !double.TryParse(args[1], out starVal)) {
                        Console.WriteLine("用法: SaveEditor.exe set-stardust <数量>");
                        return;
                    }
                    ModifyCurrency(saveDir, savePath, save2Path, "bank_e", "stat_stardust", starVal, "星尘/暗物质 (Stardust/Dark Matter)");
                    break;

                case "set-var":
                    if (args.Length < 3) {
                        Console.WriteLine("用法: SaveEditor.exe set-var <变量名> <数值>");
                        return;
                    }
                    ModifyCustomVar(saveDir, savePath, save2Path, args[1], args[2]);
                    break;

                default:
                    Console.WriteLine("[未知命令] " + cmd);
                    PrintHelp();
                    break;
            }
        }

        static void PrintHelp() {
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine("==========================================================");
            Console.WriteLine(" 《细胞到奇点》(Cell to Singularity) 存档修改与管理工具");
            Console.WriteLine("==========================================================");
            Console.ResetColor();
            Console.WriteLine("用法: SaveEditor.exe <命令> [参数...]");
            Console.WriteLine();
            Console.WriteLine("可用命令:");
            Console.WriteLine("  status                  查看当前存档内各项货币、等级与统计概况");
            Console.WriteLine("  export [输出路径.json]  将二进制存档解析并导出为可读的 JSON 文本");
            Console.WriteLine("  backup                  为当前存档创建带时间戳的安全副本");
            Console.WriteLine("  set-darwin  <数量>      修改粉色达尔文素 (如: set-darwin 100000)");
            Console.WriteLine("  set-entropy <数量>      修改熵数值 (如: set-entropy 1e12)");
            Console.WriteLine("  set-ideas   <数量>      修改想法数值 (如: set-ideas 1e12)");
            Console.WriteLine("  set-mutagen <数量>      修改中生代山谷突变剂 (如: set-mutagen 50000)");
            Console.WriteLine("  set-stardust <数量>     修改超越篇星尘/暗物质");
            Console.WriteLine("  set-var <变量名> <数值> 直接修改 customVars 中的任意指定字段");
            Console.WriteLine();
        }

        static SaveFile LoadSave(string savePath) {
            using (FileStream fs = File.OpenRead(savePath)) {
                BinaryFormatter bf = new BinaryFormatter();
                return (SaveFile)bf.Deserialize(fs);
            }
        }

        static void WriteSave(string savePath, SaveFile save) {
            using (FileStream fs = File.Create(savePath)) {
                BinaryFormatter bf = new BinaryFormatter();
                bf.Serialize(fs, save);
            }
        }

        static string CreateBackup(string saveDir, string savePath) {
            string timestamp = DateTime.Now.ToString("yyyyMMdd_HHmmss");
            string backupPath = Path.Combine(saveDir, "savedGames_backup_" + timestamp + ".gd");
            File.Copy(savePath, backupPath, true);
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("[备份成功] 存档副本已保存至: " + backupPath);
            Console.ResetColor();
            return backupPath;
        }

        static void ShowStatus(string savePath) {
            SaveFile save = LoadSave(savePath);

            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("\n--- [ 当前玩家资产与货币状态 ] ---");
            Console.ResetColor();
            
            PrintBankVal(save, "bank", "熵 (Entropy)");
            PrintBankVal(save, "bank_b", "想法 (Ideas)");
            PrintBankVal(save, "bank_c", "达尔文素 (Darwinium / 粉色立方体)");
            PrintBankVal(save, "bank_d", "突变剂 (Mutagen / 恐龙化石)");
            PrintBankVal(save, "bank_e", "星尘/暗物质 (Stardust / Dark Matter)");
            PrintBankVal(save, "bank_f", "星座碎片 (Constellation Currency)");

            Console.ForegroundColor = ConsoleColor.Yellow;
            Console.WriteLine("\n--- [ 模拟进度与统计 ] ---");
            Console.ResetColor();
            PrintCustomVar(save, "statTotal", "历史总获得熵");
            PrintCustomVar(save, "totalTimePlayed", "总游戏时长(秒)");
            PrintCustomVar(save, "stat_main_simulation_reset_count", "主模拟重启次数");
            PrintCustomVar(save, "stat_dino_rank", "中生代山谷等级");
            PrintCustomVar(save, "stat_beyond_rank", "超越篇等级");
            Console.WriteLine();
        }

        static void PrintBankVal(SaveFile save, string key, string name) {
            string val = save.customVars.ContainsKey(key) ? save.customVars[key] : "0";
            Console.WriteLine(string.Format("  {0,-36} : {1}", name + " (" + key + ")", val));
        }

        static void PrintCustomVar(SaveFile save, string key, string name) {
            if (save.customVars.ContainsKey(key)) {
                Console.WriteLine(string.Format("  {0,-36} : {1}", name + " (" + key + ")", save.customVars[key]));
            }
        }

        static void ModifyCurrency(string saveDir, string savePath, string save2Path, string bankKey, string statKey, double amount, string displayName) {
            // 1. 自动备份
            CreateBackup(saveDir, savePath);

            // 2. 读取反序列化
            SaveFile save = LoadSave(savePath);

            // 3. 修改钱包余额
            string oldVal = save.customVars.ContainsKey(bankKey) ? save.customVars[bankKey] : "0";
            save.customVars[bankKey] = amount.ToString();

            // 4. 同步统计
            if (!string.IsNullOrEmpty(statKey) && save.metaVars.ContainsKey(statKey)) {
                var item = save.metaVars[statKey];
                item.bigOwned = new BigDouble(amount);
                item.DoBeforeSerialize(save, statKey);
            }

            // 5. 写入主存档并同步校验存档
            WriteSave(savePath, save);
            try {
                File.Copy(savePath, save2Path, true);
            } catch {}

            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine(string.Format("\n[修改成功] {0} 已从 {1} 更新为 {2}！", displayName, oldVal, amount));
            Console.ResetColor();
            Console.WriteLine("主存档 (savedGames.gd) 与校验存档 (savedGames2.gd) 已完成同步。");
        }

        static void ModifyCustomVar(string saveDir, string savePath, string save2Path, string key, string val) {
            CreateBackup(saveDir, savePath);
            SaveFile save = LoadSave(savePath);

            string oldVal = save.customVars.ContainsKey(key) ? save.customVars[key] : "不存在";
            save.customVars[key] = val;

            WriteSave(savePath, save);
            try {
                File.Copy(savePath, save2Path, true);
            } catch {}

            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine(string.Format("\n[修改成功] 变量 [{0}] 已从 {1} 更新为 {2}！", key, oldVal, val));
            Console.ResetColor();
        }

        static void ExportToJson(string savePath, string exportFile) {
            SaveFile save = LoadSave(savePath);

            using (StreamWriter sw = new StreamWriter(exportFile, false, System.Text.Encoding.UTF8)) {
                sw.WriteLine("{");
                sw.WriteLine("  \"customVars\": {");
                int cCount = 0;
                foreach (var kv in save.customVars) {
                    cCount++;
                    string comma = cCount == save.customVars.Count ? "" : ",";
                    sw.WriteLine(string.Format("    \"{0}\": \"{1}\"{2}", Escape(kv.Key), Escape(kv.Value), comma));
                }
                sw.WriteLine("  },");
                
                sw.WriteLine("  \"metaVars\": {");
                int mCount = 0;
                foreach (var kv in save.metaVars) {
                    mCount++;
                    string comma = mCount == save.metaVars.Count ? "" : ",";
                    ItemSaveData item = kv.Value;
                    sw.WriteLine(string.Format("    \"{0}\": {1}{2}", Escape(kv.Key), ItemToJson(item), comma));
                }
                sw.WriteLine("  }");
                sw.WriteLine("}");
            }

            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("[导出成功] 存档数据已导出至 JSON 文件: " + Path.GetFullPath(exportFile));
            Console.ResetColor();
        }

        static string ItemToJson(ItemSaveData item) {
            FieldInfo ownedField = typeof(ItemSaveData).GetField("owned", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
            FieldInfo expField = typeof(ItemSaveData).GetField("ownedExponent", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);
            double owned = (double)ownedField.GetValue(item);
            long exp = (long)expField.GetValue(item);
            string dvars = item.dVars != null ? "[" + string.Join(", ", item.dVars) + "]" : "[]";

            return string.Format("{{\"owned\": {0}, \"ownedExponent\": {1}, \"progress\": {2}, \"dVar1\": {3}, \"dVars\": {4}}}",
                owned, exp, item.progress, item.dVar1, dvars);
        }

        static string Escape(string s) {
            if (s == null) return "";
            return s.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\n", "\\n").Replace("\r", "\\r");
        }
    }
}
