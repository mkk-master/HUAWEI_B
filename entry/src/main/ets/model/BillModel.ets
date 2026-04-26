// 文件路径: entry/src/main/ets/model/BillModel.ets
/**
 * 账单数据模型
 */
export class BillModel {
  id: number = 0;
  amount: number = 0; // 金额（分）
  category: CategoryType = CategoryType.FOOD;
  date: string = ''; // 格式: YYYY-MM-DD
  remark: string = '';

  constructor(id: number, amount: number, category: CategoryType, date: string, remark: string) {
    this.id = id;
    this.amount = amount;
    this.category = category;
    this.date = date;
    this.remark = remark;
  }
}

/**
 * 消费分类枚举
 */
export enum CategoryType {
  FOOD = '饮食',
  TRANSPORT = '交通',
  SHOPPING = '购物',
  ENTERTAINMENT = '娱乐',
  HOUSING = '居住',
  MEDICAL = '医疗',
  EDUCATION = '教育',
  OTHER = '其他'
}

/**
 * 月度预算模型
 */
export class BudgetModel {
  month: string = ''; // 格式: YYYY-MM
  totalBudget: number = 0; // 单位：分
}

/**
 * 分类颜色映射（用于饼图）
 */
export const CategoryColors: Record<string, string> = {
  '饮食': '#FF6B6B',
  '交通': '#4ECDC4',
  '购物': '#45B7D1',
  '娱乐': '#96CEB4',
  '居住': '#FFEAA7',
  '医疗': '#DDA0DD',
  '教育': '#98D8C8',
  '其他': '#F7DC6F'
};