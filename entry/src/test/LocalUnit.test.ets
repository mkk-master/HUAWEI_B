// 本地单元测试 — 不依赖设备，验证核心工具类与数据模型

import { describe, it, expect } from '@ohos/hypium';
import { CurrencyUtil } from '../../main/ets/utils/CurrencyUtil';
import { BillModel, CategoryType, BudgetModel, CategoryColors } from '../../main/ets/model/BillModel';

export default function localUnitTest() {
  describe('CurrencyUtil_金额工具类', () => {

    it('fenToYuan_正常转换', 0, () => {
      expect(CurrencyUtil.fenToYuan(100)).assertEqual('1.00');
      expect(CurrencyUtil.fenToYuan(0)).assertEqual('0.00');
      expect(CurrencyUtil.fenToYuan(50)).assertEqual('0.50');
      expect(CurrencyUtil.fenToYuan(12345)).assertEqual('123.45');
    });

    it('fenToYuan_万元亿级转换', 0, () => {
      expect(CurrencyUtil.fenToYuan(123456789)).assertEqual('12345.68万');
      expect(CurrencyUtil.fenToYuan(12345678900)).assertEqual('1.23亿');
    });

    it('yuanToFen_正常转换与非法输入', 0, () => {
      expect(CurrencyUtil.yuanToFen('1.00')).assertEqual(100);
      expect(CurrencyUtil.yuanToFen('0.5')).assertEqual(50);
      expect(isNaN(CurrencyUtil.yuanToFen('abc'))).assertTrue();
      expect(isNaN(CurrencyUtil.yuanToFen('-1'))).assertTrue();
    });

    it('isValidAmount_合法性校验', 0, () => {
      expect(CurrencyUtil.isValidAmount('100')).assertTrue();
      expect(CurrencyUtil.isValidAmount('1.50')).assertTrue();
      expect(CurrencyUtil.isValidAmount('')).assertFalse();
      expect(CurrencyUtil.isValidAmount('abc')).assertFalse();
      expect(CurrencyUtil.isValidAmount('1.567')).assertFalse();
      expect(CurrencyUtil.isValidAmount('-1')).assertFalse();
    });
  });

  describe('BillModel_数据模型', () => {

    it('BillModel_构造与字段', 0, () => {
      const bill = new BillModel(1, 5000, CategoryType.FOOD, '2026-06-19', '午餐');
      expect(bill.id).assertEqual(1);
      expect(bill.amount).assertEqual(5000);
      expect(bill.category).assertEqual(CategoryType.FOOD);
      expect(bill.date).assertEqual('2026-06-19');
      expect(bill.remark).assertEqual('午餐');
    });

    it('CategoryType_枚举完整8种分类', 0, () => {
      const values: string[] = Object.values(CategoryType);
      expect(values.length).assertEqual(8);
      [('饮食'), ('交通'), ('购物'), ('娱乐'), ('居住'), ('医疗'), ('教育'), ('其他')]
        .forEach((cat: string) => expect(values.indexOf(cat)).assertLarger(-1));
    });

    it('BudgetModel_默认赋值', 0, () => {
      const budget = new BudgetModel();
      budget.month = '2026-06';
      budget.totalBudget = 200000;
      expect(budget.month).assertEqual('2026-06');
      expect(budget.totalBudget).assertEqual(200000);
    });

    it('CategoryColors_覆盖所有8种分类', 0, () => {
      Object.values(CategoryType).forEach((cat: string) => {
        const color: string = CategoryColors[cat];
        expect(color !== undefined && color.length > 0).assertTrue();
      });
    });
  });
}
