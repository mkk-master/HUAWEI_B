# 智慧记账大作业升级 - 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成三个任务：Native C++ 财务报表生成器、平板分栏布局、HapTest 自动化测试，满足《移动应用开发与测试》大作业全部要求。

**Architecture:** 任务一在 C++ 层做账单统计计算，通过 NAPI 暴露给 ArkTS；任务二用 SideBarContainer 实现平板双栏布局；任务三基于 HapTest 框架编写 UI 自动化测试。

**Tech Stack:** HarmonyOS ArkTS, C++ (NAPI + CMake), MindSpore Lite (已有), Hypium/HapTest

---

### 文件清单

| 操作 | 文件 |
|------|------|
| Create | `entry/src/main/cpp/CMakeLists.txt` |
| Create | `entry/src/main/cpp/bill_report.h` |
| Create | `entry/src/main/cpp/bill_report.cpp` |
| Create | `entry/src/main/cpp/napi_init.cpp` |
| Create | `entry/src/main/ets/utils/NativeReportHelper.ets` |
| Modify | `entry/build-profile.json5` |
| Modify | `entry/src/main/ets/viewmodel/BillViewModel.ets` |
| Modify | `entry/src/main/ets/pages/Index.ets` |
| Modify | `entry/src/main/module.json5` |
| Create | `entry/src/ohosTest/ets/test/HapTest.test.ets` |
| Modify | `entry/src/ohosTest/ets/test/List.test.ets` |
| Modify | `entry/src/ohosTest/module.json5` |
| Modify | `entry/oh-package.json5` |

---

### Task 1: 项目基础设施 — 启用 Native 构建

**Files:**
- Create: `entry/src/main/cpp/CMakeLists.txt`
- Modify: `entry/build-profile.json5`

- [ ] **Step 1: 创建 CMakeLists.txt**

```cmake
# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(billReport)

add_library(billreport SHARED napi_init.cpp bill_report.cpp)

# 链接 NAPI 和 HiLog NDK 库
target_link_libraries(billreport PUBLIC
    libace_napi.z.so
    libhilog_ndk.z.so
)
```

- [ ] **Step 2: 修改 entry/build-profile.json5 启用 Native 构建**

在 `buildOption` 中增加 `externalNativeOptions`：

```json5
{
  "apiType": "stageMode",
  "buildOption": {
    "externalNativeOptions": {
      "path": "./src/main/cpp/CMakeLists.txt",
      "arguments": "",
      "cppFlags": ""
    },
    "resOptions": {
      "copyCodeResource": {
        "enable": false
      }
    }
  },
  "buildOptionSet": [
    {
      "name": "release",
      "arkOptions": {
        "obfuscation": {
          "ruleOptions": {
            "enable": false,
            "files": [
              "./obfuscation-rules.txt"
            ]
          }
        }
      }
    },
  ],
  "targets": [
    {
      "name": "default"
    },
    {
      "name": "ohosTest",
    }
  ]
}
```

- [ ] **Step 3: 验证构建配置**

```bash
# 回到项目根目录，检查 hvigor 是否能识别 Native 配置
cd c:/Users/wangk/Desktop/HUAWEI_B/HUAWEI_B
# 如果 DevEco Studio 可用，运行 hvigorw assembleHap
```

---

### Task 2: Native C++ 核心逻辑 — 账单统计引擎

**Files:**
- Create: `entry/src/main/cpp/bill_report.h`
- Create: `entry/src/main/cpp/bill_report.cpp`

- [ ] **Step 1: 创建头文件 bill_report.h**

```cpp
// entry/src/main/cpp/bill_report.h
#ifndef BILL_REPORT_H
#define BILL_REPORT_H

#include <string>
#include <vector>

struct BillItem {
    int64_t amount;      // 金额（分）
    std::string category;
    std::string date;
    std::string remark;
};

struct CategorySummary {
    std::string category;
    int64_t amount;
};

// 核心函数：根据预算和账单列表，生成格式化文本报告
std::string generateMonthlyReport(int64_t budgetFen, const std::vector<BillItem>& bills);

#endif // BILL_REPORT_H
```

