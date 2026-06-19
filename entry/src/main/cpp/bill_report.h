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

// 核心函数：根据预算和账单列表，生成格式化文本报告
std::string generateMonthlyReport(int64_t budgetFen, const std::vector<BillItem>& bills);

#endif // BILL_REPORT_H
