// entry/src/main/ets/utils/LocalModelClassifier.ets

import { CategoryType } from '../model/BillModel';
import { FastTextInference } from './FastTextInference';

export interface RemarkSuggestResult {
  suggestion: string;
  reason: string;
}

export class LocalModelClassifier {
  private static instance: LocalModelClassifier;
  private fastTextInference: FastTextInference = new FastTextInference();

  static getInstance(): LocalModelClassifier {
    if (!LocalModelClassifier.instance) {
      LocalModelClassifier.instance = new LocalModelClassifier();
    }
    return LocalModelClassifier.instance;
  }

  /**
   * 为了兼容你原来 AddBillPage.ets 里可能存在的 initModel() 调用。
   * 现在真正端侧模型在 FastTextInference 中加载，这里直接返回 true。
   */
  async initModel(): Promise<boolean> {
    return true;
  }

  /**
   * 端侧模型分类预测
   * amount 单位：分
   * remark：用户输入备注
   * context：页面上下文，用于读取 rawfile 中的 bill_final.ms 和 word_vectors.json
   */
  async predictCategory(amount: number, remark: string, context?: Context): Promise<CategoryType> {
    const amountYuan = amount / 100;
    const text = `${remark} ${amountYuan}元`;

    if (context) {
      try {
        const label: string = await this.fastTextInference.predict(context, text);
        const result: CategoryType = this.mapLabelToCategory(label);

        // 如果端侧模型返回了明确分类，就直接使用
        if (result !== CategoryType.OTHER || label === '其他') {
          return result;
        }
      } catch (err) {
        console.error('端侧模型预测失败，改用本地规则兜底: ' + JSON.stringify(err));
      }
    }

    // 端侧模型失败时，使用本地规则兜底
    return this.predictCategoryByLocalRule(amount, remark);
  }

  /**
   * 字符串标签转 CategoryType
   */
  private mapLabelToCategory(label: string): CategoryType {
    const text = label.trim();

    if (text === '饮食') {
      return CategoryType.FOOD;
    }

    if (text === '交通') {
      return CategoryType.TRANSPORT;
    }

    if (text === '购物') {
      return CategoryType.SHOPPING;
    }

    if (text === '娱乐') {
      return CategoryType.ENTERTAINMENT;
    }

    if (text === '居住') {
      return CategoryType.HOUSING;
    }

    if (text === '医疗') {
      return CategoryType.MEDICAL;
    }

    if (text === '教育') {
      return CategoryType.EDUCATION;
    }

    return CategoryType.OTHER;
  }

  /**
   * 本地规则兜底分类
   * amount 单位：分
   */
  predictCategoryByLocalRule(amount: number, remark: string): CategoryType {
    const text = remark.trim();

    if (this.containsAny(text, [
      '饭', '餐', '早餐', '午餐', '晚餐', '外卖', '奶茶', '咖啡',
      '水果', '食堂', '火锅', '烧烤', '黄焖鸡', '星巴克', '拿铁',
      '买菜', '超市买菜', '聚餐', '小吃', '饮料', '炸鸡', '汉堡'
    ])) {
      return CategoryType.FOOD;
    }

    if (this.containsAny(text, [
      '地铁', '公交', '打车', '滴滴', '高铁', '火车', '飞机',
      '加油', '停车', '共享单车', '出租车', '网约车', '通勤',
      '坐地铁', '停车费'
    ])) {
      return CategoryType.TRANSPORT;
    }

    if (this.containsAny(text, [
      '淘宝', '京东', '拼多多', '超市购物', '衣服', '卫衣', '鞋',
      '裤子', '化妆品', '手机壳', '电脑', '耳机', '快递',
      '生活用品', '日用品', '网购'
    ])) {
      return CategoryType.SHOPPING;
    }

    if (this.containsAny(text, [
      '电影', '哪吒', '游戏', 'KTV', '旅游', '景点', '门票',
      '演唱会', '会员', '音乐', '剧本杀', '桌游', '密室逃脱',
      '游乐园', '看展', '滑冰'
    ])) {
      return CategoryType.ENTERTAINMENT;
    }

    if (this.containsAny(text, [
      '房租', '交房租', '水费', '电费', '物业', '宽带',
      '燃气', '租房', '宿舍电费', '取暖费', '生活缴费'
    ])) {
      return CategoryType.HOUSING;
    }

    if (this.containsAny(text, [
      '医院', '药', '买药', '感冒药', '挂号', '体检',
      '牙科', '感冒', '诊所', '药店', '消炎药', '看病'
    ])) {
      return CategoryType.MEDICAL;
    }

    if (this.containsAny(text, [
      '书', '教材', '课程', '网课', '文具', '打印',
      '考试', '报名', '编程课', '培训班', '学费', '补习班',
      '资料费', '考证'
    ])) {
      return CategoryType.EDUCATION;
    }

    if (amount > 0 && amount <= 3000) {
      return CategoryType.FOOD;
    }

    return CategoryType.OTHER;
  }

