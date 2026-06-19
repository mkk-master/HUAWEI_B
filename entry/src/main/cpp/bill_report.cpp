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

struct CategorySummary {
    std::string category;
    int64_t amount;
};

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
    for (size_t i = 0; i < bills.size(); i++) {
        totalFen += bills[i].amount;
    }

    // 2. 按分类汇总
    std::map<std::string, int64_t> catMap;
    for (size_t i = 0; i < bills.size(); i++) {
        catMap[bills[i].category] += bills[i].amount;
    }

    // 3. 分类汇总转 vector 并排序
    std::vector<CategorySummary> catSummaries;
    for (std::map<std::string, int64_t>::const_iterator it = catMap.begin(); it != catMap.end(); ++it) {
        CategorySummary cs;
        cs.category = it->first;
        cs.amount = it->second;
        catSummaries.push_back(cs);
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
    for (size_t i = 0; i < catSummaries.size(); i++) {
        double pct = totalFen > 0
            ? (static_cast<double>(catSummaries[i].amount) / static_cast<double>(totalFen)) * 100.0
            : 0.0;
        report << "- " << catSummaries[i].category << "：" << fenToYuan(catSummaries[i].amount)
               << "（占当月支出 " << std::fixed << std::setprecision(1) << pct << "%）\n";
    }

    report << "\n单笔金额较高的账单（最多 15 条）：\n";
    if (sortedBills.empty()) {
        report << "- （无）\n";
    } else {
        for (size_t i = 0; i < topCount; i++) {
            const BillItem& bill = sortedBills[i];
            report << "- " << bill.date << "｜" << bill.category << "｜"
                   << fenToYuan(bill.amount) << " 元｜备注："
                   << (bill.remark.empty() ? "无" : bill.remark) << "\n";
        }
    }

    return report.str();
}