- [ ] **Step 2: 实现 bill_report.cpp**

```cpp
// entry/src/main/cpp/bill_report.cpp
#include "bill_report.h"
#include <algorithm>
#include <map>
#include <sstream>
#include <iomanip>
#include <cmath>

// 分转元的格式化字符串
static std::string fenToYuan(int64_t fen) {
    double yuan = static_cast<double>(fen) / 100.0;
    std::ostringstream oss;
    oss << std::fixed << std::setprecision(2) << yuan;
    return oss.str();
}

// 按金额降序排序（用于分类汇总）
static bool compareCategoryAmount(const CategorySummary& a, const CategorySummary& b) {
    return a.amount > b.amount;
}

// 按金额降序排序（用于单笔账单）
static bool compareBillAmount(const BillItem& a, const BillItem& b) {
    return a.amount > b.amount;
}

std::string generateMonthlyReport(int64_t budgetFen, const std::vector<BillItem>& bills) {
    std::ostringstream report;

    // 1. 计算总支出
    int64_t totalFen = 0;
    for (const auto& bill : bills) {
        totalFen += bill.amount;
    }

    // 2. 按分类汇总
    std::map<std::string, int64_t> catMap;
    for (const auto& bill : bills) {
        catMap[bill.category] += bill.amount;
    }

    // 3. 分类汇总转 vector 并排序
    std::vector<CategorySummary> catSummaries;
    for (const auto& pair : catMap) {
        catSummaries.push_back({pair.first, pair.second});
    }
    std::sort(catSummaries.begin(), catSummaries.end(), compareCategoryAmount);

    // 4. 单笔账单按金额排序，取前 15
    std::vector<BillItem> sortedBills = bills;
    std::sort(sortedBills.begin(), sortedBills.end(), compareBillAmount);
    size_t topCount = sortedBills.size() < 15 ? sortedBills.size() : 15;

    // 5. 拼装文本报告
    report << "账单笔数：" << bills.size() << "\n";
    report << "月度预算：" << fenToYuan(budgetFen) << " 元（若为 0 表示未设置预算）\n";
    report << "当月支出合计：" << fenToYuan(totalFen) << " 元\n";

    int64_t remainFen = budgetFen - totalFen;
    report << "预算剩余：" << fenToYuan(remainFen) << " 元（负数表示超支）\n";

    if (budgetFen > 0) {
        double progress = (static_cast<double>(totalFen) / static_cast<double>(budgetFen)) * 100.0;
        report << "预算执行进度：" << std::fixed << std::setprecision(1) << progress << "%\n";
    } else {
        report << "预算执行进度：未设置预算\n";
    }

    report << "\n分类支出（元）：\n";
    for (const auto& cat : catSummaries) {
        double pct = totalFen > 0
            ? (static_cast<double>(cat.amount) / static_cast<double>(totalFen)) * 100.0
            : 0.0;
        report << "- " << cat.category << "：" << fenToYuan(cat.amount)
               << "（占当月支出 " << std::fixed << std::setprecision(1) << pct << "%）\n";
    }

    report << "\n单笔金额较高的账单（最多 15 条）：\n";
    if (sortedBills.empty()) {
        report << "- （无）\n";
    } else {
        for (size_t i = 0; i < topCount; i++) {
            const auto& bill = sortedBills[i];
            report << "- " << bill.date << "｜" << bill.category << "｜"
                   << fenToYuan(bill.amount) << " 元｜备注："
                   << (bill.remark.empty() ? "无" : bill.remark) << "\n";
        }
    }

    return report.str();
}
```

- [ ] **Step 3: 实现 NAPI 桥接层 napi_init.cpp**

