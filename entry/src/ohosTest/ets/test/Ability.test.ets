// 设备 UI 自动化测试 — 基于 @ohos.UiTest
// 测试策略 1: TextPresence — 验证关键页面存在预期文字
// 测试策略 2: ComponentPresence — 验证关键 UI 组件存在且可交互

import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON, Component, MatchPattern } from '@ohos.UiTest';

function assertText(driver: Driver, text: string): Promise<void> {
  // 用 CONTAINS 匹配，兼容嵌套在 Button/Row 里的 Text
  return driver.assertComponentExist(ON.text(text, MatchPattern.CONTAINS));
}

async function findAndClick(driver: Driver, text: string): Promise<boolean> {
  const comp = await driver.findComponent(ON.text(text, MatchPattern.CONTAINS));
  if (comp) {
    await comp.click();
    return true;
  }
  return false;
}

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

    // ==========================================================
    // 策略 1: TextPresence — 验证关键文字存在
    // ==========================================================

    it('TextPresence_首页关键文字存在', 0, async () => {
      if (!driver) return;
      await assertText(driver, '智慧记账');
      await assertText(driver, '上月');
      await assertText(driver, '本月');
      await assertText(driver, '剩余');
      await assertText(driver, '已花');
    });

    // ==========================================================
    // 策略 2: ComponentPresence — 验证 UI 组件
    // ==========================================================

    it('ComponentPresence_可交互按钮存在', 0, async () => {
      if (!driver) return;
      const buttons = await driver.findComponents(ON.clickable(true));
      expect(buttons.length > 0).assertTrue();
    });

    it('ComponentPresence_输入框存在', 0, async () => {
      if (!driver) return;
      const inputs = await driver.findComponents(ON.type('TextInput'));
      expect(inputs.length > 0).assertTrue();
    });

    it('ComponentPresence_进入记一笔页并返回', 0, async () => {
      if (!driver) return;
      // 点击"记一笔"按钮
      const clicked = await findAndClick(driver, '记一笔');
      expect(clicked).assertTrue();
      await driver.delayMs(1500);
      // 验证进入记一笔页
      await assertText(driver, '保存');
      await assertText(driver, '金额');
      // 返回
      await findAndClick(driver, '取消');
      await driver.delayMs(1500);
      await assertText(driver, '智慧记账');
    });

    it('ComponentPresence_切换月份正常', 0, async () => {
      if (!driver) return;
      await findAndClick(driver, '上月');
      await driver.delayMs(500);
      await findAndClick(driver, '本月');
      await driver.delayMs(500);
      await assertText(driver, '智慧记账');
    });
  });
}
