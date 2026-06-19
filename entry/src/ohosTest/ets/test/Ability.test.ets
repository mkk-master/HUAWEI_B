// 设备 UI 自动化测试 — 基于 @ohos.UiTest
// 测试策略 1: TextPresence — 验证关键页面存在预期文字
// 测试策略 2: ComponentPresence — 验证关键 UI 组件存在且可交互

import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';

function assertComp(driver: Driver, text: string): Promise<void> {
  return driver.assertComponentExist(ON.text(text));
}

function assertType(driver: Driver, typeName: string): Promise<void> {
  return driver.assertComponentExist(ON.type(typeName));
}

export default function abilityTest() {
  describe('SmartAccount_UiTest', () => {

    let driver: Driver | null = null;

    beforeAll(async () => {
      driver = Driver.create();
      await driver.delayMs(2000);
    });

    afterAll(async () => {
      // 框架管理
    });

    // ==========================================================
    // 策略 1: TextPresence — 验证关键文字存在
    // ==========================================================

    it('TextPresence_首页标题存在', 0, async () => {
      if (!driver) return;
      await assertComp(driver, '智慧记账');
    });

    it('TextPresence_导航按钮文字存在', 0, async () => {
      if (!driver) return;
      await assertComp(driver, '记一笔');
      await assertComp(driver, '消费统计');
    });

    it('TextPresence_月份选择器文字存在', 0, async () => {
      if (!driver) return;
      await assertComp(driver, '上月');
      await assertComp(driver, '下月');
      await assertComp(driver, '本月');
    });

    it('TextPresence_预算卡片文字存在', 0, async () => {
      if (!driver) return;
      await assertComp(driver, '剩余');
      await assertComp(driver, '预算');
      await assertComp(driver, '已花');
    });

    it('TextPresence_搜索栏与筛选存在', 0, async () => {
      if (!driver) return;
      await assertComp(driver, '全部类型');
    });

    // ==========================================================
    // 策略 2: ComponentPresence — 验证 UI 组件
    // ==========================================================

    it('ComponentPresence_Button组件存在', 0, async () => {
      if (!driver) return;
      const buttons = await driver.findComponents(ON.type('Button'));
      expect(buttons.length > 0).assertTrue();
    });

    it('ComponentPresence_TextInput组件存在', 0, async () => {
      if (!driver) return;
      await assertType(driver, 'TextInput');
    });

    it('ComponentPresence_Progress组件存在', 0, async () => {
      if (!driver) return;
      await assertType(driver, 'Progress');
    });

    it('ComponentPresence_导航到记一笔页并返回', 0, async () => {
      if (!driver) return;
      const addBtn = await driver.findComponent(ON.text('记一笔'));
      expect(addBtn !== null).assertTrue();
      if (addBtn) {
        await addBtn.click();
      }
      await driver.delayMs(1500);
      await assertComp(driver, '保存');
      await assertComp(driver, '取消');
      const cancelBtn = await driver.findComponent(ON.text('取消'));
      if (cancelBtn) {
        await cancelBtn.click();
      }
      await driver.delayMs(1500);
      await assertComp(driver, '智慧记账');
    });

    it('ComponentPresence_导航到消费统计页并返回', 0, async () => {
      if (!driver) return;
      const statsBtn = await driver.findComponent(ON.text('消费统计'));
      expect(statsBtn !== null).assertTrue();
      if (statsBtn) {
        await statsBtn.click();
      }
      await driver.delayMs(1500);
      await assertComp(driver, '饼图');
      await assertComp(driver, '详情');
      const backBtn = await driver.findComponent(ON.text('返回'));
      if (backBtn) {
        await backBtn.click();
      }
      await driver.delayMs(1500);
      await assertComp(driver, '智慧记账');
    });
  });
}