```cpp
// entry/src/main/cpp/napi_init.cpp
#include "napi/native_api.h"
#include "hilog/log.h"
#include "bill_report.h"
#include <string>
#include <vector>
#include <cstdlib>

#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200
#define LOG_TAG "BillReportNative"

// 简易 JSON 解析器 — 专门解析账单数组
// 格式: [{"amount":1500,"category":"饮食","date":"2026-06-15","remark":"午餐"},...]
static bool parseBillsJson(const std::string& json, std::vector<BillItem>& outBills) {
    outBills.clear();
    size_t pos = 0;

    // 跳过开头的 [
    while (pos < json.size() && json[pos] != '[') pos++;
    if (pos >= json.size()) return true; // 空数组也视为成功
    pos++; // 跳过 [

    while (pos < json.size()) {
        // 跳过空白
        while (pos < json.size() && (json[pos] == ' ' || json[pos] == '\n' || json[pos] == '\r' || json[pos] == '\t')) pos++;
        if (pos >= json.size()) break;
        if (json[pos] == ']') break;
        if (json[pos] == ',') { pos++; continue; }

        // 期望 {
        if (json[pos] != '{') { pos++; continue; }
        pos++; // 跳过 {

        BillItem item;
        item.amount = 0;

        while (pos < json.size()) {
            while (pos < json.size() && (json[pos] == ' ' || json[pos] == '\n' || json[pos] == '\r' || json[pos] == '\t')) pos++;
            if (pos >= json.size() || json[pos] == '}') break;
            if (json[pos] == ',') { pos++; continue; }

            // 期望 "key":
            if (json[pos] != '"') { pos++; continue; }
            pos++; // 跳过 "
            std::string key;
            while (pos < json.size() && json[pos] != '"') {
                key += json[pos];
                pos++;
            }
            if (pos < json.size()) pos++; // 跳过 "
            while (pos < json.size() && json[pos] != ':') pos++;
            if (pos < json.size()) pos++; // 跳过 :

            while (pos < json.size() && (json[pos] == ' ' || json[pos] == '\n')) pos++;

            // 解析 value
            if (json[pos] == '"') {
                // 字符串值
                pos++; // 跳过 "
                std::string value;
                while (pos < json.size() && json[pos] != '"') {
                    value += json[pos];
                    pos++;
                }
                if (pos < json.size()) pos++; // 跳过 "
                if (key == "category") item.category = value;
                else if (key == "date") item.date = value;
                else if (key == "remark") item.remark = value;
            } else if (json[pos] == '-' || (json[pos] >= '0' && json[pos] <= '9')) {
                // 数字值
                std::string numStr;
                if (json[pos] == '-') { numStr += json[pos]; pos++; }
                while (pos < json.size() && json[pos] >= '0' && json[pos] <= '9') {
                    numStr += json[pos];
                    pos++;
                }
                if (key == "amount") {
                    item.amount = static_cast<int64_t>(std::atoll(numStr.c_str()));
                }
            } else if (json[pos] == '{' || json[pos] == '[') {
                // 嵌套对象或数组 — 跳过
                int depth = 1;
                char open = json[pos];
                char close = (open == '{') ? '}' : ']';
                pos++;
                while (pos < json.size() && depth > 0) {
                    if (json[pos] == open) depth++;
                    if (json[pos] == close) depth--;
                    pos++;
                }
            } else {
                pos++;
            }
        }
        if (pos < json.size()) pos++; // 跳过 }

        // 有效的账单必须有 amount > 0
        if (item.amount > 0 || !item.category.empty()) {
            outBills.push_back(item);
        }
    }

    return true;
}

// NAPI: generateReport(budgetFen: number, billsJson: string): string
static napi_value GenerateReport(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    // 解析参数 1: budgetFen (number)
    int64_t budgetFen = 0;
    if (argc > 0) {
        napi_get_value_int64(env, args[0], &budgetFen);
    }

    // 解析参数 2: billsJson (string)
    std::string billsJson;
    if (argc > 1) {
        size_t strLen = 0;
        napi_get_value_string_utf8(env, args[1], nullptr, 0, &strLen);
        char* buf = new char[strLen + 1];
        napi_get_value_string_utf8(env, args[1], buf, strLen + 1, &strLen);
        billsJson = std::string(buf, strLen);
        delete[] buf;
    }

    // 解析 JSON 并生成报告
    std::vector<BillItem> bills;
    std::string reportText;

    if (!billsJson.empty()) {
        parseBillsJson(billsJson, bills);
    }
    reportText = generateMonthlyReport(budgetFen, bills);

    OH_LOG_INFO(LOG_APP, "BillReport: generated report for %{public}zu bills, budget=%{public}ld",
                bills.size(), static_cast<long>(budgetFen));

    // 返回结果字符串
    napi_value result;
    napi_create_string_utf8(env, reportText.c_str(), reportText.size(), &result);
    return result;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "generateReport", nullptr, GenerateReport, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module billReportModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "billreport",
    .nm_priv = ((void*)0),
    .reserved = { 0 },
};

extern "C" __attribute__((constructor)) void RegisterBillReportModule(void) {
    napi_module_register(&billReportModule);
}
```

