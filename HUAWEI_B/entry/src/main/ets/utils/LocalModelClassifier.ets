// entry/src/main/ets/utils/LocalModelClassifier.ets

import { localChatModel } from '@kit.DataAugmentationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { CategoryType } from '../model/BillModel';


export class LocalModelClassifier {
  private static instance: LocalModelClassifier;
  private isModelReady: boolean = false;
  private nextQuestionId: number = 1;


  static getInstance(): LocalModelClassifier {
    if (!LocalModelClassifier.instance) {
      LocalModelClassifier.instance = new LocalModelClassifier();
    }
    return LocalModelClassifier.instance;
  }

  /**
   * 初始化端侧模型（不需要参数）
   */
  async initModel(): Promise<boolean> {
    try {
      await localChatModel.init();
      this.isModelReady = true;
      console.info('端侧模型初始化成功');
      return true;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`模型初始化失败: ${error.code}, ${error.message}`);
      return false;
    }
  }

  /**
   * 智能预测账单分类
   * @param amount 金额（分）
   * @param remark 备注文本
   * @returns 预测的分类
   */
  async predictCategory(amount: number, remark: string): Promise<CategoryType> {
    if (!this.isModelReady) {
      const ready = await this.initModel();
      if (!ready) {
        return CategoryType.OTHER;
      }
    }

    return new Promise((resolve) => {
      const questionId = this.nextQuestionId++;
      const question = `金额：${(amount / 100).toFixed(2)}元，备注：${remark || '无'}。请判断这笔消费的分类，可选答案：饮食、交通、购物、娱乐、居住、医疗、教育、其他。只输出分类名称。`;

      const questionInfo: localChatModel.QuestionInfo = {
        questionId: questionId,
        content: question
      };

      const config: localChatModel.Config = {
        isStream: false  // 非流式输出，直接获取完整结果
      };

      try {
        localChatModel.chat(questionInfo, config,
          (err: BusinessError | null, ans: localChatModel.Answer) => {
            if (err) {
              console.error(`问答失败: ${err.code}, ${err.message}`);
              resolve(CategoryType.OTHER);
              return;
            }
            console.info(`========== 模型返回原始内容 ==========`);
            console.info(`content: "${ans.content}"`);
            console.info(`content length: ${ans.content.length}`);
            console.info(`isFinished: ${ans.isFinished}`);
            console.info(`=====================================`);
            console.info(`模型回答: ${ans.content}`);
            const category = this.parseCategory(ans.content);
            resolve(category);
          }
        );
      } catch (err) {
        const error = err as BusinessError;
        console.error(`chat调用失败: ${error.code}, ${error.message}`);
        resolve(CategoryType.OTHER);
      }
    });
  }

  /**
   * 解析模型输出为 CategoryType
   */
  private parseCategory(output: string): CategoryType {
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
   * 释放模型资源
   */
  async releaseModel(): Promise<void> {
    if (this.isModelReady) {

      this.isModelReady = false;
      console.info('模型资源已释放');
    }
  }
}