// 文件路径: entry/src/main/ets/viewmodel/BillViewModel.ets
import { BillModel, BudgetModel, CategoryType } from '../model/BillModel';
import { DatabaseHelper } from '../database/DatabaseHelper';
import { CurrencyUtil } from '../utils/CurrencyUtil';
import { nativeGenerateMonthlyReport } from '../utils/NativeReportHelper';

interface CategorySummary {
  category: string;
  amount: number;
}

interface BillJsonItem {
  amount: number;
  category: string;
  date: string;
  remark: string;
}

export class BillViewModel {
  private dbHelper: DatabaseHelper = DatabaseHelper.getInstance();

  // 当前页面列表显示的账单，可以被搜索关键字、类型筛选影响
  public bills: BillModel[] = [];

  // 当前查看的月份，例如 2026-04
  public currentMonth: string = '';

  // 当前月份预算
  public monthlyBudget: number = 0;

  // 当前月份全部账单总支出
  // 注意：这个值不应该受分类筛选影响
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

  /**
   * 加载账单列表
   *
   * 说明：
   * 这里的 bills 是首页列表显示的数据，
   * 可以受搜索关键字 keyword 和分类 category 影响。
   *
   * 但是预算条不应该使用这里的 bills 计算，
   * 因为 bills 可能只是某一类账单。
   */
  async loadBills(keyword?: string, category?: string): Promise<void> {
    try {
      console.info('Loading bills for month:', this.currentMonth, 'keyword:', keyword, 'category:', category);

      this.bills = await this.dbHelper.queryBills(this.currentMonth, keyword, category);

      console.info('Loaded list bills count:', this.bills.length);
    } catch (error) {
      console.error('Error loading bills:', error);
      this.bills = [];
    }
  }

  /**
   * 加载预算条数据
   *
   * 关键修改：
   * monthlyTotal 不再根据 this.bills 计算。
   * 因为 this.bills 可能是筛选后的列表。
   *
   * 这里重新查询当前月份全部账单：
   * this.dbHelper.queryBills(this.currentMonth)
   *
   * 不传 keyword，也不传 category，
   * 所以预算条永远统计当前月份所有账单。
   */
  async loadBudget(): Promise<void> {
    try {
      this.monthlyBudget = await this.dbHelper.getBudget(this.currentMonth);

      const allMonthBills = await this.dbHelper.queryBills(this.currentMonth);

      this.monthlyTotal = allMonthBills.reduce((sum: number, bill: BillModel) => {
        return sum + bill.amount;
      }, 0);

      console.info(
        `Budget loaded: month=${this.currentMonth}, budget=${this.monthlyBudget}, total=${this.monthlyTotal}`
      );
    } catch (error) {
      console.error('Error loading budget:', error);
      this.monthlyBudget = 0;
      this.monthlyTotal = 0;
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
      await this.loadBudget();

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
      await this.loadBudget();
    } catch (error) {
      console.error('Error deleting bill:', error);
    }
  }

  async updateBill(
    id: number,
    amountYuan: string,
    category: CategoryType,
    date: string,
    remark: string
  ): Promise<boolean> {
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
      await this.loadBudget();

      return true;
    } catch (error) {
      console.error('Error updating bill:', error);
      return false;
    }
  }

  async setBudget(totalBudgetYuan: string): Promise<boolean> {
    return await this.setBudgetForMonth(this.currentMonth, totalBudgetYuan);
  }

  async setBudgetForMonth(month: string, totalBudgetYuan: string): Promise<boolean> {
    try {
      if (!month || month.length !== 7) {
        console.error('Invalid budget month:', month);
        return false;
      }

      const budgetFen = CurrencyUtil.yuanToFen(totalBudgetYuan);

      if (isNaN(budgetFen)) {
        console.error('Invalid budget amount:', totalBudgetYuan);
        return false;
      }

      const budget = new BudgetModel();
      budget.month = month;
      budget.totalBudget = budgetFen;

      await this.dbHelper.setBudget(budget);

      if (month === this.currentMonth) {
        this.monthlyBudget = budgetFen;
      }

      return true;
    } catch (error) {
      console.error('Error setting budget for month:', error);
      return false;
    }
  }

  async getBudgetForMonth(month: string): Promise<number> {
    try {
      if (!month || month.length !== 7) {
        console.error('Invalid month when getting budget:', month);
        return 0;
      }

      return await this.dbHelper.getBudget(month);
    } catch (error) {
      console.error('Error getting budget for month:', error);
      return 0;
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

  /**
   * 分类统计
   *
   * 这里仍然基于 this.bills，
   * 所以它会跟随当前首页筛选结果变化。
   * 如果你希望统计页也永远统计整月全部账单，
   * 后面可以单独再改 StatisticsPage。
   */
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
    const billsJsonItems: BillJsonItem[] = bills.map((b: BillModel): BillJsonItem => {
      return {
        amount: b.amount,
        category: b.category,
        date: b.date,
        remark: b.remark
      } as BillJsonItem;
    });
    const billsJson = JSON.stringify(billsJsonItems);

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
  private buildMonthlyInsightDataTextFallback(
    month: string, bills: BillModel[], budgetFen: number
  ): string {
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
}