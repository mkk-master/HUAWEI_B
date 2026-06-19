// entry/src/main/ets/utils/NativeReportHelper.ets
import billreport from 'libbillreport.so';

/**
 * 调用 Native C++ 层生成月度财务报表。
 * @param budgetFen 月度预算（分）
 * @param billsJson 账单列表 JSON 字符串
 * @returns 格式化好的多行文本报告
 * @throws 如果 Native 模块加载失败
 */
export function nativeGenerateMonthlyReport(budgetFen: number, billsJson: string): string {
  return billreport.generateReport(budgetFen, billsJson);
}
