
// 文件路径: entry/src/main/ets/viewmodel/BillViewModel.ets
import { BillModel, BudgetModel, CategoryType } from '../model/BillModel';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { CurrencyUtil } from '../utils/CurrencyUtil';

interface CategorySummary {
  category: string;
  amount: number;
}

export class BillViewModel {
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance();
  public bills: BillModel[] = [];
  public currentMonth: string = ''; // YYYY-MM
  public monthlyBudget: number = 0; // 分
  public monthlyTotal: number = 0; // 分

  constructor() {
    const now = new Date();
    this.currentMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
  }

  async init(): Promise<void> {
    await this.loadBills();
    await this.loadBudget();
  }

  async loadBills(keyword?: string, category?: string): Promise<void> {
    this.bills = await this.dbHelper.queryBills(this.currentMonth, keyword, category);
    this.monthlyTotal = this.bills.reduce((sum, bill) => sum + bill.amount, 0);
  }

  async loadBudget(): Promise<void> {
    this.monthlyBudget = await this.dbHelper.getBudget(this.currentMonth);
  }

  async addBill(amountYuan: string, category: CategoryType, date: string, remark: string): Promise<boolean> {
    const amountFen = CurrencyUtil.yuanToFen(amountYuan);
    if (isNaN(amountFen)) {
      return false;
    }

    const bill = new BillModel(0, amountFen, category, date, remark);
    await this.dbHelper.insertBill(bill);
    await this.loadBills();
    return true;
  }

  async deleteBill(id: number): Promise<void> {
    await this.dbHelper.deleteBill(id);
    await this.loadBills();
  }

  async updateBill(id: number, amountYuan: string, category: CategoryType, date: string, remark: string): Promise<boolean> {
    const amountFen = CurrencyUtil.yuanToFen(amountYuan);
    if (isNaN(amountFen)) {
      return false;
    }

    const bill = new BillModel(id, amountFen, category, date, remark);
    await this.dbHelper.updateBill(bill);
    await this.loadBills();
    return true;
  }

  async setBudget(totalBudgetYuan: string): Promise<boolean> {
    const budgetFen = CurrencyUtil.yuanToFen(totalBudgetYuan);
    if (isNaN(budgetFen)) {
      return false;
    }

    const budget = new BudgetModel();
    budget.month = this.currentMonth;
    budget.totalBudget = budgetFen;
    await this.dbHelper.setBudget(budget);
    this.monthlyBudget = budgetFen;
    return true;
  }

  getRemainingBudget(): number {
    return this.monthlyBudget - this.monthlyTotal;
  }

  getBudgetProgress(): number {
    if (this.monthlyBudget <= 0) return 0;
    return Math.min(this.monthlyTotal / this.monthlyBudget, 1.0);
  }
  // 获取当月各分类汇总（用于饼图）
  getCategorySummary(): Array<CategorySummary> {
    const summaryMap = new Map<string, number>();
    this.bills.forEach(bill => {
      const current = summaryMap.get(bill.category) || 0;
      summaryMap.set(bill.category, current + bill.amount);
    });
    return Array.from(summaryMap.entries()).map((entry): CategorySummary => ({
      category: entry[0],
      amount: entry[1]
    }));
  }
}