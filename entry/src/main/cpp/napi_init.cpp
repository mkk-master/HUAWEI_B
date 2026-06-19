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

        // 有效的账单必须有分类
        if (!item.category.empty()) {
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
