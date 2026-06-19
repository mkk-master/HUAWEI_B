# 智慧记账 - 大作业升级设计

**日期**: 2026-06-19 | **截止**: 2026-06-20 晚12点 | **选题**: 智慧记账

## 1. 任务分解

### 任务一：Native C++ 财务报表生成器

**目标**：将账单统计计算从 ArkTS 下沉到 C++ 层，通过 NAPI 暴露接口。

**接口**：
```
C++ generateMonthlyReport(budgetFen: number, billsJson: string): string
// 输入：月度预算（分）+ 账单列表 JSON 数组
// 输出：格式化好的多行文本报告
```

**C++ 侧职责**：
- 解析 JSON 账单数组
- 按分类汇总金额、排序
- 计算占比百分比
- 找出单笔金额最高的 15 条
- 拼装文本报告

**文件变更**：
- 新增 `entry/src/main/cpp/bill_report.cpp`
- 新增 `entry/src/main/cpp/napi_init.cpp`
- 新增 `entry/src/main/cpp/CMakeLists.txt`
- 修改 `entry/build-profile.json5` — externalNativeOptions
- 新增 `entry/src/main/ets/utils/NativeReportHelper.ets` — ArkTS 封装
- 修改 `entry/src/main/ets/viewmodel/BillViewModel.ets` — 调用 Native 方法

---

### 任务二：平板分栏布局

**目标**：平板端展示"左边流水列表，右边统计大图"的宽屏看板布局。

**方案**：使用 `SideBarContainer` 组件实现分栏。

**断点逻辑**：
- 宽度 < 600vp → 手机模式（现有 UI 不变）
- 宽度 ≥ 600vp → 平板模式（双栏）

**平板布局**：
- 左侧栏（~40%）：账单列表 + 搜索/筛选 + 月份选择器
- 右侧栏（~60%）：饼图 + 分类统计详情 + 预算进度

**文件变更**：
- 修改 `entry/src/main/ets/pages/Index.ets` — 添加 SideBarContainer
- 修改 `entry/src/main/module.json5` — deviceTypes 增加 "tablet"

---

### 任务三：HapTest 自动化测试

**策略**：选用两个内置测试策略 — `TextPresence` 和 `ComponentPresence`。

**TextPresence 测试用例**：
- 验证首页存在"智慧记账"、"记一笔"、"消费统计"文字
- 验证消费统计页存在"消费统计"标题

**ComponentPresence 测试用例**：
- 验证首页存在账单列表组件
- 验证按钮组件存在

**文件变更**：
- 修改 `entry/src/ohosTest/ets/test/Ability.test.ets` — 添加 HapTest 用例
- 修改 `entry/src/ohosTest/module.json5` — 测试配置

---

## 2. 不涉及的内容（YAGNI）

- 不增加加密存储（超出入度要求）
- 不增加 PC/2in1 适配（作业只要求两种设备形态）
- 不增加新的 UI 页面（复用现有 StatisticsPage 做右侧栏）
- 不修改数据库结构