- [ ] **Step 4: 验证 C++ 代码语法正确性（阅读检查）**

检查要点：
1. `#include` 路径正确（`napi/native_api.h` 是 HarmonyOS NDK 标准头文件）
2. 简易 JSON 解析器能处理项目中的标准账单 JSON
3. NAPI 函数签名与 HarmonyOS API 9+ 兼容
4. 内存管理正确（`new[]`/`delete[]` 配对）

---

### Task 3: ArkTS 侧封装 — 调用 Native 报表引擎

**Files:**
- Create: `entry/src/main/ets/utils/NativeReportHelper.ets`
- Modify: `entry/src/main/ets/viewmodel/BillViewModel.ets`

- [ ] **Step 1: 创建 NativeReportHelper.ets**

```typescript
// entry/src/main/ets/utils/NativeReportHelper.ets
import billreport from 'libbillreport.so';

/**
 * 调用 Native C++ 层生成月度财务报表。
 * @throws 如果 Native 模块加载失败
 */
export function nativeGenerateMonthlyReport(budgetFen: number, billsJson: string): string {
  return billreport.generateReport(budgetFen, billsJson);
}
```

- [ ] **Step 2: 修改 BillViewModel.buildMonthlyInsightDataText — 优先走 Native，失败回退 ArkTS**

修改 `entry/src/main/ets/viewmodel/BillViewModel.ets` 中的 `buildMonthlyInsightDataText` 方法。当前方法约在 348-409 行。

将现有逻辑重命名为 `buildMonthlyInsightDataTextFallback`，新增方法优先调用 Native：

在文件顶部增加 import：
```typescript
import { nativeGenerateMonthlyReport } from '../utils/NativeReportHelper';
```

修改 `buildMonthlyInsightDataText` 方法（替换第 349-409 行）：

