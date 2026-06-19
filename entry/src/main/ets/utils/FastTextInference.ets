// entry/src/main/ets/utils/FastTextInference.ets

import { mindSporeLite } from '@kit.MindSporeLiteKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { fileIo } from '@kit.CoreFileKit';

const MODEL_FILE_NAME: string = 'bill_final.ms';
const VOCAB_FILE_NAME: string = 'bill_vocab.json';
const LABEL_FILE_NAME: string = 'bill_labels.json';

const MAX_LEN: number = 32;
const PAD_TOKEN: string = '<PAD>';
const UNK_TOKEN: string = '<UNK>';

interface MindSporeModelConfig {
  target: string[];
}

class EncodedInput {
  inputIds: Int32Array;
  mask: Float32Array;

  constructor(inputIds: Int32Array, mask: Float32Array) {
    this.inputIds = inputIds;
    this.mask = mask;
  }
}

export class FastTextInference {
  private vocab: Record<string, number> | null = null;
  private labels: string[] = [];
  private isLoaded: boolean = false;
  private cachedModelPath: string = '';

  /**
   * 兼容旧代码：
   * 你 AddBillPage.ets 里如果还调用 loadWordVectors()，
   * 这里会转到新的 loadConfig()。
   */
  async loadWordVectors(context: Context): Promise<void> {
    await this.loadConfig(context);
  }

