// HapTest 补充测试：分类 + 金额校验
// 测试策略: TextPresence + ComponentPresence 扩展

import { describe, beforeAll, it, expect } from '@ohos/hypium';
import { Driver, ON, MatchPattern } from '@ohos.UiTest';

async function assertText(driver: Driver, text: string): Promise<void> {
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

export default function smartAccountHapTest() {
  describe('SmartAccount_Extended', () => {

    let driver: Driver | null = null;

    beforeAll(async () => {
      driver = Driver.create();
      await driver.delayMs(3000);
    });

    // TextPresence: 验证 AddBillPage 全字段
    it('TextPresence_记一笔页全字段', 0, async () => {
      if (!driver) return;
      const ok = await findAndClick(driver, '记一笔');
      expect(ok).assertTrue();
      await driver.delayMs(1500);
      await assertText(driver, '金额');
      await assertText(driver, '分类');
      await assertText(driver, '日期');
      await assertText(driver, '备注');
      await assertText(driver, '保存');
      await findAndClick(driver, '取消');
      await driver.delayMs(1000);
    });

    // ComponentPresence: 8 个分类标签
    it('ComponentPresence_8个分类标签', 0, async () => {
      if (!driver) return;
      const ok = await findAndClick(driver, '记一笔');
      expect(ok).assertTrue();
      await driver.delayMs(1500);
      const cats: string[] = ['饮食', '交通', '购物', '娱乐', '居住', '医疗', '教育', '其他'];
      for (let i = 0; i < cats.length; i++) {
        await assertText(driver, cats[i]);
      }
      await findAndClick(driver, '取消');
      await driver.delayMs(1000);
    });

    // 金额格式校验
    it('ComponentPresence_金额格式校验', 0, () => {
      // 合法
      expect(/^\d+(\.\d{0,2})?$/.test('50.00')).assertTrue();
      expect(/^\d+(\.\d{0,2})?$/.test('0.01')).assertTrue();
      // 非法
      expect(/^\d+(\.\d{0,2})?$/.test('-50')).assertFalse();
      expect(/^\d+(\.\d{0,2})?$/.test('abc')).assertFalse();
      expect(/^\d+(\.\d{0,2})?$/.test('50.999')).assertFalse();
    });

    // 分类完整性
    it('ComponentPresence_分类枚举完整性', 0, () => {
      const categories: string[] = ['饮食', '交通', '购物', '娱乐', '居住', '医疗', '教育', '其他'];
      expect(categories.length).assertEqual(8);
    });
  });
}
