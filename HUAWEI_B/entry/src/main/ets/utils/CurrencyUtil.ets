// 文件路径: entry/src/main/ets/utils/CurrencyUtil.ets
/**
 * 金额处理工具类
 * 内部统一使用“分”存储，展示时转为“元”
 */
export class CurrencyUtil {
  /**
   * 分转元（带格式）
   */
  static fenToYuan(fen: number): string {
    const yuan = fen / 100;
    // 处理超大金额显示
    if (yuan >= 1e8) {
      return `${(yuan / 1e8).toFixed(2)}亿`;
    } else if (yuan >= 1e4) {
      return `${(yuan / 1e4).toFixed(2)}万`;
    }
    return yuan.toFixed(2);
  }

  /**
   * 元转分（带校验）
   */
  static yuanToFen(yuanStr: string): number {
    // 容错处理：移除非数字字符（保留小数点）
    const sanitized = yuanStr.replace(/[^\d.]/g, '');
    const num = parseFloat(sanitized);
    if (isNaN(num) || num < 0) {
      return NaN;
    }
    return Math.round(num * 100);
  }

  /**
   * 验证金额输入合法性
   */
  static isValidAmount(input: string): boolean {
    if (input.trim().length === 0) return false;
    // 正则：最多两位小数，支持整数
    const pattern = /^\d+(\.\d{0,2})?$/;
    if (!pattern.test(input)) return false;
    const num = parseFloat(input);
    return !isNaN(num) && num >= 0 && num <= 99999999.99; // 最大9999.99万
  }
}

