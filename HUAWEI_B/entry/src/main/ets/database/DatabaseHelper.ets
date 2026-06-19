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

    await this.store.executeSql(`
      CREATE TABLE IF NOT EXISTS ${TABLE_BILL} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount INTEGER NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        remark TEXT
      )
    `);

    // 兼容旧数据库：如果旧表没有 date / remark 字段，就补上
    await this.addColumnIfNotExists(`ALTER TABLE ${TABLE_BILL} ADD COLUMN date TEXT DEFAULT ''`);
    await this.addColumnIfNotExists(`ALTER TABLE ${TABLE_BILL} ADD COLUMN remark TEXT DEFAULT ''`);

    await this.store.executeSql(`
      CREATE TABLE IF NOT EXISTS ${TABLE_BUDGET} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        month TEXT NOT NULL UNIQUE,
        totalBudget INTEGER NOT NULL
      )
    `);
  }

  private async addColumnIfNotExists(sql: string): Promise<void> {
    if (!this.store) {
      return;
    }

    try {
      await this.store.executeSql(sql);
    } catch (error) {
      console.info('Column may already exist:', JSON.stringify(error));
    }
  }

  async insertBill(bill: BillModel): Promise<number> {
    if (!this.store) {
      console.error('Database store is null when inserting bill');
      return -1;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      amount: bill.amount,
      category: bill.category,
      date: bill.date,
      remark: bill.remark || ''
    };

    const rowId = await this.store.insert(TABLE_BILL, valueBucket);
    console.info(`insertBill rowId=${rowId}, date=${bill.date}`);
    return rowId;
  }

  async deleteBill(id: number): Promise<number> {
    if (!this.store) {
      console.error('Database store is null when deleting bill');
      return 0;
    }

    if (id === undefined || id === null || id < 0) {
      console.error('Invalid bill id when deleting:', id);
      return 0;
    }

    const predicates = new relationalStore.RdbPredicates(TABLE_BILL);
    predicates.equalTo('id', id);

    const rows = await this.store.delete(predicates);
    console.info(`deleteBill id=${id}, affected rows=${rows}`);
    return rows;
  }

  async updateBill(bill: BillModel): Promise<number> {
    if (!this.store) {
      console.error('Database store is null when updating bill');
      return 0;
    }

    if (bill.id === undefined || bill.id === null || bill.id < 0) {
      console.error('Invalid bill id when updating:', bill.id);
      return 0;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      amount: bill.amount,
      category: bill.category,
      date: bill.date,
      remark: bill.remark || ''
    };

    const predicates = new relationalStore.RdbPredicates(TABLE_BILL);

    // 关键：只允许根据 id 更新，不允许根据日期、分类、备注更新
    predicates.equalTo('id', bill.id);

    const rows = await this.store.update(valueBucket, predicates);
    console.info(`updateBill id=${bill.id}, date=${bill.date}, affected rows=${rows}`);

    return rows;
  }

  async queryBills(month: string, keyword?: string, category?: string): Promise<BillModel[]> {
    if (!this.store) {
      console.error('Database store is null when querying bills');
      return [];
    }

    const predicates = new relationalStore.RdbPredicates(TABLE_BILL);

    if (month && month.trim().length > 0) {
      predicates.like('date', `${month}%`);
    }

    if (keyword && keyword.trim().length > 0) {
      predicates.and();
      predicates.like('remark', `%${keyword.trim()}%`);
    }

    if (category && category.trim().length > 0) {
      predicates.and();
      predicates.equalTo('category', category.trim());
    }

    const resultSet = await this.store.query(predicates);
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

    bills.sort((a: BillModel, b: BillModel) => {
      if (a.date === b.date) {
        return b.id - a.id;
      }
      return b.date.localeCompare(a.date);
    });

    return bills;
  }

  async setBudget(budget: BudgetModel): Promise<void> {
    if (!this.store) {
      console.error('Database store is null when setting budget');
      return;
    }

    const valueBucket: relationalStore.ValuesBucket = {
      month: budget.month,
      totalBudget: budget.totalBudget
    };

    const predicates = new relationalStore.RdbPredicates(TABLE_BUDGET);
    predicates.equalTo('month', budget.month);

    const resultSet = await this.store.query(predicates);

    if (resultSet.rowCount > 0) {
      await this.store.update(valueBucket, predicates);
    } else {
      await this.store.insert(TABLE_BUDGET, valueBucket);
    }

    resultSet.close();
  }

  async getBudget(month: string): Promise<number> {
    if (!this.store) {
      console.error('Database store is null when getting budget');
      return 0;
    }

    const predicates = new relationalStore.RdbPredicates(TABLE_BUDGET);
    predicates.equalTo('month', month);

    const resultSet = await this.store.query(predicates);

    let budget = 0;
    if (resultSet.goToNextRow()) {
      budget = resultSet.getLong(resultSet.getColumnIndex('totalBudget'));
    }

    resultSet.close();
    return budget;
  }
}