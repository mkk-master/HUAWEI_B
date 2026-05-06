// 使用云端大模型做账单分类（与端侧 LocalModelClassifier 提示词保持一致）

import { CategoryType } from '../model/BillModel';
import { dashScopeChatCompletion } from './DashScopeOpenAiClient';

function parseCategoryLabel(output: string): CategoryType {
  if (output.indexOf('饮食') !== -1) {
    return CategoryType.FOOD;
  }
  if (output.indexOf('交通') !== -1) {
    return CategoryType.TRANSPORT;
  }
  if (output.indexOf('购物') !== -1) {
    return CategoryType.SHOPPING;
  }
  if (output.indexOf('娱乐') !== -1) {
    return CategoryType.ENTERTAINMENT;
  }
  if (output.indexOf('居住') !== -1) {
    return CategoryType.HOUSING;
  }
  if (output.indexOf('医疗') !== -1) {
    return CategoryType.MEDICAL;
  }
  if (output.indexOf('教育') !== -1) {
    return CategoryType.EDUCATION;
  }
  return CategoryType.OTHER;
}

/**
 * 云端预测分类；失败时返回 null，由调用方回退端侧或其它逻辑。
 */
export async function predictBillCategoryCloud(apiKey: string, amountCent: number,
  remark: string): Promise<CategoryType | null> {
  const key = apiKey.trim();
  if (key.length === 0) {
    return null;
  }

  const question =
    `金额：${(amountCent / 100).toFixed(2)}元，备注：${remark || '无'}。请判断这笔消费的分类，可选答案：饮食、交通、购物、娱乐、居住、医疗、教育、其他。只输出分类名称。`;

  try {
    const text = await dashScopeChatCompletion(key, question);
    return parseCategoryLabel(text);
  } catch (e) {
    console.error('云端分类失败', e);
    return null;
  }
}