  /**
   * 读取 rawfile/bill_vocab.json 和 rawfile/bill_labels.json
   */
  async loadConfig(context: Context): Promise<void> {
    if (this.isLoaded && this.vocab !== null && this.labels.length > 0) {
      return;
    }

    try {
      const decoder = util.TextDecoder.create('utf-8');

      const vocabRaw = await context.resourceManager.getRawFileContent(VOCAB_FILE_NAME);
      const vocabStr = decoder.decodeToString(new Uint8Array(vocabRaw));
      this.vocab = JSON.parse(vocabStr) as Record<string, number>;

      const labelRaw = await context.resourceManager.getRawFileContent(LABEL_FILE_NAME);
      const labelStr = decoder.decodeToString(new Uint8Array(labelRaw));
      this.labels = JSON.parse(labelStr) as string[];

      this.isLoaded = true;

      console.info(`FastText 词表加载成功，词数: ${Object.keys(this.vocab).length}`);
      console.info(`FastText 标签顺序: ${JSON.stringify(this.labels)}`);
    } catch (err) {
      this.vocab = null;
      this.labels = [];
      this.isLoaded = false;
      console.error('加载 bill_vocab.json / bill_labels.json 失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 中文按字切分，英文和数字连续保留。
   * 必须和 Python 训练/转换脚本里的 char_tokenize 保持一致。
   */
  private charTokenize(text: string): string[] {
    const tokens: string[] = [];
    let buff: string = '';

    for (let i = 0; i < text.length; i++) {
      const ch: string = text.charAt(i);

      if (ch === ' ' || ch === '\n' || ch === '\t' || ch === '\r') {
        if (buff.length > 0) {
          tokens.push(buff);
          buff = '';
        }
        continue;
      }

      if (/[A-Za-z0-9.]/.test(ch)) {
        buff += ch;
      } else {
        if (buff.length > 0) {
          tokens.push(buff);
          buff = '';
        }
        tokens.push(ch);
      }
    }

    if (buff.length > 0) {
      tokens.push(buff);
    }

    return tokens;
  }

  /**
   * 文本转 input_ids 和 mask。
   *
   * 新模型输入：
   * input_ids: [1, 32]
   * mask: [1, 32]
   */
  private encodeText(text: string): EncodedInput {
    if (this.vocab === null) {
      const emptyIds: Int32Array = new Int32Array(MAX_LEN);
      const emptyMask: Float32Array = new Float32Array(MAX_LEN);
      return new EncodedInput(emptyIds, emptyMask);
    }

    const tokens: string[] = this.charTokenize(text);
    console.info(`端侧分词结果: ${JSON.stringify(tokens)}`);

    const padId: number = this.vocab[PAD_TOKEN] ?? 0;
    const unkId: number = this.vocab[UNK_TOKEN] ?? 1;

    const idsArray: number[] = [];
    const maskArray: number[] = [];

    for (let i = 0; i < tokens.length && idsArray.length < MAX_LEN; i++) {
      const token: string = tokens[i];
      const id: number = this.vocab[token] ?? unkId;

      idsArray.push(id);
      maskArray.push(1.0);
    }

    while (idsArray.length < MAX_LEN) {
      idsArray.push(padId);
      maskArray.push(0.0);
    }

    console.info(`input_ids前16个: ${JSON.stringify(idsArray.slice(0, 16))}`);
    console.info(`mask前16个: ${JSON.stringify(maskArray.slice(0, 16))}`);

    const inputIds: Int32Array = new Int32Array(idsArray);
    const mask: Float32Array = new Float32Array(maskArray);

    return new EncodedInput(inputIds, mask);
  }

  /**
   * 把 rawfile 里的 .ms 模型复制到应用沙箱。
   * 这里每次第一次调用都覆盖复制，避免继续使用旧模型。
   */
  private async copyModelToSandbox(context: Context): Promise<string> {
    if (this.cachedModelPath.length > 0) {
      return this.cachedModelPath;
    }

    const modelPath: string = `${context.filesDir}/${MODEL_FILE_NAME}`;

    console.info('准备从 rawfile 复制最新 bill_final.ms');

    const rawData = await context.resourceManager.getRawFileContent(MODEL_FILE_NAME);

    let file: fileIo.File | null = null;

    try {
      file = fileIo.openSync(
        modelPath,
        fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC
      );

      const uint8Data: Uint8Array = new Uint8Array(rawData);
      fileIo.writeSync(file.fd, uint8Data.buffer);

      console.info(`模型文件复制完成: ${modelPath}, size=${rawData.byteLength}`);
    } catch (err) {
      console.error('复制模型文件失败: ' + JSON.stringify(err));
      throw new Error('复制模型文件失败');
    } finally {
      if (file !== null) {
        fileIo.closeSync(file);
      }
    }

    this.cachedModelPath = modelPath;
    return modelPath;
  }

  /**
   * 端侧推理入口
   *
   * text 示例：
   * 奶茶 4元
   * 坐地铁上班 5元
   * 淘宝买卫衣 150元
   */
  async predict(context: Context, text: string): Promise<string> {
    if (!this.isLoaded) {
      await this.loadConfig(context);
    }

    if (this.vocab === null || this.labels.length === 0) {
      console.error('vocab 或 labels 未加载，无法推理');
      return '其他';
    }

    try {
      const modelConfig: MindSporeModelConfig = {
        target: ['cpu']
      };

      const modelPath: string = await this.copyModelToSandbox(context);
      console.info(`准备加载端侧模型: ${modelPath}`);

      const model = await mindSporeLite.loadModelFromFile(modelPath, modelConfig);
      const inputs = model.getInputs();

      if (!inputs || inputs.length < 2) {
        const inputCount: number = inputs ? inputs.length : 0;
        console.error(`模型输入数量异常，当前输入数量: ${inputCount}`);
        return '其他';
      }

      const encoded: EncodedInput = this.encodeText(text);

      /**
       * 新模型有两个输入：
       * inputs[0] = input_ids
       * inputs[1] = mask
       */
      inputs[0].setData(encoded.inputIds.buffer);
      inputs[1].setData(encoded.mask.buffer);

      const outputs = await model.predict(inputs);

      if (!outputs || outputs.length === 0) {
        console.error('模型没有输出');
        return '其他';
      }

      const outputBuffer = outputs[0].getData() as ArrayBuffer;
      const float32Output: Float32Array = new Float32Array(outputBuffer);
      const scores: number[] = Array.from(float32Output);

      console.info(`端侧模型原始输出: ${JSON.stringify(scores)}`);

      if (scores.length === 0) {
        console.error('模型输出为空');
        return '其他';
      }

      let maxIdx: number = 0;
      let maxScore: number = scores[0];

      for (let i = 1; i < scores.length; i++) {
        if (scores[i] > maxScore) {
          maxScore = scores[i];
          maxIdx = i;
        }
      }

      const result: string = this.labels[maxIdx] || '其他';

      console.info(`端侧推理结果: ${text} → ${result}, index=${maxIdx}, score=${maxScore}`);

      return result;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`推理失败: ${error.code}, ${error.message}`);
      console.error('推理失败详情: ' + JSON.stringify(err));
      return '其他';
    }
  }
}