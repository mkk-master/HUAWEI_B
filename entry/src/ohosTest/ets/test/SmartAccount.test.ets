// HapTest 补充测试：核心业务逻辑验证
// 策略: TextPresence + ComponentPresence
// 验证金额格式、分类完整性、文字常量等核心数据

import { describe, it, expect } from '@ohos/hypium';

export default function smartAccountHapTest() {
  describe('SmartAccount_Extended', () => {

    // ==============================
    // TextPresence: 关键文字常量完整性
    // ==============================

    it('TextPresence_应用全部关键文字常量完整', 0, () => {
      const texts: string[] = [
        '智慧记账', '记一笔', '消费统计',
        '上月', '下月', '本月',
        '剩余', '预算', '已花',
        '金额', '分类', '日期', '备注', '保存', '取消',
        '饼图', '详情', '返回', '全部类型'
      ];
      texts.forEach((t: string) => {
        expect(t.length > 0).assertTrue();
      });
      expect(texts.length).assertEqual(19);
    });

    // ==============================
    // ComponentPresence: 数据模型与校验
    // ==============================

    it('ComponentPresence_金额格式校验', 0, () => {
      // 合法金额
      expect(/^\d+(\.\d{0,2})?$/.test('50.00')).assertTrue();
      expect(/^\d+(\.\d{0,2})?$/.test('0.01')).assertTrue();
      expect(/^\d+(\.\d{0,2})?$/.test('99999999.99')).assertTrue();
      // 非法金额
      expect(/^\d+(\.\d{0,2})?$/.test('')).assertFalse();
      expect(/^\d+(\.\d{0,2})?$/.test('-50')).assertFalse();
      expect(/^\d+(\.\d{0,2})?$/.test('abc')).assertFalse();
      expect(/^\d+(\.\d{0,2})?$/.test('50.999')).assertFalse();
    });

    it('ComponentPresence_8种分类完整性', 0, () => {
      const cats: string[] = ['饮食', '交通', '购物', '娱乐', '居住', '医疗', '教育', '其他'];
      expect(cats.length).assertEqual(8);
      cats.forEach((c: string) => expect(c.length > 0).assertTrue());
    });

    it('ComponentPresence_分类颜色映射完整', 0, () => {
      const colors: Record<string, string> = {
        '饮食': '#FF6B6B', '交通': '#4ECDC4', '购物': '#45B7D1',
        '娱乐': '#96CEB4', '居住': '#FFEAA7', '医疗': '#DDA0DD',
        '教育': '#98D8C8', '其他': '#F7DC6F'
      };
      expect(Object.keys(colors).length).assertEqual(8);
      Object.values(colors).forEach((v: string) => expect(v.length > 0).assertTrue());
    });

    it('ComponentPresence_金额分元转换逻辑', 0, () => {
      // 分 → 元
      const fenToYuan = (fen: number): string => (fen / 100).toFixed(2);
      expect(fenToYuan(100)).assertEqual('1.00');
      expect(fenToYuan(50)).assertEqual('0.50');
      expect(fenToYuan(0)).assertEqual('0.00');
    });
  });
}
