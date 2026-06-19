// 本地单元测试 — 不依赖设备，验证核心工具类与数据模型

import { describe, it, expect } from '@ohos/hypium';
import { CurrencyUtil } from '../main/ets/utils/CurrencyUtil';
import { BillModel, CategoryType, BudgetModel, CategoryColors } from '../main/ets/model/BillModel';

export default function localUnitTest() {
  describe('CurrencyUtilTest', () => {

    it('fenToYuan_normal', 0, () => {
      expect(CurrencyUtil.fenToYuan(100)).assertEqual('1.00');
      expect(CurrencyUtil.fenToYuan(0)).assertEqual('0.00');
      expect(CurrencyUtil.fenToYuan(50)).assertEqual('0.50');
      expect(CurrencyUtil.fenToYuan(12345)).assertEqual('123.45');
    });

    it('fenToYuan_large', 0, () => {
      expect(CurrencyUtil.fenToYuan(123456789)).assertEqual('123.46万');
    });

    it('fenToYuan_yi', 0, () => {
      expect(CurrencyUtil.fenToYuan(12345678900)).assertEqual('1.23亿');
    });

    it('yuanToFen_normal', 0, () => {
      expect(CurrencyUtil.yuanToFen('1.00')).assertEqual(100);
      expect(CurrencyUtil.yuanToFen('0.5')).assertEqual(50);
    });

    it('yuanToFen_edge_cases', 0, () => {
      // 边界值测试
      expect(CurrencyUtil.yuanToFen('0')).assertEqual(0);
      expect(CurrencyUtil.yuanToFen('0.01')).assertEqual(1);
      expect(CurrencyUtil.yuanToFen('9999')).assertEqual(999900);
    });

    it('isValidAmount_check', 0, () => {
      expect(CurrencyUtil.isValidAmount('100')).assertTrue();
      expect(CurrencyUtil.isValidAmount('1.50')).assertTrue();
      expect(CurrencyUtil.isValidAmount('')).assertFalse();
      expect(CurrencyUtil.isValidAmount('abc')).assertFalse();
      expect(CurrencyUtil.isValidAmount('1.567')).assertFalse();
      expect(CurrencyUtil.isValidAmount('-1')).assertFalse();
    });
  });

  describe('BillModelTest', () => {

    it('BillModel_construct', 0, () => {
      const bill = new BillModel(1, 5000, CategoryType.FOOD, '2026-06-19', '午餐');
      expect(bill.id).assertEqual(1);
      expect(bill.amount).assertEqual(5000);
      expect(bill.category).assertEqual(CategoryType.FOOD);
      expect(bill.date).assertEqual('2026-06-19');
      expect(bill.remark).assertEqual('午餐');
    });

    it('CategoryType_8_values', 0, () => {
      const values: string[] = Object.values(CategoryType);
      expect(values.length).assertEqual(8);
      expect(values.indexOf('饮食')).assertLarger(-1);
      expect(values.indexOf('交通')).assertLarger(-1);
      expect(values.indexOf('购物')).assertLarger(-1);
      expect(values.indexOf('娱乐')).assertLarger(-1);
      expect(values.indexOf('居住')).assertLarger(-1);
      expect(values.indexOf('医疗')).assertLarger(-1);
      expect(values.indexOf('教育')).assertLarger(-1);
      expect(values.indexOf('其他')).assertLarger(-1);
    });

    it('BudgetModel_assign', 0, () => {
      const budget = new BudgetModel();
      budget.month = '2026-06';
      budget.totalBudget = 200000;
      expect(budget.month).assertEqual('2026-06');
      expect(budget.totalBudget).assertEqual(200000);
    });

    it('CategoryColors_all_8', 0, () => {
      Object.values(CategoryType).forEach((cat: string) => {
        const color: string = CategoryColors[cat];
        expect(color !== undefined && color.length > 0).assertTrue();
      });
    });
  });
}