```typescript
  /**
   * 生成某月全量账单的纯文本摘要，供云端模型做消费分析（不受首页列表筛选影响）。
   *
   * 优先使用 Native C++ 层计算，失败时自动回退到 ArkTS 纯逻辑。
   */
  async buildMonthlyInsightDataText(month: string): Promise<string> {
    if (!month || month.length !== 7) {
      return '月份参数无效。';
    }

    const budgetFen = await this.dbHelper.getBudget(month);
    const bills = await this.dbHelper.queryBills(month);

    // 准备 C++ 侧需要的 JSON 字符串
    const billsJson = JSON.stringify(bills.map((b: BillModel) => ({
      amount: b.amount,
      category: b.category,
      date: b.date,
      remark: b.remark
    })));

    // 优先走 Native C++ 报表引擎
    try {
      const nativeResult: string = nativeGenerateMonthlyReport(budgetFen, billsJson);
      if (nativeResult && nativeResult.length > 0) {
        // 前置月份信息（Native 报告不含月份头）
        return `月份：${month}\n${nativeResult}`;
      }
    } catch (e) {
      console.error('Native 报表生成失败，回退到 ArkTS 逻辑: ' + JSON.stringify(e));
    }

    // 回退：使用原有 ArkTS 纯逻辑
    return this.buildMonthlyInsightDataTextFallback(month, bills, budgetFen);
  }

  /**
   * ArkTS 侧兜底实现（保留原有逻辑，Native 加载失败时使用）。
   */
  private async buildMonthlyInsightDataTextFallback(
    month: string, bills: BillModel[], budgetFen: number
  ): Promise<string> {
    const totalFen = bills.reduce((sum: number, bill: BillModel) => {
      return sum + bill.amount;
    }, 0);

    const byCat = new Map<string, number>();
    bills.forEach((bill: BillModel) => {
      const cur = byCat.get(bill.category) || 0;
      byCat.set(bill.category, cur + bill.amount);
    });

    const sortedCats = Array.from(byCat.entries()).sort((a: [string, number], b: [string, number]) => {
      return b[1] - a[1];
    });

    const lines: string[] = [];
    lines.push(`月份：${month}`);
    lines.push(`账单笔数：${bills.length}`);
    lines.push(`月度预算：${CurrencyUtil.fenToYuan(budgetFen)} 元（若为 0 表示未设置预算）`);
    lines.push(`当月支出合计：${CurrencyUtil.fenToYuan(totalFen)} 元`);
    const remainFen = budgetFen - totalFen;
    lines.push(`预算剩余：${CurrencyUtil.fenToYuan(remainFen)} 元（负数表示超支）`);
    if (budgetFen > 0) {
      lines.push(`预算执行进度：${((totalFen / budgetFen) * 100).toFixed(1)}%`);
    } else {
      lines.push('预算执行进度：未设置预算');
    }

    lines.push('');
    lines.push('分类支出（元）：');
    sortedCats.forEach((pair: [string, number]) => {
      const cat = pair[0];
      const fen = pair[1];
      const pct = totalFen > 0 ? ((fen / totalFen) * 100).toFixed(1) : '0';
      lines.push(`- ${cat}：${CurrencyUtil.fenToYuan(fen)}（占当月支出 ${pct}%）`);
    });

    const sortedBills = [...bills].sort((a: BillModel, b: BillModel) => {
      return b.amount - a.amount;
    }).slice(0, 15);

    lines.push('');
    lines.push('单笔金额较高的账单（最多 15 条）：');
    if (sortedBills.length === 0) {
      lines.push('- （无）');
    } else {
      sortedBills.forEach((bill: BillModel) => {
        lines.push(
          `- ${bill.date}｜${bill.category}｜${CurrencyUtil.fenToYuan(bill.amount)} 元｜备注：${bill.remark || '无'}`
        );
      });
    }

    return lines.join('\n');
  }
```

- [ ] **Step 3: 确认 import 完整**

确保 `BillViewModel.ets` 文件顶部已 import `CurrencyUtil`（已有）和新增的 `nativeGenerateMonthlyReport`。

---

### Task 4: 平板分栏布局

**Files:**
- Modify: `entry/src/main/ets/pages/Index.ets`
- Modify: `entry/src/main/module.json5`

- [ ] **Step 1: 修改 module.json5 — 添加 tablet 设备类型**

修改 `entry/src/main/module.json5`，在 `deviceTypes` 数组中增加 `"tablet"`：

```json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": [
      "default",
      "phone",
      "tablet",
      "2in1"
    ],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "$profile:main_pages",
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "description": "$string:EntryAbility_desc",
        "icon": "$media:layered_image",
        "label": "$string:EntryAbility_label",
        "startWindowIcon": "$media:startIcon",
        "startWindowBackground": "$color:start_window_background",
        "exported": true,
        "skills": [
          {
            "entities": [
              "entity.system.home"
            ],
            "actions": [
              "ohos.want.action.home"
            ]
          }
        ]
      }
    ],
    "requestPermissions": [
      { "name": "ohos.permission.INTERNET" },
    ],
    "extensionAbilities": [
      {
        "name": "EntryBackupAbility",
        "srcEntry": "./ets/entrybackupability/EntryBackupAbility.ets",
        "type": "backup",
        "exported": false,
        "metadata": [
          {
            "name": "ohos.extension.backup",
            "resource": "$profile:backup_config"
          }
        ],
      }
    ]
  },
}
```

- [ ] **Step 2: 重构 Index.ets — 包一层 SideBarContainer 实现平板双栏**

