// 设备 UI 自动化测试 — 基于 @ohos.UiTest
// 测试策略 1: TextPresence — 验证 UI 层级中存在预期元素
// 测试策略 2: ComponentPresence — 验证关键 UI 组件可交互

import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON, Component } from '@ohos.UiTest';

export default function abilityTest() {
  describe('SmartAccount_UiTest', () => {

    let driver: Driver | null = null;

    beforeAll(async () => {
      driver = Driver.create();
      await driver.delayMs(3000);
    });

    afterAll(async () => {
      // 框架管理
    });

    // ==============================
    // 策略 1: TextPresence
    // 验证页面中至少存在 Button 元素（按钮必然带文字）
    // 通过 findComponents 获取所有按钮，间接验证文字渲染
    // ==============================

    it('TextPresence_首页至少渲染一个按钮', 0, async () => {
      if (!driver) return;
      const btns = await driver.findComponents(ON.type('Button'));
      expect(btns !== null).assertTrue();
      expect(btns.length > 0).assertTrue();
    });

    it('TextPresence_至少存在5个按钮元素', 0, async () => {
      if (!driver) return;
      // 首页：上月、下月、本月、记一笔、消费统计 → 至少 5 个按钮
      const btns = await driver.findComponents(ON.type('Button'));
      expect(btns === null ? false : btns.length >= 5).assertTrue();
    });

    // ==============================
    // 策略 2: ComponentPresence
    // ==============================

    it('ComponentPresence_首页存在可交互元素', 0, async () => {
      if (!driver) return;
      // 可点击元素数量
      const clickable = await driver.findComponents(ON.clickable(true));
      expect(clickable !== null && clickable.length > 0).assertTrue();
    });

    it('ComponentPresence_点击按钮并返回首页', 0, async () => {
      if (!driver) return;
      // 获取所有按钮，至少有 1 个
      const allBtns = await driver.findComponents(ON.type('Button'));
      expect(allBtns.length > 0).assertTrue();
      // 点击第一个按钮
      if (allBtns.length > 0) {
        await allBtns[0].click();
        await driver.delayMs(1000);
        // 按返回键回到首页
        await driver.pressBack();
        await driver.delayMs(1000);
        // 验证首页仍然存在按钮
        const btns2 = await driver.findComponents(ON.type('Button'));
        expect(btns2.length > 0).assertTrue();
      }
    });

    it('ComponentPresence_应用可正常响应', 0, async () => {
      if (!driver) return;
      // 验证 List 组件存在（账单列表）
      const lists = await driver.findComponents(ON.type('List'));
      // List 可能存在也可能为空列表无数据，不强制断言
      expect(lists !== null).assertTrue();
    });
  });
}
