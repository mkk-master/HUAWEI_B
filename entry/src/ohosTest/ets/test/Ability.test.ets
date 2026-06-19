// 设备 UI 自动化测试 — @ohos.UiTest
// 策略 1: TextPresence — 文字存在
// 策略 2: ComponentPresence — 组件交互

import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';
import abilityDelegatorRegistry from '@ohos.application.abilityDelegatorRegistry';

function sleep(ms: number): Promise<void> {
  return new Promise<void>((resolve: Function) => {
    setTimeout(() => { resolve(); }, ms);
  });
}

export default function abilityTest() {
  describe('SmartAccount_UiTest', () => {

    let driver: Driver | null = null;

    beforeAll(async () => {
      const delegator = abilityDelegatorRegistry.getAbilityDelegator();
      await delegator.startAbility({
        bundleName: 'com.example.count1',
        abilityName: 'EntryAbility'
      });
      await sleep(5000);
      driver = Driver.create();
    });

    // ==============================
    // 策略 1: TextPresence
    // ==============================

    it('TextPresence_首页智慧记账', 0, async () => {
      await driver!.assertComponentExist(ON.text('智慧记账'));
    });

    it('TextPresence_本月按钮', 0, async () => {
      await driver!.assertComponentExist(ON.text('本月'));
    });

    // ==============================
    // 策略 2: ComponentPresence
    // ==============================

    it('ComponentPresence_Button存在', 0, async () => {
      const btns = await driver!.findComponents(ON.type('Button'));
      expect(btns !== null && btns.length > 0).assertTrue();
    });

    it('ComponentPresence_记一笔跳转并返回', 0, async () => {
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
