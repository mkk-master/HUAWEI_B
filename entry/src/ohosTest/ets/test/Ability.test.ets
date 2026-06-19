// 设备 UI 自动化测试 — @ohos.UiTest (HapTest 兼容)
// 应用由 OpenHarmonyTestRunner 启动后执行
// 测试策略 1: TextPresence — 关键文字存在
// 测试策略 2: ComponentPresence — 组件可交互

import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';

export default function abilityTest() {
  describe('SmartAccount_UiTest', () => {

    let driver: Driver | null = null;

    beforeAll(async () => {
      driver = Driver.create();
      // 等待应用 UI 完全渲染
      await driver.delayMs(4000);
    });

    // ==============================
    // 策略 1: TextPresence
    // ==============================

    it('TextPresence_首页智慧记账', 0, async () => {
      await driver!.assertComponentExist(ON.text('智慧记账'));
    });

    it('TextPresence_月份按钮', 0, async () => {
      await driver!.assertComponentExist(ON.text('上月'));
      await driver!.assertComponentExist(ON.text('本月'));
    });

    // ==============================
    // 策略 2: ComponentPresence
    // ==============================

    it('ComponentPresence_Button存在', 0, async () => {
      const btns = await driver!.findComponents(ON.type('Button'));
      expect(btns !== null && btns.length > 0).assertTrue();
    });

    it('ComponentPresence_记一笔跳转添加页', 0, async () => {
      const addBtn = await driver!.findComponent(ON.text('记一笔'));
      expect(addBtn !== null).assertTrue();
      await addBtn!.click();
      await driver!.delayMs(1500);
      await driver!.assertComponentExist(ON.text('保存'));
      await driver!.assertComponentExist(ON.text('取消'));
      const cancelBtn = await driver!.findComponent(ON.text('取消'));
      await cancelBtn!.click();
      await driver!.delayMs(1500);
    });
  });
}