核心思路：通过 `SideBarContainer` + 屏幕宽度断点实现响应式布局。
- 宽度 < 600vp：手机模式，SideBarContainer 隐藏侧栏，行为与原来完全一致
- 宽度 ≥ 600vp：平板模式，左侧显示账单列表，右侧显示统计图表

`Index.ets` 需要进行较大的结构调整。保留现有所有 `@Builder` 方法，将 `build()` 方法改为使用 `SideBarContainer`。

在 Index 组件中添加状态变量：

```typescript
@State sideBarWidth: number = 280;
@StorageLink('currentBreakpoint') currentBreakpoint: string = 'sm';
@State showSideBar: boolean = false;  // 由 build 中计算
```

修改 `build()` 方法：

```typescript
build() {
  // 判断是否平板模式（宽度 ≥ 600vp 时启用侧栏）
  if (this.currentBreakpoint === 'md' || this.currentBreakpoint === 'lg') {
    this.showSideBar = true;
  } else {
    this.showSideBar = false;
  }

  SideBarContainer(this.showSideBar ? SideBarContainerType.Embed : SideBarContainerType.Overlay) {
    // 左侧栏：账单列表 + 搜索
    Column() {
      this.buildHeader();
      this.buildMonthSelector();
      this.buildBudgetCard();
      this.buildSearchBar();
      this.buildActionButtons();

      if (this.viewModel.bills.length === 0) {
        Column() {
          Text('当前月份暂无账单')
            .fontSize(16)
            .fontColor('#999999')
            .margin({ top: 40 })
          Text('可以切换月份查看其他账单')
            .fontSize(12)
            .fontColor('#BBBBBB')
            .margin({ top: 8 })
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor('#F5F5F5')
      } else {
        List() {
          ForEach(this.viewModel.bills, (bill: BillModel) => {
            ListItem() {
              this.buildBillItem(bill)
            }
            .swipeAction({
              end: this.buildSwipeActions(bill)
            })
          }, (bill: BillModel) => {
            return bill.id.toString();
          })
        }
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')
      }
    }
    .width(this.showSideBar ? '100%' : '100%')
    .height('100%')
    .backgroundColor('#FFFFFF')

    // 右侧内容区（仅平板模式可见）
    if (this.showSideBar) {
      Column() {
        // 右侧统计面板
        Text('消费统计')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ top: 16, bottom: 12 })

        Text(`${this.viewModel.currentMonth} 总消费`)
          .fontSize(14)
          .fontColor('#666666')

        Text(`¥${CurrencyUtil.fenToYuan(this.viewModel.monthlyTotal)}`)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#D32F2F')
          .margin({ top: 4, bottom: 16 })

        // 预算进度
        Column() {
          Row() {
            Text(`${this.viewModel.currentMonth} 剩余`)
              .fontSize(14)
              .fontColor('#666666')
            Text(`${CurrencyUtil.fenToYuan(this.viewModel.getRemainingBudget())} 元`)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.viewModel.getRemainingBudget() >= 0 ? '#2E7D32' : '#D32F2F')
              .margin({ left: 8 })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)

          Progress({
            value: this.viewModel.getBudgetProgress() * 100,
            total: 100,
            type: ProgressType.Linear
          })
            .width('100%')
            .height(8)
            .style({ strokeWidth: 8, strokeRadius: 4 })
            .color(this.viewModel.getRemainingBudget() >= 0 ? '#4CAF50' : '#F44336')
            .margin({ top: 8 })

          Row() {
            Text(`预算 ${CurrencyUtil.fenToYuan(this.viewModel.monthlyBudget)}`)
              .fontSize(12)
              .fontColor('#999999')
            Text(`已花 ${CurrencyUtil.fenToYuan(this.viewModel.monthlyTotal)}`)
              .fontSize(12)
              .fontColor('#999999')
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ top: 4 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .shadow({ radius: 8, color: '#10000000', offsetX: 0, offsetY: 2 })
        .margin({ bottom: 16 })

        // 分类统计列表
        if (this.viewModel.getCategorySummary().length > 0) {
          List() {
            ForEach(this.viewModel.getCategorySummary(), (item: CategorySummaryItem) => {
              ListItem() {
                Row() {
                  Circle({ width: 12, height: 12 })
                    .fill(CategoryColors[item.category] || '#CCCCCC')
                  Text(item.category)
                    .fontSize(15)
                    .margin({ left: 8 })
                    .layoutWeight(1)
                  Text(`¥${CurrencyUtil.fenToYuan(item.amount)}`)
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                  Text(this.viewModel.monthlyTotal > 0
                    ? `${((item.amount / this.viewModel.monthlyTotal) * 100).toFixed(1)}%`
                    : '0.0%')
                    .fontSize(13)
                    .fontColor('#999999')
                    .margin({ left: 8 })
                }
                .width('100%')
                .padding(10)
                .backgroundColor('#FFFFFF')
                .borderRadius(8)
                .margin({ top: 4, bottom: 4 })
              }
            })
          }
          .layoutWeight(1)
          .width('100%')
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
      .padding({ left: 16, right: 16 })
    }
  }
  .sideBarWidth(this.showSideBar ? 320 : 0)
  .showSideBar(this.showSideBar)
  .autoHide(true)
  .minSideBarWidth(280)
  .maxSideBarWidth(480)
  .width('100%')
  .height('100%')
}
```

