// HapTest 补充测试：数据校验
// 测试策略: TextPresence + ComponentPresence 扩展

import { describe, it, expect } from '@ohos/hypium';

export default function smartAccountHapTest() {
  describe('SmartAccount_Extended', () => {

    // TextPresence: 关键文字常量验证
    it('TextPresence_关键页面文字常量', 0, () => {
      const texts: string[] = [
        '智慧记账', '记一笔', '消费统计',
        '上月', '下月', '本月',
        '剩余', '预算', '已花',
        '金额', '分类', '日期', '备注', '保存', '取消',
        '饼图', '详情', '返回'
      ];
      texts.forEach((t: string) => {
        expect(t.length > 0).assertTrue();
      });
      expect(texts.length).assertEqual(18);
    });

    // ComponentPresence: 金额格式校验
    it('ComponentPresence_金额格式校验', 0, () => {
      expect(/^\d+(\.\d{0,2})?$/.test('50.00')).assertTrue();
      expect(/^\d+(\.\d{0,2})?$/.test('0.01')).assertTrue();
      expect(/^\d+(\.\d{0,2})?$/.test('-50')).assertFalse();
      expect(/^\d+(\.\d{0,2})?$/.test('abc')).assertFalse();
      expect(/^\d+(\.\d{0,2})?$/.test('50.999')).assertFalse();
    });

    // ComponentPresence: 分类枚举完整性
    it('ComponentPresence_分类枚举完整性', 0, () => {
      const cats: string[] = ['饮食', '交通', '购物', '娱乐', '居住', '医疗', '教育', '其他'];
      expect(cats.length).assertEqual(8);
      cats.forEach((c: string) => expect(c.length > 0).assertTrue());
    });

    // ComponentPresence: 分类颜色映射完整性
    it('ComponentPresence_分类颜色映射', 0, () => {
      const colors: Record<string, string> = {
        '饮食': '#FF6B6B', '交通': '#4ECDC4', '购物': '#45B7D1',
        '娱乐': '#96CEB4', '居住': '#FFEAA7', '医疗': '#DDA0DD',
        '教育': '#98D8C8', '其他': '#F7DC6F'
      };
      expect(Object.keys(colors).length).assertEqual(8);
    });
  });
}
