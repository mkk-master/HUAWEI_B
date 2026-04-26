// 文件路径: entry/src/main/ets/database/DatabaseHelper.ets
import relationalStore from '@ohos.data.relationalStore';
import { BillModel, CategoryType, BudgetModel } from '../model/BillModel';

const DB_NAME = 'SmartAccount.db';
const TABLE_BILL = 'bill';
const TABLE_BUDGET = 'budget';

export class DatabaseHelper {
  private static instance: DatabaseHelper;
  private store: relationalStore.RdbStore | null = null;

  private constructor() {}

  static getInstance(): DatabaseHelper {
    if (!DatabaseHelper.instance) {
      DatabaseHelper.instance = new DatabaseHelper();
    }
    return DatabaseHelper.instance;
  }

  async initDatabase(context: Context): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };

    this.store = await relationalStore.getRdbStore(context, config);

    // 创建账单表
    await this.store.executeSql(`
      CREATE TABLE IF NOT EXISTS ${TABLE_BILL} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount INTEGER NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        remark TEXT
      )
    `);

    // 创建预算表
    await this.store.executeSql(`
      CREATE TABLE IF NOT EXISTS ${TABLE_BUDGET} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month TEXT NOT NULL UNIQUE,
        totalBudget INTEGER NOT NULL
      )
    `);
  }

  // 增加账单
  async insertBill(bill: BillModel): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      amount: bill.amount,
      category: bill.category,
      date: bill.date,
      remark: bill.remark
    };
    return await this.store!.insert(TABLE_BILL, valueBucket);
  }

  // 删除账单
  async deleteBill(id: number): Promise<number> {
    const predicates = new relationalStore.RdbPredicates(TABLE_BILL);
    predicates.equalTo('id', id);
    return await this.store!.delete(predicates);
  }

  // 更新账单
  async updateBill(bill: BillModel): Promise<number> {
    const valueBucket: relationalStore.ValuesBucket = {
      amount: bill.amount,
      category: bill.category,
      date: bill.date,
      remark: bill.remark
    };
    const predicates = new relationalStore.RdbPredicates(TABLE_BILL);
    predicates.equalTo('id', bill.id);
    return await this.store!.update(valueBucket, predicates);
  }

  // 查询月度账单（带筛选）
  async queryBills(month: string, keyword?: string, category?: string): Promise<BillModel[]> {
    const predicates = new relationalStore.RdbPredicates(TABLE_BILL);
    predicates.like('date', `${month}%`);

    if (keyword && keyword.trim().length > 0) {
      predicates.and();
      predicates.like('remark', `%${keyword.trim()}%`);
    }

    if (category && category.trim().length > 0) {
      predicates.and();
      predicates.equalTo('category', category.trim());
    }

    const resultSet = await this.store!.query(predicates);
    const bills: BillModel[] = [];

    while (resultSet.goToNextRow()) {
      bills.push(new BillModel(
        resultSet.getLong(resultSet.getColumnIndex('id')),
        resultSet.getLong(resultSet.getColumnIndex('amount')),
        resultSet.getString(resultSet.getColumnIndex('category')) as CategoryType,
        resultSet.getString(resultSet.getColumnIndex('date')),
        resultSet.getString(resultSet.getColumnIndex('remark'))
      ));
    }
    resultSet.close();
    return bills;
  }

  // 设置/更新预算
  async setBudget(budget: BudgetModel): Promise<void> {
    const valueBucket: relationalStore.ValuesBucket = {
      month: budget.month,
      totalBudget: budget.totalBudget
    };

    // 先查询是否存在
    const predicates = new relationalStore.RdbPredicates(TABLE_BUDGET);
    predicates.equalTo('month', budget.month);
    const resultSet = await this.store!.query(predicates);

    if (resultSet.rowCount > 0) {
      await this.store!.update(valueBucket, predicates);
    } else {
      await this.store!.insert(TABLE_BUDGET, valueBucket);
    }
    resultSet.close();
  }

  // 获取月度预算
  async getBudget(month: string): Promise<number> {
    const predicates = new relationalStore.RdbPredicates(TABLE_BUDGET);
    predicates.equalTo('month', month);
    const resultSet = await this.store!.query(predicates);

    let budget = 0;
    if (resultSet.goToNextRow()) {
      budget = resultSet.getLong(resultSet.getColumnIndex('totalBudget'));
    }
    resultSet.close();
    return budget;
  }
}