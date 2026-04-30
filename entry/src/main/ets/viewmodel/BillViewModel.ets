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
  public currentMonth: string = '';
  public monthlyBudget: number = 0;
  public monthlyTotal: number = 0;

  constructor() {
    const now = new Date();
    this.currentMonth = this.formatMonth(now);
  }

  private formatMonth(date: Date): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    return `${year}-${month}`;
  }

  private parseMonth(month: string): Date {
    const parts = month.split('-');
    if (parts.length !== 2) {
      return new Date();
    }

    const year = Number(parts[0]);
    const monthIndex = Number(parts[1]) - 1;

    if (isNaN(year) || isNaN(monthIndex)) {
      return new Date();
    }

    return new Date(year, monthIndex, 1);
  }

  async init(): Promise<void> {
    await this.loadBills();
    await this.loadBudget();
  }

  async loadBills(keyword?: string, category?: string): Promise<void> {
    try {
      console.info('Loading bills for month:', this.currentMonth, 'keyword:', keyword, 'category:', category);

      this.bills = await this.dbHelper.queryBills(this.currentMonth, keyword, category);

      /*this.monthlyTotal = this.bills.reduce((sum: number, bill: BillModel) => {
        return sum + bill.amount;
      }, 0);*/

      console.info('Loaded bills count:', this.bills.length, 'total:', this.monthlyTotal);
    } catch (error) {
      console.error('Error loading bills:', error);
      this.bills = [];
      this.monthlyTotal = 0;
    }
  }

  async loadBudget(): Promise<void> {
    try {
      this.monthlyBudget = await this.dbHelper.getBudget(this.currentMonth);
      this.monthlyTotal = this.bills.reduce((sum: number, bill: BillModel) => {
        return sum + bill.amount;
      }, 0);
    } catch (error) {
      console.error('Error loading budget:', error);
      this.monthlyBudget = 0;
    }
  }

  async changeMonth(month: string, keyword?: string, category?: string): Promise<void> {
    if (!month || month.length !== 7) {
      console.error('Invalid month:', month);
      return;
    }

    this.currentMonth = month;
    await this.loadBills(keyword, category);
    await this.loadBudget();
  }

  async goPreviousMonth(keyword?: string, category?: string): Promise<void> {
    const date = this.parseMonth(this.currentMonth);
    date.setMonth(date.getMonth() - 1);

    this.currentMonth = this.formatMonth(date);
    await this.loadBills(keyword, category);
    await this.loadBudget();
  }

  async goNextMonth(keyword?: string, category?: string): Promise<void> {
    const date = this.parseMonth(this.currentMonth);
    date.setMonth(date.getMonth() + 1);

    this.currentMonth = this.formatMonth(date);
    await this.loadBills(keyword, category);
    await this.loadBudget();
  }

  async goCurrentMonth(keyword?: string, category?: string): Promise<void> {
    const now = new Date();
    this.currentMonth = this.formatMonth(now);

    await this.loadBills(keyword, category);
    await this.loadBudget();
  }

  async addBill(amountYuan: string, category: CategoryType, date: string, remark: string): Promise<boolean> {
    try {
      const amountFen = CurrencyUtil.yuanToFen(amountYuan);

      if (isNaN(amountFen)) {
        console.error('Invalid amount:', amountYuan);
        return false;
      }

      if (!date || date.trim().length === 0) {
        console.error('Invalid date when adding bill');
        return false;
      }

      const bill = new BillModel(
        0,
        amountFen,
        category,
        date.trim(),
        remark.trim()
      );

      const rowId = await this.dbHelper.insertBill(bill);

      if (rowId < 0) {
        console.error('Insert bill failed');
        return false;
      }

      await this.loadBills();
      return true;
    } catch (error) {
      console.error('Error adding bill:', error);
      return false;
    }
  }

  async deleteBill(id: number): Promise<void> {
    try {
      if (id === undefined || id === null || id < 0) {
        console.error('Invalid bill id when deleting:', id);
        return;
      }

      await this.dbHelper.deleteBill(id);
      await this.loadBills();
    } catch (error) {
      console.error('Error deleting bill:', error);
    }
  }

  async updateBill(id: number, amountYuan: string, category: CategoryType, date: string, remark: string): Promise<boolean> {
    try {
      if (id === undefined || id === null || id < 0) {
        console.error('Invalid bill id when updating:', id);
        return false;
      }

      const amountFen = CurrencyUtil.yuanToFen(amountYuan);

      if (isNaN(amountFen)) {
        console.error('Invalid amount:', amountYuan);
        return false;
      }

      if (!date || date.trim().length === 0) {
        console.error('Invalid date when updating bill');
        return false;
      }

      const bill = new BillModel(
        id,
        amountFen,
        category,
        date.trim(),
        remark.trim()
      );

      const affectedRows = await this.dbHelper.updateBill(bill);

      if (affectedRows !== 1) {
        console.error(`Update bill failed or affected rows is not 1, id=${id}, rows=${affectedRows}`);
        return false;
      }

      await this.loadBills();
      return true;
    } catch (error) {
      console.error('Error updating bill:', error);
      return false;
    }
  }

  async setBudget(totalBudgetYuan: string): Promise<boolean> {
    try {
      const budgetFen = CurrencyUtil.yuanToFen(totalBudgetYuan);

      if (isNaN(budgetFen)) {
        console.error('Invalid budget amount:', totalBudgetYuan);
        return false;
      }

      const budget = new BudgetModel();
      budget.month = this.currentMonth;
      budget.totalBudget = budgetFen;

      await this.dbHelper.setBudget(budget);
      this.monthlyBudget = budgetFen;

      return true;
    } catch (error) {
      console.error('Error setting budget:', error);
      return false;
    }
  }

  getRemainingBudget(): number {
    return this.monthlyBudget - this.monthlyTotal;
  }

  getBudgetProgress(): number {
    if (this.monthlyBudget <= 0) {
      return 0;
    }

    return Math.min(this.monthlyTotal / this.monthlyBudget, 1.0);
  }

  getCategorySummary(): Array<CategorySummary> {
    const summaryMap = new Map<string, number>();

    this.bills.forEach((bill: BillModel) => {
      const current = summaryMap.get(bill.category) || 0;
      summaryMap.set(bill.category, current + bill.amount);
    });

    return Array.from(summaryMap.entries()).map((entry: [string, number]) => {
      return {
        category: entry[0],
        amount: entry[1]
      } as CategorySummary;
    });
  }
}