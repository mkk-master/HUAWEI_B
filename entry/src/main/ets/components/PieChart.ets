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
  // 外部传入的饼图数据（变化时需重绘 Canvas；onReady 仅首次触发）
  @Prop @Watch('onDataChange') data: Array<PieDataItem> = [];
  @Prop labelColor: string = '#888888';
  private canvasReady: boolean = false;

  private onDataChange(): void {
    if (this.canvasReady) {
      this.drawPieChart();
    }
  }
  // Canvas 绘图上下文配置
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  // Canvas 宽高
  @State canvasWidth: number = 380;
  @State canvasHeight: number = 380;

  build() {
    // 外层Column包裹饼图和下方的详情列表，统一设置样式
    Column() {
      // 饼图Canvas

      Canvas(this.context)
        .width(this.canvasWidth)
        .height(this.canvasHeight)
        .onReady(() => {
          this.canvasReady = true;
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

  // 饼图绘制核心方法
  private drawPieChart(): void {
    if(!this.data || this.data.length === 0) {
      return;
    }
    const ctx = this.context;
    const centerX = this.canvasWidth / 2;
    const centerY = this.canvasHeight / 2;
    const radius = Math.min(centerX, centerY) - 55;

    ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

    const adjustedData = this.data.map(item => {
      return { category: item.category, amount: item.amount / 100 } as PieDataItem;
    });

    const total = adjustedData.reduce((sum, item) => sum + item.amount, 0);
    if (total === 0) {
      ctx.font = '26px sans-serif';
      ctx.fillStyle = '#999';
      ctx.textAlign = 'center';
      ctx.fillText('暂无消费数据', centerX, centerY);
      return;
    }

    let startAngle = -Math.PI / 2;
    const sortedData = [...adjustedData].sort((a, b) => b.amount - a.amount);

    // 先收集所有标签信息，用于碰撞检测
    interface LabelInfo {
      midAngle: number;
      percent: string;
      explode: number;
      offX: number;
      offY: number;
      sliceAngle: number;
    }
    const labels: LabelInfo[] = [];
    let curAngle = startAngle;

    sortedData.forEach(item => {
      const sliceAngle = (item.amount / total) * 2 * Math.PI;
      const isTiny = sliceAngle < 0.12;
      const explode = isTiny ? 5 : 0;
      const midAngle = curAngle + sliceAngle / 2;
      if (sliceAngle > 0.03) {
        labels.push({
          midAngle: midAngle,
          percent: ((item.amount / total) * 100).toFixed(1) + '%',
          explode: explode,
          offX: Math.cos(midAngle) * explode,
          offY: Math.sin(midAngle) * explode,
          sliceAngle: sliceAngle
        });
      }
      curAngle += sliceAngle;
    });

    // 按侧分组，每侧按 Y 排序做碰撞避让
    const leftLabels = labels.filter(l => Math.cos(l.midAngle) < 0)
      .sort((a, b) => Math.sin(a.midAngle) - Math.sin(b.midAngle));
    const rightLabels = labels.filter(l => Math.cos(l.midAngle) >= 0)
      .sort((a, b) => Math.sin(a.midAngle) - Math.sin(b.midAngle));

    const MIN_GAP = 28; // 标签最小垂直间距
    // 为每侧计算水平偏移层级（重叠时逐级外推）
    const calcLevels = (sideLabels: LabelInfo[]): Map<LabelInfo, number> => {
      const map = new Map<LabelInfo, number>();
      if (sideLabels.length <= 1) {
        sideLabels.forEach(l => map.set(l, 0));
        return map;
      }
      sideLabels.forEach((l, i) => {
        let level = 0;
        let placed = false;
        while (!placed && level < 10) {
          placed = true;
          for (let j = 0; j < i; j++) {
            const prev = sideLabels[j];
            const prevLevel = map.get(prev) ?? 0;
            if (prevLevel === level) {
              const prevY = centerY + prev.offY + Math.sin(prev.midAngle) * (radius + 12);
              const curY = centerY + l.offY + Math.sin(l.midAngle) * (radius + 12);
              if (Math.abs(curY - prevY) < MIN_GAP) {
                placed = false;
                level++;
                break;
              }
            }
          }
        }
        map.set(l, level);
      });
      return map;
    };

    const leftLevels = calcLevels(leftLabels);
    const rightLevels = calcLevels(rightLabels);
    const allLevels = new Map<LabelInfo, number>();
    leftLevels.forEach((v: number, k: LabelInfo) => { allLevels.set(k, v); });
    rightLevels.forEach((v: number, k: LabelInfo) => { allLevels.set(k, v); });

    // 绘制
    curAngle = startAngle;
    let labelIdx = 0;
    sortedData.forEach(item => {
      const sliceAngle = (item.amount / total) * 2 * Math.PI;
      const isTiny = sliceAngle < 0.12;
      const explode = isTiny ? 5 : 0;
      const midAngle = curAngle + sliceAngle / 2;
      const offX = Math.cos(midAngle) * explode;
      const offY = Math.sin(midAngle) * explode;

      // 扇形
      ctx.beginPath();
      ctx.moveTo(centerX + offX, centerY + offY);
      ctx.arc(centerX + offX, centerY + offY, radius, curAngle, curAngle + sliceAngle);
      ctx.closePath();
      ctx.fillStyle = CategoryColors[item.category] || '#CCCCCC';
      ctx.fill();
      ctx.strokeStyle = '#FFFFFF';
      ctx.lineWidth = 1.8;
      ctx.stroke();

      // 标签 + 引线
      if (sliceAngle > 0.03) {
        const info = labels[labelIdx];
        const level = allLevels.get(info) ?? 0;
        const textSide: number = Math.cos(midAngle) >= 0 ? 1 : -1;

        const edgeX = centerX + offX + Math.cos(midAngle) * radius;
        const edgeY = centerY + offY + Math.sin(midAngle) * radius;
        const baseDist = radius + 12;
        const bendDist = baseDist + level * 18;
        const bendX = centerX + offX + Math.cos(midAngle) * bendDist;
        const bendY = centerY + offY + Math.sin(midAngle) * bendDist;
        const textX = bendX + textSide * (26 + level * 10);
        const textY = bendY;

        ctx.beginPath();
        ctx.moveTo(edgeX, edgeY);
        ctx.lineTo(bendX, bendY);
        ctx.lineTo(textX, textY);
        ctx.strokeStyle = '#C0C0C0';
        ctx.lineWidth = 0.8;
        ctx.stroke();

        ctx.font = '22px sans-serif';
        ctx.fillStyle = this.labelColor;
        ctx.textBaseline = 'middle';
        ctx.textAlign = textSide >= 0 ? 'left' : 'right';
        ctx.fillText(info.percent, textX + textSide * 5, textY);

        labelIdx++;
      }

      curAngle += sliceAngle;
    });

    // 中心白色圆（甜甜圈效果）
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius * 0.55, 0, 2 * Math.PI);
    ctx.fillStyle = '#FFFFFF';
    ctx.fill();
  }
}

