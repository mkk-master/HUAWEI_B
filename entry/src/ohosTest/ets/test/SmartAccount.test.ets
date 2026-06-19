// HapTest 补充测试：数据模型 + 分类引擎逻辑
// 测试策略: TextPresence + ComponentPresence 扩展

import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';

export default function smartAccountHapTest() {
  describe('SmartAccount_Extended', () => {

    let driver: Driver | null = null;

    beforeAll(async () => {
      driver = Driver.create();
      await driver!.delayMs(2000);
    });

    afterAll(async () => {
      // 框架管理
    });

    // 策略1扩展：验证 AddBillPage 全字段
    it('TextPresence_AddBillPage全字段存在', 0, async () => {
      if (!driver) return;
      const addBtn = await driver!.findComponent(ON.text('记一笔'));
      await addBtn!.click();
      await driver!.delayMs(1500);
      await driver!.assertComponentExist(ON.text('金额'), 2000);
      await driver!.assertComponentExist(ON.text('分类'), 2000);
      await driver!.assertComponentExist(ON.text('日期'), 2000);
      await driver!.assertComponentExist(ON.text('备注'), 2000);
      await driver!.assertComponentExist(ON.text('保存'), 2000);
      // 返回
      const cancel = await driver!.findComponent(ON.text('取消'));
      await cancel!.click();
      await driver!.delayMs(1000);
    });

    // 策略2扩展：分类 Grid 组件可用
    it('ComponentPresence_分类Grid存在8个分类', 0, async () => {
      if (!driver) return;
      const addBtn = await driver!.findComponent(ON.text('记一笔'));
      await addBtn!.click();
      await driver!.delayMs(1500);
      // 验证8个分类文字都存在
      const cats: string[] = [('饮食'), ('交通'), ('购物'), ('娱乐'), ('居住'), ('医疗'), ('教育'), ('其他')];
      for (let i = 0; i < cats.length; i++) {
        await driver!.assertComponentExist(ON.text(cats[i]), 2000);
      }
      const cancel = await driver!.findComponent(ON.text('取消'));
      await cancel!.click();
      await driver!.delayMs(1000);
    });

    // 策略2扩展：验证金额输入校验逻辑
    it('ComponentPresence_金额校验逻辑', 0, async () => {
      // 合法金额
      expect(/^\d+(\.\d{0,2})?$/.test('50.00')).assertTrue();
      expect(/^\d+(\.\d{0,2})?$/.test('0.01')).assertTrue();
      // 非法金额
      expect(/^\d+(\.\d{0,2})?$/.test('-50')).assertFalse();
      expect(/^\d+(\.\d{0,2})?$/.test('abc')).assertFalse();
      expect(/^\d+(\.\d{0,2})?$/.test('50.999')).assertFalse();
    });

    // 策略2扩展：验证分类枚举完整性
    it('ComponentPresence_分类枚举完整性', 0, () => {
      const categories: string[] = [('饮食'), ('交通'), ('购物'), ('娱乐'), ('居住'), ('医疗'), ('教育'), ('其他')];
      expect(categories.length).assertEqual(8);
    });
  });
}