- [ ] **Step 3: 确保 Index.ets 导入 CategoryColors**

在 `Index.ets` 顶部 import 增加：
```typescript
import { BillModel, CategoryType, CategoryColors } from '../model/BillModel';
```

检查现有 import：目前第 5 行已经 import 了 `CategoryType` 和 `BillModel`，需要增加 `CategoryColors`。

---

### Task 5: HapTest 自动化测试

**Files:**
- Modify: `entry/oh-package.json5` — 加 HapTest 依赖（如果需要）
- Create: `entry/src/ohosTest/ets/test/SmartAccount.test.ets`
- Modify: `entry/src/ohosTest/ets/test/List.test.ets`
- Modify: `entry/src/ohosTest/module.json5`

- [ ] **Step 1: 了解 HapTest 依赖**

根据作业要求，HapTest 从 https://gitee.com/sandlake/haptest 获取。在 HarmonyOS ohpm 中通常通过以下方式添加：

```bash
ohpm install @ohos/haptest
```

或在 `entry/oh-package.json5` 的 devDependencies 中添加：
```json5
"@ohos/haptest": "^1.0.0"
```

**注意**：如果 ohpm registry 中没有 `@ohos/haptest`，则直接从 gitee 下载源码引入。先尝试 ohpm 方式。

- [ ] **Step 2: 创建 HapTest 测试文件 SmartAccount.test.ets**

```typescript
// entry/src/ohosTest/ets/test/SmartAccount.test.ets
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos/haptest';

export default function smartAccountTest() {
  describe('SmartAccount_HapTest', () => {

    let driver: Driver | null = null;

    beforeAll(async () => {
      // 初始化 HapTest 驱动
      driver = Driver.create();
      await driver.start();
    });

    afterAll(async () => {
      if (driver !== null) {
        await driver.quit();
      }
    });

    /**
     * 测试策略 1: TextPresence
     * 验证应用关键页面中存在预期的文字内容
     */
    it('TextPresence_首页关键文字存在', 0, async () => {
      // 等待首页加载
      await driver!.assertComponentExist(ON.text('智慧记账'), 5000);
      // 验证关键文字
      await driver!.assertComponentExist(ON.text('记一笔'), 3000);
      await driver!.assertComponentExist(ON.text('消费统计'), 3000);
      await driver!.assertComponentExist(ON.text('上月'), 2000);
      await driver!.assertComponentExist(ON.text('下月'), 2000);
    });

    it('TextPresence_预算卡片显示', 0, async () => {
      // 验证预算相关文字（剩余、预算、已花这三个关键字必然存在）
      await driver!.assertComponentExist(ON.text('剩余'), 3000);
    });

    /**
     * 测试策略 2: ComponentPresence
     * 验证应用关键页面中存在预期的 UI 组件
     */
    it('ComponentPresence_首页组件存在', 0, async () => {
      // 验证按钮组件
      await driver!.assertComponentExist(ON.type('Button'), 3000);
      // 验证文本输入框存在（搜索栏）
      await driver!.assertComponentExist(ON.type('TextInput'), 3000);
      // 验证 Select 组件存在（分类筛选下拉）
      await driver!.assertComponentExist(ON.type('Select'), 3000);
    });

    it('ComponentPresence_按钮可点击_跳转记一笔页面', 0, async () => {
      // 点击 "记一笔" 按钮
      const addBtn = await driver!.findComponent(ON.text('记一笔'));
      expect(addBtn).assertNotNull();
      await driver!.clickComponent(addBtn!);
      // 等待页面跳转完成
      await driver!.assertComponentExist(ON.text('保存'), 5000);
      await driver!.assertComponentExist(ON.text('取消'), 3000);
      // 点击取消返回首页
      const cancelBtn = await driver!.findComponent(ON.text('取消'));
      await driver!.clickComponent(cancelBtn!);
    });

  });
}
```

