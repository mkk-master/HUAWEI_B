// 设备 UI 自动化测试 — 基于 HapTest / @ohos.UiTest
// 测试策略 1: TextPresence — 验证关键页面存在预期文字
// 测试策略 2: ComponentPresence — 验证关键 UI 组件存在且可交互

import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';

export default function abilityTest() {
  describe('SmartAccount_UiTest', () => {

    let driver: Driver | null = null;

    beforeAll(async () => {
      driver = Driver.create();
      // 等待应用首页加载完成
      await driver.delayMs(2000);
    });

    afterAll(async () => {
      // 清理工作由框架管理
    });

    // ==========================================================
    // 策略 1: TextPresence — 验证关键文字存在
    // ==========================================================

    it('TextPresence_首页标题存在', 0, async () => {
      if (!driver) return;
      await driver.assertComponentExist(ON.text('智慧记账'), 5000);
    });

    it('TextPresence_导航按钮文字存在', 0, async () => {
      if (!driver) return;
      await driver.assertComponentExist(ON.text('记一笔'), 3000);
      await driver.assertComponentExist(ON.text('消费统计'), 3000);
    });

    it('TextPresence_月份选择器文字存在', 0, async () => {
      if (!driver) return;
      await driver.assertComponentExist(ON.text('上月'), 3000);
      await driver.assertComponentExist(ON.text('下月'), 3000);
      await driver.assertComponentExist(ON.text('本月'), 3000);
    });

    it('TextPresence_预算卡片文字存在', 0, async () => {
      if (!driver) return;
      await driver.assertComponentExist(ON.text('剩余'), 3000);
      await driver.assertComponentExist(ON.text('预算'), 3000);
      await driver.assertComponentExist(ON.text('已花'), 3000);
    });

    it('TextPresence_搜索栏与筛选存在', 0, async () => {
      if (!driver) return;
      await driver.assertComponentExist(ON.text('全部类型'), 3000);
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
      await driver.assertComponentExist(ON.type('TextInput'), 3000);
    });

    it('ComponentPresence_Progress组件存在', 0, async () => {
      if (!driver) return;
      await driver.assertComponentExist(ON.type('Progress'), 3000);
    });

    it('ComponentPresence_导航到记一笔页并返回', 0, async () => {
      if (!driver) return;
      // 点击"记一笔"
      const addBtn = await driver.findComponent(ON.text('记一笔'));
      expect(addBtn !== null).assertTrue();
      await addBtn!.click();
      await driver.delayMs(1500);
      // 验证进入记一笔页
      await driver.assertComponentExist(ON.text('保存'), 3000);
      await driver.assertComponentExist(ON.text('取消'), 3000);
      // 返回首页
      const cancelBtn = await driver.findComponent(ON.text('取消'));
      await cancelBtn!.click();
      await driver.delayMs(1500);
      // 确认返回
      await driver.assertComponentExist(ON.text('智慧记账'), 3000);
    });

    it('ComponentPresence_导航到消费统计页并返回', 0, async () => {
      if (!driver) return;
      const statsBtn = await driver.findComponent(ON.text('消费统计'));
      expect(statsBtn !== null).assertTrue();
      await statsBtn!.click();
      await driver.delayMs(1500);
      // 验证进入统计页
      await driver.assertComponentExist(ON.text('饼图'), 3000);
      await driver.assertComponentExist(ON.text('详情'), 3000);
      // 返回首页
      const backBtn = await driver.findComponent(ON.text('返回'));
      await backBtn!.click();
      await driver.delayMs(1500);
      await driver.assertComponentExist(ON.text('智慧记账'), 3000);
    });
  });
}
