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
  '饮食': '#d36e5f',
  '交通': '#7842d7',
  '购物': '#3567ca',
  '娱乐': '#f9bf41',
  '居住': '#e07e0d',
  '医疗': '#e7639a',
  '教育': '#69bb9c',
  '其他': '#b0a758'
};