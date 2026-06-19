// 设备 UI 自动化测试 — @ohos.UiTest
// Driver 由 OpenHarmonyTestRunner 在测试启动前创建并启动被测应用
// 测试直接 new Driver() 即可（共享同一设备会话）
// 测试策略 1: TextPresence — 首页关键文字存在
// 测试策略 2: ComponentPresence — 组件可点击、页面跳转正常

import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';

export default function abilityTest() {
  describe('SmartAccount_UiTest', () => {

    let driver: Driver | null = null;

    beforeAll(async () => {
      driver = Driver.create();
      await driver.delayMs(1000);
    });

    // ==========================================================
    // 策略 1: TextPresence
    // ==========================================================

    it('TextPresence_首页标题智慧记账', 0, async () => {
      await driver!.assertComponentExist(ON.text('智慧记账'));
    });

    it('TextPresence_月份导航按钮', 0, async () => {
      await driver!.assertComponentExist(ON.text('上月'));
      await driver!.assertComponentExist(ON.text('本月'));
    });

    // ==========================================================
    // 策略 2: ComponentPresence
    // ==========================================================

    it('ComponentPresence_Button组件存在', 0, async () => {
      const btns = await driver!.findComponents(ON.type('Button'));
      expect(btns !== null && btns.length > 0).assertTrue();
    });

    it('ComponentPresence_点击记一笔进入添加页', 0, async () => {
      const addBtn = await driver!.findComponent(ON.text('记一笔'));
      expect(addBtn !== null).assertTrue();
      await addBtn!.click();
      await driver!.delayMs(1500);
      await driver!.assertComponentExist(ON.text('保存'));
      await driver!.assertComponentExist(ON.text('取消'));
      const cancelBtn = await driver!.findComponent(ON.text('取消'));
      await cancelBtn!.click();
      await driver!.delayMs(1500);
      await driver!.assertComponentExist(ON.text('智慧记账'));
    });
  });
}
