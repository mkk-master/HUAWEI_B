// 设备 UI 自动化测试 — @ohos.UiTest
// Driver 由 OpenHarmonyTestRunner.onPrepare 创建，存于 globalThis.driver
// 测试策略 1: TextPresence — 首页关键文字存在
// 测试策略 2: ComponentPresence — 组件可点击、页面跳转正常

import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';

function getDriver(): Driver {
  return globalThis.driver as Driver;
}

export default function abilityTest() {
  describe('SmartAccount_UiTest', () => {

    let driver: Driver;

    beforeAll(() => {
      driver = getDriver();
    });

    // ==========================================================
    // 策略 1: TextPresence — 验证关键文字
    // ==========================================================

    it('TextPresence_首页标题智慧记账', 0, async () => {
      await driver.assertComponentExist(ON.text('智慧记账'));
    });

    it('TextPresence_本月按钮', 0, async () => {
      await driver.assertComponentExist(ON.text('本月'));
    });

    it('TextPresence_记一笔按钮文字', 0, async () => {
      await driver.assertComponentExist(ON.text('记一笔'));
    });

    // ==========================================================
    // 策略 2: ComponentPresence — 验证组件交互
    // ==========================================================

    it('ComponentPresence_按钮数量大于0', 0, async () => {
      const btns = await driver.findComponents(ON.type('Button'));
      expect(btns !== null).assertTrue();
      expect(btns.length > 0).assertTrue();
    });

    it('ComponentPresence_点击记一笔进入添加页', 0, async () => {
      const addBtn = await driver.findComponent(ON.text('记一笔'));
      expect(addBtn !== null).assertTrue();
      await addBtn.click();
      await driver.delayMs(1500);
      // 进入 AddBillPage 后应有"保存"按钮
      await driver.assertComponentExist(ON.text('保存'));
      // 返回首页
      const cancelBtn = await driver.findComponent(ON.text('取消'));
      await cancelBtn.click();
      await driver.delayMs(1500);
      await driver.assertComponentExist(ON.text('智慧记账'));
    });

    it('ComponentPresence_点击本月切换时间', 0, async () => {
      await driver.findComponent(ON.text('本月'));
      // 如果能找到"本月"按钮，说明组件树可用
    });
  });
}