  private containsAny(text: string, keywords: string[]): boolean {
    for (let i = 0; i < keywords.length; i++) {
      if (text.indexOf(keywords[i]) !== -1) {
        return true;
      }
    }
    return false;
  }

  /**
   * 备注补全推荐
   * amount 单位：分
   */
  suggestRemark(amount: number, category: CategoryType, currentRemark: string): RemarkSuggestResult {
    const input = currentRemark.trim();

    const foodRemarks: string[] = [
      '早餐', '午餐', '晚餐', '奶茶', '咖啡', '外卖', '食堂',
      '水果', '零食', '火锅', '烧烤', '黄焖鸡', '星巴克拿铁'
    ];

    const transportRemarks: string[] = [
      '地铁', '公交', '打车', '滴滴打车', '共享单车', '高铁票',
      '火车票', '停车费', '加油'
    ];

    const shoppingRemarks: string[] = [
      '淘宝购物', '京东购物', '拼多多', '超市购物', '买衣服',
      '买鞋', '生活用品', '快递', '买卫衣'
    ];

    const entertainmentRemarks: string[] = [
      '电影票', '游戏充值', 'KTV', '会员续费', '景点门票',
      '看电影', '剧本杀'
    ];

    const housingRemarks: string[] = [
      '房租', '水费', '电费', '物业费', '宽带费', '燃气费',
      '生活缴费'
    ];

    const medicalRemarks: string[] = [
      '买药', '感冒药', '挂号', '体检', '牙科', '诊所'
    ];

    const educationRemarks: string[] = [
      '教材', '文具', '打印', '课程报名', '考试报名', '网课',
      '编程课', '培训班'
    ];

    const otherRemarks: string[] = [
      '日常支出', '临时支出', '其他消费'
    ];

    let candidates: string[] = otherRemarks;

    if (category === CategoryType.FOOD) {
      candidates = foodRemarks;
    } else if (category === CategoryType.TRANSPORT) {
      candidates = transportRemarks;
    } else if (category === CategoryType.SHOPPING) {
      candidates = shoppingRemarks;
    } else if (category === CategoryType.ENTERTAINMENT) {
      candidates = entertainmentRemarks;
    } else if (category === CategoryType.HOUSING) {
      candidates = housingRemarks;
    } else if (category === CategoryType.MEDICAL) {
      candidates = medicalRemarks;
    } else if (category === CategoryType.EDUCATION) {
      candidates = educationRemarks;
    } else {
      candidates = otherRemarks;
    }

    // 用户输入了部分备注，例如“奶”，补全为“奶茶”
    if (input.length > 0) {
      for (let i = 0; i < candidates.length; i++) {
        const item = candidates[i];

        if (item.indexOf(input) === 0 || item.indexOf(input) !== -1) {
          return {
            suggestion: item,
            reason: `根据当前分类和输入内容，推荐补全为“${item}”`
          };
        }
      }

      return {
        suggestion: '',
        reason: ''
      };
    }

    // 用户没有输入备注时，根据分类和金额推荐
    if (category === CategoryType.FOOD) {
      if (amount > 0 && amount <= 1500) {
        return {
          suggestion: '早餐',
          reason: '小额饮食消费可能是早餐或小吃'
        };
      }

      if (amount > 1500 && amount <= 5000) {
        return {
          suggestion: '午餐',
          reason: '该金额较符合日常正餐消费'
        };
      }

      return {
        suggestion: '餐饮',
        reason: '根据当前分类推荐常用备注'
      };
    }

    if (category === CategoryType.TRANSPORT) {
      if (amount > 0 && amount <= 1000) {
        return {
          suggestion: '地铁',
          reason: '小额交通消费通常可能是地铁或公交'
        };
      }

      return {
        suggestion: '交通出行',
        reason: '根据当前分类推荐常用备注'
      };
    }

    if (category === CategoryType.HOUSING) {
      if (amount >= 50000) {
        return {
          suggestion: '房租',
          reason: '较大金额居住类支出可能是房租'
        };
      }

      return {
        suggestion: '生活缴费',
        reason: '根据当前分类推荐常用备注'
      };
    }

    if (category === CategoryType.SHOPPING) {
      if (amount >= 10000) {
        return {
          suggestion: '淘宝购物',
          reason: '较大金额购物类消费可能是网购或生活用品'
        };
      }

      return {
        suggestion: '超市购物',
        reason: '根据当前分类推荐常用备注'
      };
    }

    return {
      suggestion: candidates[0],
      reason: `根据当前分类推荐常用备注“${candidates[0]}”`
    };
  }

  async releaseModel(): Promise<void> {
    // 当前版本没有需要手动释放的资源，保留该方法用于兼容旧代码。
  }
}