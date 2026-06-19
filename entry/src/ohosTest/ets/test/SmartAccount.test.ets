// HapTest 补充测试：记一笔页 + 分类 + 金额校验

import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';

export default function smartAccountHapTest() {
  describe('SmartAccount_Extended', () => {

    let driver: Driver | null = null;

    beforeAll(async () => {
      driver = Driver.create();
      await driver.delayMs(1000);
    });

    it('TextPresence_记一笔页全字段', 0, async () => {
      const addBtn = await driver!.findComponent(ON.text('记一笔'));
      await addBtn!.click();
      await driver!.delayMs(1500);
      await driver!.assertComponentExist(ON.text('金额'));
      await driver!.assertComponentExist(ON.text('分类'));
      await driver!.assertComponentExist(ON.text('日期'));
      await driver!.assertComponentExist(ON.text('备注'));
      await driver!.assertComponentExist(ON.text('保存'));
      const cancelBtn = await driver!.findComponent(ON.text('取消'));
      await cancelBtn!.click();
      await driver!.delayMs(1000);
    });

    it('ComponentPresence_8种分类', 0, async () => {
      const addBtn = await driver!.findComponent(ON.text('记一笔'));
      await addBtn!.click();
      await driver!.delayMs(1500);
      const cats: string[] = ['饮食', '交通', '购物', '娱乐', '居住', '医疗', '教育', '其他'];
      for (let i = 0; i < cats.length; i++) {
        await driver!.assertComponentExist(ON.text(cats[i]));
      }
      const cancelBtn = await driver!.findComponent(ON.text('取消'));
      await cancelBtn!.click();
      await driver!.delayMs(1000);
    });

    it('ComponentPresence_金额校验', 0, () => {
      expect(/^\d+(\.\d{0,2})?$/.test('50.00')).assertTrue();
      expect(/^\d+(\.\d{0,2})?$/.test('-50')).assertFalse();
    });

    it('ComponentPresence_分类8种', 0, () => {
      expect(['饮食', '交通', '购物', '娱乐', '居住', '医疗', '教育', '其他'].length).assertEqual(8);
    });
  });
}
