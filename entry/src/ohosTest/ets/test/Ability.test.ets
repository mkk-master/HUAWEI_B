// 设备 UI 自动化测试 — @ohos.UiTest (HapTest 兼容)
// 测试策略 1: TextPresence — 验证 UI 中预期文字存在
// 测试策略 2: ComponentPresence — 验证关键组件存在且可交互

import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.application.abilityDelegatorRegistry';

let driver: Driver | null = null;

function getDelegator() {
  return abilityDelegatorRegistry.getAbilityDelegator();
}

async function startApp() {
  const delegator = getDelegator();
  // 启动被测应用的 EntryAbility
  await delegator.startAbility({
    bundleName: 'com.example.count1',
    abilityName: 'EntryAbility'
  });
  await driver!.delayMs(3000);
}

export default function abilityTest() {
  describe('SmartAccount_UiTest', () => {

    beforeAll(async () => {
      driver = Driver.create();
      await startApp();
    });

    afterAll(async () => {
      // 被测应用会由测试框架关闭
    });

    // ==========================================================
    // 策略 1: TextPresence — 验证关键文字内容存在
    // ==========================================================

    it('TextPresence_首页标题智慧记账存在', 0, async () => {
      if (!driver) return;
      await driver.assertComponentExist(ON.text('智慧记账'));
    });

    it('TextPresence_月份导航按钮存在', 0, async () => {
      if (!driver) return;
      await driver.assertComponentExist(ON.text('上月'));
      await driver.assertComponentExist(ON.text('本月'));
      await driver.assertComponentExist(ON.text('下月'));
    });

    it('TextPresence_预算卡片关键文字存在', 0, async () => {
      if (!driver) return;
      await driver.assertComponentExist(ON.text('剩余'));
      await driver.assertComponentExist(ON.text('预算'));
      await driver.assertComponentExist(ON.text('已花'));
    });

    // ==========================================================
    // 策略 2: ComponentPresence — 验证关键组件可交互
    // ==========================================================

    it('ComponentPresence_首页至少有一个按钮', 0, async () => {
      if (!driver) return;
      const btns = await driver.findComponents(ON.type('Button'));
      expect(btns !== null && btns.length > 0).assertTrue();
    });

    it('ComponentPresence_记一笔按钮可点击并跳转', 0, async () => {
      if (!driver) return;
      const addBtn = await driver.findComponent(ON.text('记一笔'));
      expect(addBtn !== null).assertTrue();
      if (addBtn) {
        await addBtn.click();
        await driver.delayMs(1500);
        await driver.assertComponentExist(ON.text('保存'));
        await driver.assertComponentExist(ON.text('取消'));
        // 返回首页
        const cancelBtn = await driver.findComponent(ON.text('取消'));
        if (cancelBtn) {
          await cancelBtn.click();
          await driver.delayMs(1500);
        }
      }
    });

    it('ComponentPresence_pressBack正常退出', 0, async () => {
      if (!driver) return;
      await driver.pressBack();
      await driver.delayMs(500);
    });
  });
}