- [ ] **Step 3: 修改 List.test.ets — 引入新测试套件**

```typescript
// entry/src/ohosTest/ets/test/List.test.ets
import abilityTest from './Ability.test';
import smartAccountTest from './SmartAccount.test';

export default function testsuite() {
  abilityTest();
  smartAccountTest();
}
```

- [ ] **Step 4: 修改 ohosTest/module.json5 — 确保设备类型和权限**

```json5
{
  "module": {
    "name": "entry_test",
    "type": "feature",
    "deviceTypes": [
      "phone",
      "tablet"
    ],
    "deliveryWithInstall": true,
    "installationFree": false
  }
}
```

- [ ] **Step 5: 提交 HapTest 测试文件**

```bash
git add entry/src/ohosTest/
git commit -m "test: add HapTest UI automation tests (TextPresence + ComponentPresence)"
```

---

### Task 6: 最终验证与收尾

- [ ] **Step 1: 确认所有变更文件列表**

```bash
git status
git diff --stat
```

预期变更文件：
- 新增 4 个 Native 相关文件
- 新增 1 个 ArkTS 封装文件
- 新增 1 个测试文件
- 修改 6 个配置文件/页面文件

- [ ] **Step 2: 提交所有变更**

```bash
git add entry/src/main/cpp/ entry/build-profile.json5
git add entry/src/main/ets/utils/NativeReportHelper.ets
git add entry/src/main/ets/viewmodel/BillViewModel.ets
git add entry/src/main/ets/pages/Index.ets
git add entry/src/main/module.json5
git add entry/src/ohosTest/
git commit -m "feat: complete final assignment upgrade

- Task 1: Native C++ bill report engine via NAPI
- Task 2: Tablet responsive layout with SideBarContainer
- Task 3: HapTest automation tests (TextPresence + ComponentPresence)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## 验证清单

| # | 验证项 | 方式 |
|---|--------|------|
| 1 | Native 模块能编译 | DevEco Studio Build > Build Hap(s) |
| 2 | Native 报表输出与 ArkTS 版本一致 | 对比 `generateMonthlyReport` 和 `buildMonthlyInsightDataTextFallback` 输出 |
| 3 | 手机模式 UI 不变 | 模拟器 phone 尺寸 | 运行应用 |
| 4 | 平板模式显示双栏 | 模拟器 tablet 尺寸 | 运行应用 |
| 5 | HapTest 通过 | 运行 ohosTest target |

---

## 注意事项

1. **Native 模块加载**：在 DevEco Studio 预览器中可能无法加载 `.so` 库，这是正常的。代码中有 try-catch 回退逻辑，真机/模拟器上可以正常使用 Native 路径。
2. **HapTest API**：以上 HapTest 代码基于其公开文档的典型 API 模式。如果 ohpm 无法直接安装 `@ohos/haptest`，需要从 gitee 下载后手动引入。具体 API 可能因版本而异，届时微调。
3. **SideBarContainer**：需要 HarmonyOS API 9+，当前项目 targetSdkVersion 为 6.0.2(22)，完全兼容。
