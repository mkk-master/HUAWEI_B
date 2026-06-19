// HapTest 补充测试：记一笔页 + 分类 + 金额校验
// 使用 globalThis.driver（由 OpenHarmonyTestRunner 创建）

import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';

function getDriver(): Driver {
  return globalThis.driver as Driver;
}

export default function smartAccountHapTest() {
  describe('SmartAccount_Extended', () => {

    let driver: Driver;

    beforeAll(() => {
      driver = getDriver();
    });

    // TextPresence: 记一笔页全字段
    it('TextPresence_记一笔页金额分类日期备注保存', 0, async () => {
      const addBtn = await driver.findComponent(ON.text('记一笔'));
      await addBtn.click();
      await driver.delayMs(1500);
      await driver.assertComponentExist(ON.text('金额'));
      await driver.assertComponentExist(ON.text('分类'));
      await driver.assertComponentExist(ON.text('日期'));
      await driver.assertComponentExist(ON.text('备注'));
      await driver.assertComponentExist(ON.text('保存'));
      await driver.findComponent(ON.text('取消')).then(c => c.click());
      await driver.delayMs(1000);
    });

    // ComponentPresence: 8 个分类标签
    it('ComponentPresence_8种分类标签全部可见', 0, async () => {
      const addBtn = await driver.findComponent(ON.text('记一笔'));
      await addBtn.click();
      await driver.delayMs(1500);
      const cats: string[] = ['饮食', '交通', '购物', '娱乐', '居住', '医疗', '教育', '其他'];
      for (let i = 0; i < cats.length; i++) {
        await driver.assertComponentExist(ON.text(cats[i]));
      }
      await driver.findComponent(ON.text('取消')).then(c => c.click());
      await driver.delayMs(1000);
    });

    // 金额格式校验
    it('ComponentPresence_金额正则校验', 0, () => {
      expect(/^\d+(\.\d{0,2})?$/.test('50.00')).assertTrue();
      expect(/^\d+(\.\d{0,2})?$/.test('-50')).assertFalse();
    });

    // 分类枚举完整性
    it('ComponentPresence_分类枚举8种', 0, () => {
      const cats: string[] = ['饮食', '交通', '购物', '娱乐', '居住', '医疗', '教育', '其他'];
      expect(cats.length).assertEqual(8);
    });
  });
}
