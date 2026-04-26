// 文件路径: entry/src/main/ets/components/PieChart.ets
import { drawing } from '@kit.ArkGraphics2D';
import { CategoryColors } from '../model/BillModel';
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
  @Prop data: Array<PieDataItem>;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  @State canvasWidth: number = 300;
  @State canvasHeight: number = 300;

  build() {
    Canvas(this.context)
      .width(this.canvasWidth)
      .height(this.canvasHeight)
      .onReady(() => {
        this.drawPieChart();
      })
  }

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

    const total = this.data.reduce((sum, item) => sum + item.amount, 0);
    if (total === 0 || this.data.length === 0) {
      // 无数据提示
      ctx.font = '16px sans-serif';
      ctx.fillStyle = '#999';
      ctx.textAlign = 'center';
      ctx.fillText('暂无消费数据', centerX, centerY);
      return;
    }

    let startAngle = -Math.PI / 2; // 从正上方开始
    const sortedData = [...this.data].sort((a, b) => b.amount - a.amount);

    sortedData.forEach(item => {
      const sliceAngle = (item.amount / total) * 2 * Math.PI;

      // 绘制扇形
      ctx.beginPath();
      ctx.moveTo(centerX, centerY);
      ctx.arc(centerX, centerY, radius, startAngle, startAngle + sliceAngle);
      ctx.closePath();
      ctx.fillStyle = CategoryColors[item.category] || '#CCCCCC';
      ctx.fill();
      ctx.strokeStyle = '#FFFFFF';
      ctx.lineWidth = 2;
      ctx.stroke();

      // 绘制百分比标签
      if (sliceAngle > 0.2) { // 角度过小不显示标签
        const labelAngle = startAngle + sliceAngle / 2;
        const labelX = centerX + Math.cos(labelAngle) * radius * 0.7;
        const labelY = centerY + Math.sin(labelAngle) * radius * 0.7;

        ctx.font = '12px sans-serif';
        ctx.fillStyle = '#FFFFFF';
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        const percent = ((item.amount / total) * 100).toFixed(1) + '%';
        ctx.fillText(percent, labelX, labelY);
      }

      startAngle += sliceAngle;
    });

    // 绘制中心白色圆（甜甜圈效果）
    ctx.beginPath();
    ctx.arc(centerX, centerY, radius * 0.55, 0, 2 * Math.PI);
    ctx.fillStyle = '#FFFFFF';
    ctx.fill();
  }
}