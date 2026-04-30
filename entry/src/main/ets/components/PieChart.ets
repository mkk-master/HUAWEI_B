// 文件路径: entry/src/main/ets/components/PieChart.ets
import { drawing } from '@kit.ArkGraphics2D';
import { CategoryColors } from '../model/BillModel';

// 定义饼图数据项接口
interface PieDataItem {
  category: string;
  amount: number;
}

/**
 * Canvas 饼图组件
 * 使用 XComponent + Drawing API 实现
 */
@Component
export struct PieChart {
  // 外部传入的饼图数据
  @Prop data: Array<PieDataItem>;
  // Canvas 绘图上下文配置
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  // Canvas 宽高
  @State canvasWidth: number = 300;
  @State canvasHeight: number = 300;

  build() {
    // 外层Column包裹饼图和下方的详情列表，统一设置样式
    Column() {
      // 饼图Canvas

      Canvas(this.context)
        .width(this.canvasWidth)
        .height(this.canvasHeight)
        .onReady(() => {
          this.drawPieChart(); // Canvas就绪后绘制饼图
        })

      // 详情页面（标签）放在饼图下方
      if (this.data && this.data.length > 0) {
        Column() {
          ForEach(this.data, (item: PieDataItem) => {
            Row() {
              // 颜色方块
              Rect()
                .width(20)
                .height(20)
                .fill(CategoryColors[item.category] || '#CCCCCC')
                .margin({ right: 12 })
              // 分类名称
              Text(item.category)
                .fontSize(16)
                .fontColor('#333333')
                .layoutWeight(1)
              // 金额（保留两位小数）- 修正金额显示：除以10
              Text('¥' + (item.amount / 100).toFixed(2))
                .fontSize(16)
                .fontColor('#333333')
                .margin({ left: 12 })
            }
            .width('100%')
            .padding({ top: 8, bottom: 8, left: 16, right: 16 })
            .borderRadius(8)
            .backgroundColor('#F5F5F5')
            .margin({ bottom: 8 })
          })
        }
        .width('100%')
        .margin({ top: 24 })
        .padding({ left: 16, right: 16 })
      } else {
        // 无数据时显示提示
        Column() {
          Text('暂无消费数据')
            .fontSize(18)
            .fontColor('#999')
        }
        .width('100%')
        .margin({ top: 24 })
      }
    }
    // 外层Column的样式（原错误位置的样式移到这里）
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 16, bottom: 16 })
  }

  // 饼图绘制核心方法（整合并修正位置）
  private drawPieChart(): void {
    if(!this.data || this.data.length === 0) {
      return;
    }
    const ctx = this.context;
    const centerX = this.canvasWidth / 2;
    const centerY = this.canvasHeight / 2;
    const radius = Math.min(centerX, centerY) - 20;

    // 清空画布
    ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
    // 修正金额：如果数据源金额被放大了10倍，这里除以10恢复正确值
    const adjustedData = this.data.map(item => {
      return {
        category: item.category,
        amount: item.amount / 100
      } as PieDataItem;
    });

    // 计算总金额（使用修正后的金额）
    const total = adjustedData.reduce((sum, item) => sum + item.amount, 0);
    if (total === 0) {
      // 无有效数据时绘制提示文字
      ctx.font = '26px sans-serif';
      ctx.fillStyle = '#999';
      ctx.textAlign = 'center';
      ctx.fillText('暂无消费数据', centerX, centerY);
      return;
    }

    let startAngle = -Math.PI / 2; // 从正上方开始绘制
    const sortedData = [...adjustedData].sort((a, b) => b.amount - a.amount); // 按金额降序排列

    // 遍历绘制每个扇形
    sortedData.forEach(item => {
      const sliceAngle = (item.amount / total) * 2 * Math.PI; // 计算当前扇形的角度

      // 绘制扇形区域
      ctx.beginPath();
      ctx.moveTo(centerX, centerY);
      ctx.arc(centerX, centerY, radius, startAngle, startAngle + sliceAngle);
      ctx.closePath();
      ctx.fillStyle = CategoryColors[item.category] || '#CCCCCC'; // 分类对应颜色
      ctx.fill();
      // 扇形描边（白色边框区分）
      ctx.strokeStyle = '#FFFFFF';
      ctx.lineWidth = 2;
      ctx.stroke();

      // 绘制百分比标签（角度过小不显示，避免重叠）
      if (sliceAngle > 0.15) {
        const labelAngle = startAngle + sliceAngle / 2;
        const labelX = centerX + Math.cos(labelAngle) * radius * 0.7;
        const labelY = centerY + Math.sin(labelAngle) * radius * 0.7;

        ctx.font = '56px sans-serif';
        ctx.fillStyle = '#FFFFFF';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        const percent = ((item.amount / total) * 100).toFixed(1) + '%';
        ctx.fillText(percent, labelX, labelY);
      }

      startAngle += sliceAngle; // 更新下一个扇形的起始角度
    });

    // 绘制中心白色圆，实现甜甜圈效果
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius * 0.55, 0, 2 * Math.PI);
    ctx.fillStyle = '#FFFFFF';
    ctx.fill();
  }
}